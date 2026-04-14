#Requires -Version 5.1
# Module GS-Init.psm1 - Verification et initialisation de l'environnement GameSwap
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

$script:AppDataPath = Join-Path $env:APPDATA "GameSwap"
$script:SettingsFile = Join-Path $script:AppDataPath "settings.json"

function Test-AdminRights {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-MountDiskImage {
    return ($null -ne (Get-Command Mount-DiskImage -ErrorAction SilentlyContinue))
}

function Get-GSSettings {
    if (Test-Path $script:SettingsFile) {
        try {
            $json = Get-Content $script:SettingsFile -Raw -Encoding UTF8
            $obj  = $json | ConvertFrom-Json
            # Migration : ajouter les champs absents des anciennes versions
            if ($null -eq $obj.PSObject.Properties['SelectedAdapterIP']) {
                $obj | Add-Member -NotePropertyName SelectedAdapterIP -NotePropertyValue "" -Force
            }
            if ($null -eq $obj.PSObject.Properties['MaxDownloadSlots']) {
                $obj | Add-Member -NotePropertyName MaxDownloadSlots -NotePropertyValue 3 -Force
            }
            Write-GSLog "Parametres charges depuis $($script:SettingsFile)" -Level "INFO"
            return $obj
        } catch {
            Write-GSLog "Erreur lecture parametres: $_" -Level "WARNING"
        }
    }
    return [PSCustomObject]@{
        Initialized        = $false
        PlayerName         = ""
        GameSwapFolder     = ""
        ShareName          = "GameSwap"
        SelectedAdapterIP  = ""
        MaxDownloadSlots   = 3
    }
}

function Save-GSSettings {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Settings
    )
    if (-not (Test-Path $script:AppDataPath)) {
        New-Item -ItemType Directory -Path $script:AppDataPath -Force | Out-Null
    }
    $Settings | ConvertTo-Json | Set-Content $script:SettingsFile -Encoding UTF8
    Write-GSLog "Parametres sauvegardes dans $($script:SettingsFile)" -Level "INFO"
}

function Install-NmapIfNeeded {
    $nmapCmd = Get-Command nmap.exe -ErrorAction SilentlyContinue
    if ($nmapCmd) {
        Write-GSLog "nmap deja installe: $($nmapCmd.Source)" -Level "INFO"
        return $true
    }

    Write-GSLog "nmap introuvable - installation via winget..." -Level "INFO"
    try {
        $proc = Start-Process -FilePath "winget" `
            -ArgumentList "install --id Insecure.Nmap --silent --accept-package-agreements --accept-source-agreements" `
            -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -eq 0) {
            # Rafraichir le PATH
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("PATH","User")
            Write-GSLog "nmap installe avec succes" -Level "INFO"
            return $true
        } else {
            Write-GSLog "winget a retourne le code: $($proc.ExitCode)" -Level "WARNING"
            return $false
        }
    } catch {
        Write-GSLog "Erreur installation nmap: $_" -Level "ERROR"
        return $false
    }
}

function Get-AppDataPath {
    return $script:AppDataPath
}

Export-ModuleMember -Function Test-AdminRights, Test-MountDiskImage, Get-GSSettings, Save-GSSettings, Install-NmapIfNeeded, Get-AppDataPath
