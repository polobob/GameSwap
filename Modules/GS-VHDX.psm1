#Requires -Version 5.1
# Module GS-VHDX.psm1 - Montage et demontage des fichiers VHDX
# Toujours monte sur la lettre U:
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

$script:DriveLetter      = "U"
$script:MountedVhdxPath  = $null   # chemin du VHDX actuellement monte

# ---------------------------------------------------------------------------
# Helpers internes : ShellHWDetection (evite l'ouverture d'Explorer)
# ---------------------------------------------------------------------------
function Stop-AutoPlay {
    try {
        $svc = Get-Service -Name "ShellHWDetection" -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            Stop-Service -Name "ShellHWDetection" -Force -ErrorAction SilentlyContinue
            Write-GSLog "ShellHWDetection arrete (montage silencieux)" -Level "DEBUG"
            return $true
        }
    } catch { }
    return $false
}

function Start-AutoPlay {
    param([bool]$WasRunning)
    if ($WasRunning) {
        try {
            Start-Service -Name "ShellHWDetection" -ErrorAction SilentlyContinue
            Write-GSLog "ShellHWDetection redémarre" -Level "DEBUG"
        } catch { }
    }
}

# ---------------------------------------------------------------------------
function Mount-GSVhdx {
    param(
        [Parameter(Mandatory)]
        [string]$VhdxPath
    )

    if (-not (Test-Path $VhdxPath)) {
        throw "Fichier VHDX introuvable: $VhdxPath"
    }

    # Verifier si ce VHDX est deja monte
    $existingImg = Get-DiskImage -ImagePath $VhdxPath -ErrorAction SilentlyContinue
    if ($existingImg -and $existingImg.Attached) {
        Write-GSLog "VHDX deja monte: $VhdxPath" -Level "INFO"
        $script:MountedVhdxPath = $VhdxPath
        return "$($script:DriveLetter):"
    }

    # Demonter ce qui est eventuellement sur U:
    Dismount-GSVhdx

    Write-GSLog "Montage du VHDX: $VhdxPath" -Level "INFO"

    # Stopper l'AutoPlay pour eviter l'ouverture d'Explorer
    $autoPlayWasRunning = Stop-AutoPlay

    try {
        $diskImage = Mount-DiskImage -ImagePath $VhdxPath -PassThru -ErrorAction Stop
        Start-Sleep -Milliseconds 800

        $disk = $diskImage | Get-Disk -ErrorAction Stop

        # Trouver la partition principale (eviter Reserved/System/Recovery)
        $partition = Get-Partition -DiskNumber $disk.DiskNumber -ErrorAction Stop |
            Where-Object { $_.Size -gt 50MB -and $_.Type -notin @("Reserved","System","Recovery","Unknown") } |
            Sort-Object Size -Descending |
            Select-Object -First 1

        if (-not $partition) {
            $partition = Get-Partition -DiskNumber $disk.DiskNumber |
                Where-Object { $_.Size -gt 0 } |
                Sort-Object Size -Descending |
                Select-Object -First 1
        }

        if (-not $partition) {
            throw "Aucune partition accessible dans le VHDX"
        }

        # Supprimer la lettre existante si differente de U:
        if ($partition.DriveLetter -and ($partition.DriveLetter -ne $script:DriveLetter[0])) {
            Remove-PartitionAccessPath -DiskNumber $disk.DiskNumber `
                -PartitionNumber $partition.PartitionNumber `
                -AccessPath "$($partition.DriveLetter):" -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 300
        }

        # Assigner la lettre U:
        if ("$($partition.DriveLetter)" -ne $script:DriveLetter) {
            Set-Partition -DiskNumber $disk.DiskNumber `
                -PartitionNumber $partition.PartitionNumber `
                -NewDriveLetter $script:DriveLetter -ErrorAction Stop
            Start-Sleep -Milliseconds 500
        }

        $script:MountedVhdxPath = $VhdxPath
        Write-GSLog "VHDX monte sur $($script:DriveLetter): ($VhdxPath)" -Level "INFO"
        return "$($script:DriveLetter):"

    } catch {
        Write-GSLog "Erreur montage VHDX: $_" -Level "ERROR"
        try { Dismount-DiskImage -ImagePath $VhdxPath -ErrorAction SilentlyContinue } catch {}
        $script:MountedVhdxPath = $null
        throw
    } finally {
        # Toujours restaurer l'AutoPlay meme en cas d'erreur
        Start-AutoPlay -WasRunning $autoPlayWasRunning
    }
}

# ---------------------------------------------------------------------------
function Dismount-GSVhdx {
    if (-not $script:MountedVhdxPath) {
        # Fallback : verifier via la lettre de lecteur si la variable est vide
        $script:MountedVhdxPath = Get-MountedGSVhdxPathByDrive
        if (-not $script:MountedVhdxPath) { return }
    }

    try {
        Dismount-DiskImage -ImagePath $script:MountedVhdxPath -ErrorAction Stop
        Write-GSLog "VHDX demonte: $script:MountedVhdxPath" -Level "INFO"
        $script:MountedVhdxPath = $null
        Start-Sleep -Milliseconds 300
    } catch {
        Write-GSLog "Avertissement lors du demontage: $_" -Level "WARNING"
        $script:MountedVhdxPath = $null
    }
}

# ---------------------------------------------------------------------------
function Dismount-GSVhdxByPath {
    param(
        [Parameter(Mandatory)]
        [string]$VhdxPath
    )
    try {
        $img = Get-DiskImage -ImagePath $VhdxPath -ErrorAction SilentlyContinue
        if ($img -and $img.Attached) {
            Dismount-DiskImage -ImagePath $VhdxPath -ErrorAction Stop
            Write-GSLog "VHDX demonte: $VhdxPath" -Level "INFO"
            if ($script:MountedVhdxPath -eq $VhdxPath) {
                $script:MountedVhdxPath = $null
            }
        }
    } catch {
        Write-GSLog "Erreur demontage $VhdxPath : $_" -Level "WARNING"
    }
}

# ---------------------------------------------------------------------------
function Get-MountedGSVhdxPath {
    return $script:MountedVhdxPath
}

# Fallback interne : retrouver le chemin via la lettre de lecteur
function Get-MountedGSVhdxPathByDrive {
    try {
        $partition = Get-Partition -DriveLetter $script:DriveLetter -ErrorAction SilentlyContinue
        if (-not $partition) { return $null }

        $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction SilentlyContinue
        if (-not $disk) { return $null }

        # Pour un VHDX monte via Mount-DiskImage, la propriete Location contient le chemin du fichier
        $location = $disk.Location
        if (-not [string]::IsNullOrEmpty($location) -and (Test-Path $location)) {
            return $location
        }
    } catch {
        Write-GSLog "Erreur recherche VHDX monte: $_" -Level "DEBUG"
    }
    return $null
}

function Get-DriveLetter { return $script:DriveLetter }

Export-ModuleMember -Function Mount-GSVhdx, Dismount-GSVhdx, Dismount-GSVhdxByPath, Get-MountedGSVhdxPath, Get-DriveLetter
