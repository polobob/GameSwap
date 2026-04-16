#Requires -Version 5.1
# GameSwap.ps1 - Point d'entree principal
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding            = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---------------------------------------------------------------------------
# Chargement des modules
# ---------------------------------------------------------------------------
$ModulesDir = Join-Path $ScriptDir "Modules"
$modules    = @("GS-Log","GS-Init","GS-Account","GS-Share","GS-Network","GS-VHDX","GS-Games","GS-UI")

foreach ($mod in $modules) {
    $modPath = Join-Path $ModulesDir "$mod.psm1"
    if (-not (Test-Path $modPath)) {
        Write-Host "[FATAL] Module introuvable: $modPath" -ForegroundColor Red
        Read-Host "Appuyez sur Entree pour quitter"
        exit 1
    }
    Import-Module $modPath -Force -ErrorAction Stop
}

# ---------------------------------------------------------------------------
# Initialisation du journal
# ---------------------------------------------------------------------------
$LogDir = Join-Path $ScriptDir "logs"
Initialize-GSLog -LogDir $LogDir
Write-GSLog "GameSwap demarre depuis: $ScriptDir" -Level "INFO"
Write-GSLog "PowerShell version: $($PSVersionTable.PSVersion)" -Level "INFO"

# ---------------------------------------------------------------------------
# Verification des droits administrateur
# ---------------------------------------------------------------------------
if (-not (Test-AdminRights)) {
    Write-GSLog "Droits administrateur manquants - arret" -Level "ERROR"
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "GameSwap necessite des droits administrateur.`nRelancez l'application via Start-GameSwap.bat",
        "Droits insuffisants", "OK", "Error") | Out-Null
    exit 1
}
Write-GSLog "Droits administrateur confirmes" -Level "INFO"

# ---------------------------------------------------------------------------
# Verification de Mount-DiskImage
# ---------------------------------------------------------------------------
if (-not (Test-MountDiskImage)) {
    Write-GSLog "Mount-DiskImage non disponible" -Level "ERROR"
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "Mount-DiskImage n'est pas disponible sur ce systeme.`nVerifiez que la fonctionnalite 'Hyper-V' ou 'Disques virtuels' est activee.",
        "Composant manquant", "OK", "Error") | Out-Null
    exit 1
}
Write-GSLog "Mount-DiskImage disponible" -Level "INFO"

# ---------------------------------------------------------------------------
# Verification du lecteur U: (VHDX residuel d'une session precedente)
# ---------------------------------------------------------------------------
if (Test-Path "U:\") {
    Write-GSLog "Lecteur U: deja monte au demarrage - tentative de demontage..." -Level "WARNING"
    Dismount-GSVhdx
    Start-Sleep -Milliseconds 500
    if (Test-Path "U:\") {
        Write-GSLog "Impossible de demonter le lecteur U:" -Level "ERROR"
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            "Le lecteur U: est occupe et n'a pas pu etre libere automatiquement." +
            "`n`nGameSwap utilise la lettre U: pour monter les jeux." +
            "`n`nFermez le programme qui utilise U: puis relancez GameSwap.",
            "Lecteur U: occupe", "OK", "Warning") | Out-Null
    } else {
        Write-GSLog "Lecteur U: demonté avec succes au demarrage" -Level "INFO"
    }
}

# ---------------------------------------------------------------------------
# Chargement des parametres
# ---------------------------------------------------------------------------
$Settings = Get-GSSettings
Write-GSLog "Parametres: Initialise=$($Settings.Initialized) Joueur='$($Settings.PlayerName)'" -Level "INFO"

# ---------------------------------------------------------------------------
# Premier lancement : assistant de configuration
# ---------------------------------------------------------------------------
if (-not $Settings.Initialized) {
    Write-GSLog "Premier lancement - assistant de configuration" -Level "INFO"

    $wizResult = Show-GSWizard -ScriptDir $ScriptDir -Settings $Settings

    if (-not $wizResult) {
        Write-GSLog "Configuration annulee par l'utilisateur" -Level "WARNING"
        exit 0
    }

    Write-GSLog "Configuration choisie: dossier='$($wizResult.GameSwapFolder)' joueur='$($wizResult.PlayerName)'" -Level "INFO"

    # Creer le dossier GameSwap si necessaire
    if (-not (Test-Path $wizResult.GameSwapFolder)) {
        New-Item -ItemType Directory -Path $wizResult.GameSwapFolder -Force | Out-Null
        Write-GSLog "Dossier GameSwap cree: $($wizResult.GameSwapFolder)" -Level "INFO"
    }

    # Creer le compte local GameSwap
    Write-GSLog "Creation du compte local GameSwap..." -Level "INFO"
    New-GSLocalAccount

    # Configurer le partage SMB
    Write-GSLog "Configuration du partage reseau..." -Level "INFO"
    New-GSShare -FolderPath $wizResult.GameSwapFolder -PlayerName $wizResult.PlayerName
    Set-GSQueueMaxSlots -ShareRootPath $wizResult.GameSwapFolder -MaxSlots $Settings.MaxDownloadSlots

    # Installer nmap si absent
    Write-GSLog "Verification de nmap..." -Level "INFO"
    Install-NmapIfNeeded | Out-Null

    # Sauvegarder les parametres
    $Settings.Initialized    = $true
    $Settings.PlayerName     = $wizResult.PlayerName
    $Settings.GameSwapFolder = $wizResult.GameSwapFolder
    Save-GSSettings -Settings $Settings

    Write-GSLog "Initialisation terminee avec succes" -Level "INFO"

} else {
    # Verifications au demarrage normal
    if (-not (Test-GSShare -FolderPath $Settings.GameSwapFolder)) {
        Write-GSLog "Partage absent - recreation..." -Level "WARNING"
        New-GSShare -FolderPath $Settings.GameSwapFolder -PlayerName $Settings.PlayerName
        Set-GSQueueMaxSlots -ShareRootPath $Settings.GameSwapFolder -MaxSlots $Settings.MaxDownloadSlots
    }

    Install-NmapIfNeeded | Out-Null
}

# ---------------------------------------------------------------------------
# Lancement de l'interface principale
# ---------------------------------------------------------------------------
Write-GSLog "Lancement de l'interface principale" -Level "INFO"

try {
    Show-GSMainWindow -Settings $Settings -ScriptDir $ScriptDir
} catch {
    Write-GSLog "Erreur critique dans l'interface: $_" -Level "ERROR"
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "Une erreur inattendue s'est produite :`n$_`n`nConsultez les logs pour plus de details.",
        "Erreur GameSwap", "OK", "Error") | Out-Null
}

Write-GSLog "GameSwap ferme" -Level "INFO"
