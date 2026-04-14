#Requires -Version 5.1
# Module GS-Share.psm1 - Gestion du partage reseau SMB GameSwap
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

$script:ShareName = "GameSwap"

function Test-GSShare {
    $share = Get-SmbShare -Name $script:ShareName -ErrorAction SilentlyContinue
    return ($null -ne $share)
}

function New-GSShare {
    param(
        [Parameter(Mandatory)]
        [string]$FolderPath,
        [Parameter(Mandatory)]
        [string]$PlayerName
    )

    # Supprimer le partage existant si present
    if (Test-GSShare) {
        Write-GSLog "Suppression du partage existant '$($script:ShareName)'" -Level "INFO"
        cmd /c "net share $($script:ShareName) /DELETE /Y" 2>&1 | Out-Null
        Start-Sleep -Milliseconds 500
    }

    # Creer le sous-dossier Jeux si absent
    $jeuxFolder = Join-Path $FolderPath "Jeux"
    if (-not (Test-Path $jeuxFolder)) {
        New-Item -ItemType Directory -Path $jeuxFolder -Force | Out-Null
        Write-GSLog "Dossier Jeux cree: $jeuxFolder" -Level "INFO"
    }

    # Ajouter les permissions NTFS pour l'utilisateur GameSwap (Modify pour la queue)
    try {
        $acl  = Get-Acl $FolderPath
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            (Get-GSAccountName),
            "Modify",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl -Path $FolderPath -AclObject $acl
        Write-GSLog "Permissions NTFS configurees pour $(Get-GSAccountName)" -Level "INFO"
    } catch {
        Write-GSLog "Avertissement permissions NTFS: $_" -Level "WARNING"
    }

    # Creer le partage via net share avec permission CHANGE (lecture + ecriture)
    $comment = "GameSwap|$PlayerName"
    $gsUser  = Get-GSAccountName
    $cmd     = "net share $($script:ShareName)=""$FolderPath"" /GRANT:$gsUser,CHANGE /REMARK:""$comment"" /UNLIMITED"

    Write-GSLog "Creation du partage: $cmd" -Level "INFO"
    $output = cmd /c $cmd 2>&1
    $output | ForEach-Object { Write-GSLog "  net share: $_" -Level "DEBUG" }

    if (-not (Test-GSShare)) {
        Write-GSLog "Echec creation du partage SMB" -Level "ERROR"
        throw "Impossible de creer le partage reseau '$($script:ShareName)'"
    }

    # Ecrire le fichier d'info du joueur a la racine du partage
    Save-GSShareInfo -FolderPath $FolderPath -PlayerName $PlayerName

    Write-GSLog "Partage '$($script:ShareName)' cree sur '$FolderPath'" -Level "INFO"
}

function Save-GSShareInfo {
    param(
        [string]$FolderPath,
        [string]$PlayerName
    )
    $infoFile = Join-Path $FolderPath "gameswap_info.json"
    $info = [PSCustomObject]@{
        PlayerName = $PlayerName
        Version    = "1.0"
        ShareName  = $script:ShareName
    }
    $info | ConvertTo-Json | Set-Content $infoFile -Encoding UTF8
    Write-GSLog "Fichier d'info joueur ecrit: $infoFile" -Level "INFO"
}

function Remove-GSShare {
    if (Test-GSShare) {
        cmd /c "net share $($script:ShareName) /DELETE /Y" 2>&1 | Out-Null
        Write-GSLog "Partage '$($script:ShareName)' supprime" -Level "INFO"
    }
}

function Get-GSShareName { return $script:ShareName }

# ---------------------------------------------------------------------------
# Gestion de la file de telechargement (download_queue.json)
# ---------------------------------------------------------------------------
$script:MaxSlots    = 3
$script:SlotTimeout = 30  # minutes

function Get-GSQueueFile {
    param([Parameter(Mandatory)][string]$ShareRootPath)
    return Join-Path $ShareRootPath "download_queue.json"
}

function Read-GSQueue {
    param([Parameter(Mandatory)][string]$QueueFile)
    if (-not (Test-Path $QueueFile)) { return @() }
    try {
        $json = Get-Content $QueueFile -Raw -Encoding UTF8
        $data = $json | ConvertFrom-Json
        return @($data.slots)
    } catch { return @() }
}

function Get-GSNasMaxSlots {
    # Lit MaxDownloadSlots depuis gameswap_user.json (NAS uniquement)
    param([Parameter(Mandatory)][string]$ShareRootPath)
    $userFile = Join-Path $ShareRootPath "gameswap_user.json"
    if (Test-Path $userFile) {
        try {
            $data = Get-Content $userFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $data.MaxDownloadSlots) { return [int]$data.MaxDownloadSlots }
        } catch {}
    }
    return $null  # null = pas un NAS ou champ absent
}

function Read-GSQueueInfo {
    param([Parameter(Mandatory)][string]$QueueFile)
    $shareRoot = Split-Path $QueueFile -Parent

    # Fallback maxSlots : gameswap_user.json (NAS) puis valeur par defaut du module
    $nasMax    = Get-GSNasMaxSlots -ShareRootPath $shareRoot
    $defaultMs = if ($null -ne $nasMax) { $nasMax } else { $script:MaxSlots }

    if (-not (Test-Path $QueueFile)) {
        return [PSCustomObject]@{ maxSlots = $defaultMs; slots = @() }
    }
    try {
        $json = Get-Content $QueueFile -Raw -Encoding UTF8
        $data = $json | ConvertFrom-Json
        $ms   = if ($null -ne $data.maxSlots) { [int]$data.maxSlots } else { $defaultMs }
        return [PSCustomObject]@{ maxSlots = $ms; slots = @($data.slots) }
    } catch {
        return [PSCustomObject]@{ maxSlots = $defaultMs; slots = @() }
    }
}

function Write-GSQueue {
    param(
        [Parameter(Mandatory)][string]$QueueFile,
        [Parameter(Mandatory)][array]$Slots
    )
    $shareRoot = Split-Path $QueueFile -Parent

    # Priorite pour maxSlots : 1) download_queue.json existant  2) gameswap_user.json (NAS)  3) defaut module
    $existingMax = $script:MaxSlots
    if (Test-Path $QueueFile) {
        try {
            $existing = Get-Content $QueueFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $existing.maxSlots) { $existingMax = [int]$existing.maxSlots }
        } catch {}
    } else {
        $nasMax = Get-GSNasMaxSlots -ShareRootPath $shareRoot
        if ($null -ne $nasMax) { $existingMax = $nasMax }
    }

    $obj = [PSCustomObject]@{ maxSlots = $existingMax; slots = $Slots }
    $obj | ConvertTo-Json -Depth 3 | Set-Content $QueueFile -Encoding UTF8
}

function Set-GSQueueMaxSlots {
    param(
        [Parameter(Mandatory)][string]$ShareRootPath,
        [Parameter(Mandatory)][int]$MaxSlots
    )
    $queueFile = Get-GSQueueFile -ShareRootPath $ShareRootPath
    $slots     = @(Read-GSQueue -QueueFile $queueFile)
    $obj       = [PSCustomObject]@{ maxSlots = $MaxSlots; slots = $slots }
    $obj | ConvertTo-Json -Depth 3 | Set-Content $queueFile -Encoding UTF8
    Write-GSLog "maxSlots mis a jour : $MaxSlots" -Level "INFO"
}

function Add-GSDownloadSlot {
    param(
        [Parameter(Mandatory)][string]$ShareRootPath,
        [Parameter(Mandatory)][string]$PlayerName,
        [Parameter(Mandatory)][string]$GameName
    )

    $queueFile = Get-GSQueueFile -ShareRootPath $ShareRootPath
    $queueInfo = Read-GSQueueInfo -QueueFile $queueFile
    $maxSlots  = $queueInfo.maxSlots
    $slots     = @($queueInfo.slots)

    # Purger les slots expires
    $cutoff = (Get-Date).AddMinutes(-$script:SlotTimeout)
    $slots  = @($slots | Where-Object {
        $slotTime = [datetime]::MinValue
        if ([datetime]::TryParse($_.StartedAt, [ref]$slotTime)) { $slotTime -gt $cutoff }
        else { $false }
    })

    if ($slots.Count -ge $maxSlots) {
        return [PSCustomObject]@{
            Success  = $false
            Blockers = @($slots | ForEach-Object { "$($_.PlayerName) ($($_.GameName))" })
        }
    }

    $slots += [PSCustomObject]@{
        PlayerName = $PlayerName
        GameName   = $GameName
        StartedAt  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        Write-GSQueue -QueueFile $queueFile -Slots $slots
        return [PSCustomObject]@{ Success = $true; Blockers = @() }
    } catch {
        Write-GSLog "Impossible d'ecrire download_queue.json : $_" -Level "WARNING"
        return [PSCustomObject]@{ Success = $true; Blockers = @() }  # ne pas bloquer si le fichier est inaccessible
    }
}

function Remove-GSDownloadSlot {
    param(
        [Parameter(Mandatory)][string]$ShareRootPath,
        [Parameter(Mandatory)][string]$PlayerName,
        [Parameter(Mandatory)][string]$GameName
    )

    $queueFile = Get-GSQueueFile -ShareRootPath $ShareRootPath
    $slots     = @(Read-GSQueue -QueueFile $queueFile)
    $slots     = @($slots | Where-Object { -not ($_.PlayerName -eq $PlayerName -and $_.GameName -eq $GameName) })
    try { Write-GSQueue -QueueFile $queueFile -Slots $slots } catch {}
}

function Get-GSDownloadQueue {
    param([Parameter(Mandatory)][string]$ShareRootPath)
    $queueFile = Get-GSQueueFile -ShareRootPath $ShareRootPath
    $slots     = @(Read-GSQueue -QueueFile $queueFile)

    # Purger les expires avant de retourner
    $cutoff = (Get-Date).AddMinutes(-$script:SlotTimeout)
    $active = @($slots | Where-Object {
        $slotTime = [datetime]::MinValue
        if ([datetime]::TryParse($_.StartedAt, [ref]$slotTime)) { $slotTime -gt $cutoff }
        else { $false }
    })

    if ($active.Count -ne $slots.Count) {
        try { Write-GSQueue -QueueFile $queueFile -Slots $active } catch {}
    }
    return $active
}

function Clear-GSDownloadSlot {
    param(
        [Parameter(Mandatory)][string]$ShareRootPath,
        [Parameter(Mandatory)][string]$SlotIndex
    )
    $queueFile = Get-GSQueueFile -ShareRootPath $ShareRootPath
    $slots     = @(Read-GSQueue -QueueFile $queueFile)
    $newSlots  = @()
    for ($i = 0; $i -lt $slots.Count; $i++) {
        if ($i -ne [int]$SlotIndex) { $newSlots += $slots[$i] }
    }
    try { Write-GSQueue -QueueFile $queueFile -Slots $newSlots } catch {}
}

Export-ModuleMember -Function Test-GSShare, New-GSShare, Remove-GSShare, Save-GSShareInfo, Get-GSShareName, `
    Add-GSDownloadSlot, Remove-GSDownloadSlot, Get-GSDownloadQueue, Clear-GSDownloadSlot, Read-GSQueueInfo, Set-GSQueueMaxSlots
