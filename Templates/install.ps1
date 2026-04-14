#Requires -Version 5.1
# =============================================================================
#  TEMPLATE install.ps1 - GameSwap
#  Ce fichier doit etre place A LA RACINE du disque VHDX du jeu.
#  Il est execute automatiquement par GameSwap lors de l'installation.
#
#  PARAMETRES RECUS :
#    -GameFolder  : Chemin du dossier local du jeu (ex: D:\GameSwap\Jeux\MonJeu)
#    -GameName    : Nom du jeu (ex: MonJeu)
#
#  VARIABLES DISPONIBLES :
#    $VhdxDrive   : Lettre du lecteur VHDX monte (ex: U:)
#    $GameFolder  : Dossier de destination du jeu
#    $GameName    : Nom du jeu
#    $PlayerName  : Nom du joueur GameSwap (lu depuis les settings GameSwap)
#
#  A FAIRE : Remplacez les sections marquees "# TODO" avec vos propres actions.
#  Encodage: UTF-8 BOM | Fins de ligne: CRLF
# =============================================================================

param(
    [Parameter(Mandatory)]
    [string]$GameFolder,

    [Parameter(Mandatory)]
    [string]$GameName
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$VhdxDrive = "U:"

function Write-InstallLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        default   { "Cyan" }
    }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
}

Write-InstallLog "=== Installation de '$GameName' ==="
Write-InstallLog "Lecteur VHDX : $VhdxDrive"
Write-InstallLog "Dossier cible : $GameFolder"

# =============================================================================
# LECTURE DU NOM DE JOUEUR GAMESWAP (automatique - ne pas modifier)
# =============================================================================
$PlayerName = ""
$gsSettingsFile = Join-Path $env:APPDATA "GameSwap\settings.json"
if (Test-Path $gsSettingsFile) {
    try {
        $gsSettings = Get-Content $gsSettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $PlayerName = $gsSettings.PlayerName
        Write-InstallLog "Nom de joueur GameSwap : $PlayerName"
    } catch {
        Write-InstallLog "Impossible de lire les settings GameSwap : $_" -Level "WARNING"
    }
} else {
    Write-InstallLog "Fichier settings GameSwap introuvable, nom de joueur vide" -Level "WARNING"
}

# =============================================================================
# ETAPE 1 : Prerequis systeme
# TODO : Decommenter et adapter selon les besoins du jeu
# =============================================================================

# -- Installer un redistribuable Visual C++ --
# $vcRedist = Join-Path $VhdxDrive "Redist\vcredist_x64.exe"
# if (Test-Path $vcRedist) {
#     Write-InstallLog "Installation Visual C++ Redistributable..."
#     Start-Process $vcRedist -ArgumentList "/install /quiet /norestart" -Wait
# }

# -- Installer DirectX --
# $dxSetup = Join-Path $VhdxDrive "Redist\DirectX\DXSETUP.exe"
# if (Test-Path $dxSetup) {
#     Write-InstallLog "Installation DirectX..."
#     Start-Process $dxSetup -ArgumentList "/silent" -Wait
# }

# -- Installer .NET Framework (exemple) --
# $dotnet = Join-Path $VhdxDrive "Redist\dotnetfx.exe"
# if (Test-Path $dotnet) {
#     Write-InstallLog "Installation .NET Framework..."
#     Start-Process $dotnet -ArgumentList "/q /norestart" -Wait
# }

Write-InstallLog "Etape 1 : prerequis OK (adapter selon le jeu)"

# =============================================================================
# ETAPE 2 : Cles de registre
# TODO : Ajouter les cles de registre necessaires au jeu
# =============================================================================

# Exemple : cle de registre pour chemin d'installation
# $regKey = "HKCU:\Software\MonJeu"
# if (-not (Test-Path $regKey)) {
#     New-Item -Path $regKey -Force | Out-Null
# }
# Set-ItemProperty -Path $regKey -Name "InstallPath" -Value "$VhdxDrive\"
# Set-ItemProperty -Path $regKey -Name "Version"     -Value "1.0"
# Write-InstallLog "Cles de registre configurees"

Write-InstallLog "Etape 2 : registre OK (adapter selon le jeu)"

# =============================================================================
# ETAPE 3 : Dossier Settings du jeu (account_name.txt et language.txt)
# TODO : Definissez le chemin du dossier settings du jeu si necessaire,
#        puis decommentez le bloc ci-dessous.
#        Le dossier doit deja exister dans le VHDX - il ne sera pas cree.
#        Exemples :
#          $settingsDir = Join-Path $VhdxDrive "settings"
#          $settingsDir = Join-Path $VhdxDrive "Data\Settings"
#          $settingsDir = Join-Path $VhdxDrive "MyGame\config"
# =============================================================================

# $settingsDir = Join-Path $VhdxDrive "settings"   # TODO : adapter le chemin
#
# if (Test-Path $settingsDir) {
#
#     # account_name.txt : nom du joueur GameSwap
#     $accountFile = Join-Path $settingsDir "account_name.txt"
#     try {
#         [System.IO.File]::WriteAllText($accountFile, $PlayerName, [System.Text.Encoding]::UTF8)
#         Write-InstallLog "account_name.txt ecrit : $PlayerName"
#     } catch {
#         Write-InstallLog "Erreur ecriture account_name.txt : $_" -Level "ERROR"
#         exit 1
#     }
#
#     # language.txt : langue configuree pour le jeu
#     $languageFile = Join-Path $settingsDir "language.txt"
#     try {
#         [System.IO.File]::WriteAllText($languageFile, "french", [System.Text.Encoding]::UTF8)
#         Write-InstallLog "language.txt ecrit : french"
#     } catch {
#         Write-InstallLog "Erreur ecriture language.txt : $_" -Level "ERROR"
#         exit 1
#     }
#
#     Write-InstallLog "Etape 3 : settings du jeu OK"
# } else {
#     Write-InstallLog "Dossier settings introuvable, etape ignoree : $settingsDir" -Level "WARNING"
# }

Write-InstallLog "Etape 3 : settings du jeu (desactive - adapter si necessaire)"

# =============================================================================
# ETAPE 3b : Dossier Steam Settings (force_account_name.txt et force_language.txt)
# TODO : Definissez le chemin du dossier steam_settings si necessaire,
#        puis decommentez le bloc ci-dessous.
#        Le dossier doit deja exister dans le VHDX - il ne sera pas cree.
#        Exemples :
#          $steamSettingsDir = Join-Path $VhdxDrive "steam_settings"
#          $steamSettingsDir = Join-Path $VhdxDrive "Data\steam_settings"
#          $steamSettingsDir = Join-Path $VhdxDrive "Goldberg\steam_settings"
# =============================================================================

# $steamSettingsDir = Join-Path $VhdxDrive "steam_settings"   # TODO : adapter le chemin
#
# if (Test-Path $steamSettingsDir) {
#
#     # force_account_name.txt : nom du joueur GameSwap
#     $steamAccountFile = Join-Path $steamSettingsDir "force_account_name.txt"
#     try {
#         [System.IO.File]::WriteAllText($steamAccountFile, $PlayerName, [System.Text.Encoding]::UTF8)
#         Write-InstallLog "force_account_name.txt ecrit : $PlayerName"
#     } catch {
#         Write-InstallLog "Erreur ecriture force_account_name.txt : $_" -Level "ERROR"
#         exit 1
#     }
#
#     # force_language.txt : langue configuree pour le jeu
#     $steamLanguageFile = Join-Path $steamSettingsDir "force_language.txt"
#     try {
#         [System.IO.File]::WriteAllText($steamLanguageFile, "french", [System.Text.Encoding]::UTF8)
#         Write-InstallLog "force_language.txt ecrit : french"
#     } catch {
#         Write-InstallLog "Erreur ecriture force_language.txt : $_" -Level "ERROR"
#         exit 1
#     }
#
#     Write-InstallLog "Etape 3b : steam_settings OK"
# } else {
#     Write-InstallLog "Dossier steam_settings introuvable, etape ignoree : $steamSettingsDir" -Level "WARNING"
# }

Write-InstallLog "Etape 3b : steam_settings (desactive - adapter si necessaire)"

# =============================================================================
# ETAPE 3c : Modification de steam_emu.ini (UserName et Language)
# TODO : Definissez le chemin du fichier steam_emu.ini si necessaire,
#        puis decommentez le bloc ci-dessous.
#        Le fichier doit deja exister dans le VHDX - il ne sera pas cree.
#        Seules les lignes UserName= et Language= sont modifiees,
#        tout le reste du fichier est conserve.
#        Exemples :
#          $steamEmuIni = Join-Path $VhdxDrive "steam_emu.ini"
#          $steamEmuIni = Join-Path $VhdxDrive "Crack\steam_emu.ini"
#          $steamEmuIni = Join-Path $VhdxDrive "Data\steam_emu.ini"
# =============================================================================

# $steamEmuIni = Join-Path $VhdxDrive "steam_emu.ini"   # TODO : adapter le chemin
#
# if (Test-Path $steamEmuIni) {
#     try {
#         $content = [System.IO.File]::ReadAllText($steamEmuIni, [System.Text.Encoding]::UTF8)
#         $content = $content -replace '(?m)^UserName=[^\r\n]*', "UserName=$PlayerName"
#         $content = $content -replace '(?m)^Language=[^\r\n]*', "Language=French"
#         [System.IO.File]::WriteAllText($steamEmuIni, $content, [System.Text.Encoding]::UTF8)
#         Write-InstallLog "steam_emu.ini mis a jour : UserName=$PlayerName, Language=French"
#     } catch {
#         Write-InstallLog "Erreur modification steam_emu.ini : $_" -Level "ERROR"
#         exit 1
#     }
# } else {
#     Write-InstallLog "steam_emu.ini introuvable, etape ignoree : $steamEmuIni" -Level "WARNING"
# }

Write-InstallLog "Etape 3c : steam_emu.ini (desactive - adapter si necessaire)"

# =============================================================================
# ETAPE 3d : Modification de SmartSteamEmu.ini (SteamIdGeneration, PersonaName, Language)
# TODO : Definissez le chemin du fichier SmartSteamEmu.ini si necessaire,
#        puis decommentez le bloc ci-dessous.
#        Le fichier doit deja exister dans le VHDX - il ne sera pas cree.
#        Champs mis a jour : SteamIdGeneration, PersonaName (-> nom du joueur)
#                            Language (toutes sections -> french)
#        Tout le reste du fichier est conserve.
#        Exemples :
#          $smartSteamEmuIni = Join-Path $VhdxDrive "SmartSteamEmu.ini"
#          $smartSteamEmuIni = Join-Path $VhdxDrive "Crack\SmartSteamEmu.ini"
# =============================================================================

# $smartSteamEmuIni = Join-Path $VhdxDrive "SmartSteamEmu.ini"   # TODO : adapter le chemin
#
# if (Test-Path $smartSteamEmuIni) {
#     try {
#         $content = [System.IO.File]::ReadAllText($smartSteamEmuIni, [System.Text.Encoding]::UTF8)
#         $content = $content -replace '(?m)^SteamIdGeneration\s*=[^\r\n]*', "SteamIdGeneration = $PlayerName"
#         $content = $content -replace '(?m)^PersonaName\s*=[^\r\n]*',       "PersonaName = $PlayerName"
#         $content = $content -replace '(?m)^Language\s*=[^\r\n]*',          "Language = french"
#         [System.IO.File]::WriteAllText($smartSteamEmuIni, $content, [System.Text.Encoding]::UTF8)
#         Write-InstallLog "SmartSteamEmu.ini mis a jour : SteamIdGeneration/PersonaName=$PlayerName, Language=french"
#     } catch {
#         Write-InstallLog "Erreur modification SmartSteamEmu.ini : $_" -Level "ERROR"
#         exit 1
#     }
# } else {
#     Write-InstallLog "SmartSteamEmu.ini introuvable, etape ignoree : $smartSteamEmuIni" -Level "WARNING"
# }

Write-InstallLog "Etape 3d : SmartSteamEmu.ini (desactive - adapter si necessaire)"

# =============================================================================
# ETAPE 3e : Modification de config.ini (champ Name)
# TODO : Definissez le chemin du fichier config.ini si necessaire,
#        puis decommentez le bloc ci-dessous.
#        Le fichier doit deja exister dans le VHDX - il ne sera pas cree.
#        Seule la ligne Name= est modifiee, tout le reste est conserve.
#        Exemples :
#          $configIni = Join-Path $VhdxDrive "config.ini"
#          $configIni = Join-Path $VhdxDrive "Data\config.ini"
#          $configIni = Join-Path $VhdxDrive "settings\config.ini"
# =============================================================================

# $configIni = Join-Path $VhdxDrive "config.ini"   # TODO : adapter le chemin
#
# if (Test-Path $configIni) {
#     try {
#         $content = [System.IO.File]::ReadAllText($configIni, [System.Text.Encoding]::UTF8)
#         $content = $content -replace '(?m)^Name=[^\r\n]*', "Name=$PlayerName"
#         [System.IO.File]::WriteAllText($configIni, $content, [System.Text.Encoding]::UTF8)
#         Write-InstallLog "config.ini mis a jour : Name=$PlayerName"
#     } catch {
#         Write-InstallLog "Erreur modification config.ini : $_" -Level "ERROR"
#         exit 1
#     }
# } else {
#     Write-InstallLog "config.ini introuvable, etape ignoree : $configIni" -Level "WARNING"
# }

Write-InstallLog "Etape 3e : config.ini (desactive - adapter si necessaire)"

# =============================================================================
# ETAPE 3f : Modification de configs.user.ini (account_name et language)
# TODO : Definissez le chemin du fichier configs.user.ini si necessaire,
#        puis decommentez le bloc ci-dessous.
#        Le fichier doit deja exister dans le VHDX - il ne sera pas cree.
#        Seules les lignes account_name= et language= sont modifiees,
#        tout le reste du fichier est conserve.
#        Exemples :
#          $configsUserIni = Join-Path $VhdxDrive "configs.user.ini"
#          $configsUserIni = Join-Path $VhdxDrive "Data\configs.user.ini"
#          $configsUserIni = Join-Path $VhdxDrive "settings\configs.user.ini"
# =============================================================================

# $configsUserIni = Join-Path $VhdxDrive "configs.user.ini"   # TODO : adapter le chemin
#
# if (Test-Path $configsUserIni) {
#     try {
#         $content = [System.IO.File]::ReadAllText($configsUserIni, [System.Text.Encoding]::UTF8)
#         $content = $content -replace '(?m)^account_name=[^\r\n]*', "account_name=$PlayerName"
#         $content = $content -replace '(?m)^language=[^\r\n]*',     "language=french"
#         [System.IO.File]::WriteAllText($configsUserIni, $content, [System.Text.Encoding]::UTF8)
#         Write-InstallLog "configs.user.ini mis a jour : account_name=$PlayerName, language=french"
#     } catch {
#         Write-InstallLog "Erreur modification configs.user.ini : $_" -Level "ERROR"
#         exit 1
#     }
# } else {
#     Write-InstallLog "configs.user.ini introuvable, etape ignoree : $configsUserIni" -Level "WARNING"
# }

Write-InstallLog "Etape 3f : configs.user.ini (desactive - adapter si necessaire)"

# =============================================================================
# ETAPE 3g : Modification de Launcher.bat (champ PLAYER_NAME)
# TODO : Definissez le chemin du fichier Launcher.bat si necessaire,
#        puis decommentez le bloc ci-dessous.
#        Le fichier doit deja exister dans le VHDX - il ne sera pas cree.
#        Seule la ligne SET PLAYER_NAME= ou PLAYER_NAME= est modifiee,
#        tout le reste du fichier est conserve.
#        Exemples :
#          $launcherBat = Join-Path $VhdxDrive "Launcher.bat"
#          $launcherBat = Join-Path $VhdxDrive "Bin\Launcher.bat"
# =============================================================================

# $launcherBat = Join-Path $VhdxDrive "Launcher.bat"   # TODO : adapter le chemin
#
# if (Test-Path $launcherBat) {
#     try {
#         $content = [System.IO.File]::ReadAllText($launcherBat, [System.Text.Encoding]::ASCII)
#         $content = $content -replace '(?m)--name\s+"[^"]*"', "--name `"$PlayerName`""
#         [System.IO.File]::WriteAllText($launcherBat, $content, [System.Text.Encoding]::ASCII)
#         Write-InstallLog "Launcher.bat mis a jour : --name `"$PlayerName`""
#     } catch {
#         Write-InstallLog "Erreur modification Launcher.bat : $_" -Level "ERROR"
#         exit 1
#     }
# } else {
#     Write-InstallLog "Launcher.bat introuvable, etape ignoree : $launcherBat" -Level "WARNING"
# }

Write-InstallLog "Etape 3g : Launcher.bat (desactive - adapter si necessaire)"

# =============================================================================
# ETAPE 3h : Modification universelle (fichier et champ configurable librement)
# TODO : Definissez le chemin du fichier de configuration ET le nom du champ
#        contenant le nom du joueur, puis decommentez le bloc ci-dessous.
#        Le fichier doit deja exister dans le VHDX - il ne sera pas cree.
#        Le champ est cherche en debut de ligne (format "Champ=valeur").
#        Fonctionne avec n'importe quel fichier texte INI/CFG/TXT.
#        Exemples de fichier :
#          $universalFile = Join-Path $VhdxDrive "Data\user.cfg"
#          $universalFile = Join-Path $VhdxDrive "profiles\default.ini"
#          $universalFile = Join-Path $VhdxDrive "settings\player.conf"
#        Exemples de champ nom joueur :
#          $universalField = "PlayerName"
#          $universalField = "Nick"
#          $universalField = "Username"
#          $universalField = "player"
# =============================================================================

# $universalFile  = Join-Path $VhdxDrive "Data\user.cfg"   # TODO : adapter le chemin
# $universalField = "PlayerName"                           # TODO : adapter le nom du champ
#
# if (Test-Path $universalFile) {
#     try {
#         $content = [System.IO.File]::ReadAllText($universalFile, [System.Text.Encoding]::UTF8)
#         $content = $content -replace "(?m)^$([regex]::Escape($universalField))=[^\r\n]*", "$universalField=$PlayerName"
#         [System.IO.File]::WriteAllText($universalFile, $content, [System.Text.Encoding]::UTF8)
#         Write-InstallLog "$universalField mis a jour dans $(Split-Path $universalFile -Leaf) : $PlayerName"
#     } catch {
#         Write-InstallLog "Erreur modification $universalFile : $_" -Level "ERROR"
#         exit 1
#     }
# } else {
#     Write-InstallLog "Fichier introuvable, etape ignoree : $universalFile" -Level "WARNING"
# }

Write-InstallLog "Etape 3h : modification universelle (desactive - adapter si necessaire)"

# =============================================================================
# ETAPE 4 : Copie de fichiers de configuration utilisateur
# TODO : Copier les fichiers de config dans le profil utilisateur si necessaire
# =============================================================================

# Exemple : copier les configs dans AppData
# $configSrc  = Join-Path $VhdxDrive "Config"
# $configDest = Join-Path $env:APPDATA $GameName
# if (Test-Path $configSrc) {
#     Write-InstallLog "Copie des fichiers de configuration..."
#     if (-not (Test-Path $configDest)) { New-Item -ItemType Directory -Path $configDest -Force | Out-Null }
#     Copy-Item -Path "$configSrc\*" -Destination $configDest -Recurse -Force
#     Write-InstallLog "Configuration copiee dans : $configDest"
# }

# Exemple : copier les sauvegardes par defaut dans Documents
# $savesSrc  = Join-Path $VhdxDrive "DefaultSaves"
# $savesDest = Join-Path ([Environment]::GetFolderPath("MyDocuments")) $GameName
# if (Test-Path $savesSrc) {
#     if (-not (Test-Path $savesDest)) { New-Item -ItemType Directory -Path $savesDest -Force | Out-Null }
#     Copy-Item -Path "$savesSrc\*" -Destination $savesDest -Recurse -Force
#     Write-InstallLog "Sauvegardes par defaut copiees"
# }

Write-InstallLog "Etape 4 : fichiers de config utilisateur OK (adapter selon le jeu)"

# =============================================================================
# ETAPE 4b : Lancement du configurateur graphique (FACULTATIF)
# TODO : Renseignez le chemin de l'executable configurateur si le jeu en possede
#        un (choix de la resolution, qualite graphique, etc.), puis decommentez.
#        Le configurateur est lance en mode interactif - l'installation attend
#        sa fermeture avant de continuer. Laissez $configuratorExe vide ou
#        commentez ce bloc pour ignorer cette etape.
#        Exemples :
#          $configuratorExe = Join-Path $VhdxDrive "Config.exe"
#          $configuratorExe = Join-Path $VhdxDrive "Bin\MonJeuConfig.exe"
#          $configuratorExe = Join-Path $VhdxDrive "Tools\setup_video.exe"
# =============================================================================

# $configuratorExe = Join-Path $VhdxDrive "Config.exe"   # TODO : adapter le chemin
#
# if (-not [string]::IsNullOrWhiteSpace($configuratorExe) -and (Test-Path $configuratorExe)) {
#     Write-InstallLog "Lancement du configurateur graphique : $configuratorExe"
#     Write-InstallLog "Configurez la resolution et les parametres graphiques, puis fermez la fenetre."
#     $cfgProc = Start-Process -FilePath $configuratorExe `
#                    -WorkingDirectory (Split-Path $configuratorExe -Parent) `
#                    -Wait -PassThru
#     Write-InstallLog "Configurateur ferme (code: $($cfgProc.ExitCode))"
# } elseif ($configuratorExe -and -not (Test-Path $configuratorExe)) {
#     Write-InstallLog "Configurateur introuvable, etape ignoree : $configuratorExe" -Level "WARNING"
# }

Write-InstallLog "Etape 4b : configurateur graphique (desactive - adapter si necessaire)"

# =============================================================================
# ETAPE 5 : Actions personnalisees
# TODO : Toute autre action specifique au jeu
# =============================================================================

# Exemple : creer un raccourci sur le Bureau
# $shell       = New-Object -ComObject WScript.Shell
# $shortcut    = $shell.CreateShortcut("$env:USERPROFILE\Desktop\$GameName.lnk")
# $shortcut.TargetPath      = "$VhdxDrive\game.exe"
# $shortcut.WorkingDirectory = "$VhdxDrive\"
# $shortcut.IconLocation    = "$VhdxDrive\game.ico"
# $shortcut.Save()
# Write-InstallLog "Raccourci Bureau cree"

# Exemple : executer un fichier .bat present sur le VHDX
# TODO : Remplacez "setup.bat" par le nom reel du fichier batch a executer
# $batFile = Join-Path $VhdxDrive "setup.bat"
# if (Test-Path $batFile) {
#     Write-InstallLog "Execution de $batFile..."
#     $batProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batFile`"" `
#                    -WorkingDirectory (Split-Path $batFile -Parent) -Wait -PassThru
#     if ($batProc.ExitCode -ne 0) {
#         Write-InstallLog "Le fichier batch a termine avec le code : $($batProc.ExitCode)" -Level "WARNING"
#     } else {
#         Write-InstallLog "Fichier batch execute avec succes"
#     }
# } else {
#     Write-InstallLog "Fichier batch introuvable, etape ignoree : $batFile" -Level "WARNING"
# }

Write-InstallLog "Etape 5 : actions personnalisees OK"

# =============================================================================
# ETAPE 6 OBLIGATOIRE : Creer le fichier XML de metadata du jeu
# NE PAS MODIFIER le nom du fichier ni la structure XML.
# Remplissez LaunchCommand avec le chemin reel de l'executable sur le VHDX.
# ServerCommand est FACULTATIF : laissez vide si le jeu n'a pas de serveur dedie.
# =============================================================================

# TODO : Remplacez "U:\game.exe" par le chemin reel de l'executable client
#        Exemples :
#          U:\game.exe
#          U:\Bin\MonJeu.exe
#          "U:\Mon Jeu\jeu.exe" -fullscreen

# TODO : Remplissez ServerCommand si le jeu possede un serveur dedie,
#        sinon laissez la valeur vide.
#        Exemples :
#          U:\server.exe
#          U:\Bin\MonJeuServer.exe -port 27015
#          "U:\Mon Jeu\server.exe" -dedicated
$serverCommand = ""   # laisser vide si pas de serveur

$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<GameInfo>
  <GameName>$GameName</GameName>
  <LaunchCommand>U:\game.exe</LaunchCommand>
  <ServerCommand>$serverCommand</ServerCommand>
  <Version>1.0</Version>
  <InstalledDate>$(Get-Date -Format "yyyy-MM-dd")</InstalledDate>
  <Description>Description du jeu ici</Description>
</GameInfo>
"@

$xmlPath = Join-Path $GameFolder "$GameName.xml"

try {
    [System.IO.File]::WriteAllText($xmlPath, $xmlContent, [System.Text.Encoding]::UTF8)
    Write-InstallLog "Fichier XML cree : $xmlPath"
} catch {
    Write-InstallLog "ERREUR : Impossible de creer le fichier XML : $_" -Level "ERROR"
    exit 1
}

# =============================================================================
# FIN DE L'INSTALLATION
# =============================================================================

Write-InstallLog "=== Installation de '$GameName' terminee avec succes ! ==="
Write-InstallLog "Le jeu sera lance via la commande definie dans : $xmlPath"
exit 0
