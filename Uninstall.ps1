#Requires -Version 5.1
# Uninstall.ps1 - Desinstallation de GameSwap
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding            = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDataPath = Join-Path $env:APPDATA "GameSwap"
$SettingsFile= Join-Path $AppDataPath "settings.json"
$LogDir      = Join-Path $ScriptDir "logs"

function Write-UninstallLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts][$Level] (Uninstall) $Message"
    Write-Host $line -ForegroundColor $(switch ($Level) { "ERROR" {"Red"} "WARNING" {"Yellow"} default {"Cyan"} })
    if (Test-Path $LogDir) {
        $logFile = Join-Path $LogDir "GameSwap_$(Get-Date -Format 'yyyyMMdd').log"
        Add-Content -Path $logFile -Value $line -Encoding UTF8
    }
}

function Test-Admin {
    $id  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p   = [Security.Principal.WindowsPrincipal]$id
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ---------------------------------------------------------------------------
# Verifier les droits admin
# ---------------------------------------------------------------------------
if (-not (Test-Admin)) {
    [System.Windows.MessageBox]::Show(
        "La desinstallation necessite des droits administrateur.`nRelancez via Uninstall.bat",
        "Droits insuffisants", "OK", "Error") | Out-Null
    exit 1
}

Write-UninstallLog "Demarrage de la desinstallation GameSwap"

# ---------------------------------------------------------------------------
# Lire les settings pour connaitre le dossier des jeux
# ---------------------------------------------------------------------------
$gameSwapFolder = ""
if (Test-Path $SettingsFile) {
    try {
        $settings       = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $gameSwapFolder = $settings.GameSwapFolder
    } catch {
        Write-UninstallLog "Impossible de lire les settings: $_" -Level "WARNING"
    }
}

# ---------------------------------------------------------------------------
# Confirmation initiale
# ---------------------------------------------------------------------------
$confirmMsg = "Desinstaller GameSwap ?`n`nLes actions suivantes seront effectuees :`n"
$confirmMsg += "  - Suppression du compte local 'GameSwap'`n"
$confirmMsg += "  - Suppression du partage reseau 'GameSwap'`n"
$confirmMsg += "  - Suppression du dossier de configuration ($AppDataPath)`n"
$confirmMsg += "  - Desinstallation de nmap`n"
$confirmMsg += "`nVous pourrez choisir si vous souhaitez supprimer les jeux."

$confirm = [System.Windows.MessageBox]::Show(
    $confirmMsg, "Desinstallation de GameSwap", "YesNo", "Warning")

if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
    Write-UninstallLog "Desinstallation annulee par l'utilisateur"
    exit 0
}

$errors = @()

# ---------------------------------------------------------------------------
# 1. Supprimer le partage SMB
# ---------------------------------------------------------------------------
Write-UninstallLog "Suppression du partage SMB 'GameSwap'..."
try {
    $share = Get-SmbShare -Name "GameSwap" -ErrorAction SilentlyContinue
    if ($share) {
        cmd /c "net share GameSwap /DELETE /Y" 2>&1 | Out-Null
        Write-UninstallLog "Partage SMB supprime"
    } else {
        Write-UninstallLog "Partage SMB introuvable (deja supprime)" -Level "WARNING"
    }
} catch {
    $errors += "Partage SMB : $_"
    Write-UninstallLog "Erreur suppression partage: $_" -Level "ERROR"
}

# ---------------------------------------------------------------------------
# 2. Supprimer le compte local GameSwap
# ---------------------------------------------------------------------------
Write-UninstallLog "Suppression du compte local 'GameSwap'..."
try {
    $user = Get-LocalUser -Name "GameSwap" -ErrorAction SilentlyContinue
    if ($user) {
        Remove-LocalUser -Name "GameSwap" -ErrorAction Stop
        Write-UninstallLog "Compte local 'GameSwap' supprime"
    } else {
        Write-UninstallLog "Compte 'GameSwap' introuvable (deja supprime)" -Level "WARNING"
    }
} catch {
    $errors += "Compte local : $_"
    Write-UninstallLog "Erreur suppression compte: $_" -Level "ERROR"
}

# ---------------------------------------------------------------------------
# 3. Supprimer le dossier AppData\GameSwap
# ---------------------------------------------------------------------------
Write-UninstallLog "Suppression du dossier de configuration..."
try {
    if (Test-Path $AppDataPath) {
        Remove-Item -Path $AppDataPath -Recurse -Force -ErrorAction Stop
        Write-UninstallLog "Dossier supprime : $AppDataPath"
    } else {
        Write-UninstallLog "Dossier AppData GameSwap introuvable" -Level "WARNING"
    }
} catch {
    $errors += "AppData : $_"
    Write-UninstallLog "Erreur suppression AppData: $_" -Level "ERROR"
}

# ---------------------------------------------------------------------------
# 4. Desinstaller nmap
# ---------------------------------------------------------------------------
Write-UninstallLog "Desinstallation de nmap..."
try {
    $nmapPkg = winget list --id Insecure.Nmap 2>&1 | Select-String "Insecure.Nmap"
    if ($nmapPkg) {
        winget uninstall --id Insecure.Nmap --silent --accept-source-agreements 2>&1 | Out-Null
        Write-UninstallLog "nmap desinstalle"
    } else {
        Write-UninstallLog "nmap introuvable (deja desinstalle ou non present)" -Level "WARNING"
    }
} catch {
    $errors += "nmap : $_"
    Write-UninstallLog "Erreur desinstallation nmap: $_" -Level "ERROR"
}

# ---------------------------------------------------------------------------
# 5. Choix de supprimer le dossier des jeux
# ---------------------------------------------------------------------------
if ($gameSwapFolder -and (Test-Path $gameSwapFolder)) {
    $jeuxMsg  = "Supprimer egalement le dossier des jeux ?`n`n"
    $jeuxMsg += "$gameSwapFolder`n`n"
    $jeuxMsg += "ATTENTION : Tous les fichiers VHDX et jeux installes seront perdus."

    $deleteGames = [System.Windows.MessageBox]::Show(
        $jeuxMsg, "Supprimer les jeux ?", "YesNo", "Warning")

    if ($deleteGames -eq [System.Windows.MessageBoxResult]::Yes) {
        Write-UninstallLog "Suppression du dossier des jeux : $gameSwapFolder"
        try {
            # Demonter tout VHDX eventuellement monte sur U:
            $uPartition = Get-Partition -DriveLetter "U" -ErrorAction SilentlyContinue
            if ($uPartition) {
                $uDisk = Get-Disk -Number $uPartition.DiskNumber -ErrorAction SilentlyContinue
                if ($uDisk) {
                    $imgs = Get-DiskImage -ErrorAction SilentlyContinue | Where-Object { $_.Attached }
                    foreach ($img in @($imgs)) {
                        if (-not [string]::IsNullOrEmpty($img.ImagePath)) {
                            Dismount-DiskImage -ImagePath $img.ImagePath -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
            Start-Sleep -Milliseconds 500
            Remove-Item -Path $gameSwapFolder -Recurse -Force -ErrorAction Stop
            Write-UninstallLog "Dossier des jeux supprime"
        } catch {
            $errors += "Dossier jeux : $_"
            Write-UninstallLog "Erreur suppression dossier jeux: $_" -Level "ERROR"
        }
    } else {
        Write-UninstallLog "Dossier des jeux conserve : $gameSwapFolder"
    }
} else {
    Write-UninstallLog "Dossier des jeux introuvable ou non configure, rien a supprimer" -Level "WARNING"
}

# ---------------------------------------------------------------------------
# Bilan
# ---------------------------------------------------------------------------
if ($errors.Count -gt 0) {
    $errMsg = "La desinstallation s'est terminee avec $($errors.Count) erreur(s) :`n`n"
    $errMsg += ($errors -join "`n")
    $errMsg += "`n`nConsultez les logs pour le detail."
    [System.Windows.MessageBox]::Show($errMsg, "Desinstallation partielle", "OK", "Warning") | Out-Null
    Write-UninstallLog "Desinstallation terminee avec erreurs"
} else {
    [System.Windows.MessageBox]::Show(
        "GameSwap a ete desinstalle avec succes.",
        "Desinstallation terminee", "OK", "Information") | Out-Null
    Write-UninstallLog "Desinstallation terminee avec succes"
}
