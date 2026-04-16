# GameSwap — Documentation complète

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Prérequis système](#prérequis-système)
3. [Architecture et structure des fichiers](#architecture-et-structure-des-fichiers)
4. [Flux de démarrage](#flux-de-démarrage)
5. [Modules — rôle et fonctions](#modules--rôle-et-fonctions)
6. [Format des fichiers de données](#format-des-fichiers-de-données)
7. [Partage SMB et compte de service](#partage-smb-et-compte-de-service)
8. [File de téléchargement](#file-de-téléchargement)
9. [Interface utilisateur — onglets](#interface-utilisateur--onglets)
10. [Préparer un jeu pour GameSwap](#préparer-un-jeu-pour-gameswap)
11. [Support NAS](#support-nas)
12. [Désinstallation](#désinstallation)
13. [Conventions de code](#conventions-de-code)
14. [Historique des décisions de conception](#historique-des-décisions-de-conception)

---

## Vue d'ensemble

GameSwap est une application **PowerShell 5.1 + WPF** qui permet à plusieurs joueurs d'un réseau local Windows de partager des jeux pré-installés sous forme de fichiers **VHDX** (disques virtuels). Un joueur expose son dossier de jeux via un partage SMB ; les autres joueurs scannent le réseau, voient la bibliothèque disponible, téléchargent les VHDX qui les intéressent, et les lancent directement depuis leur machine.

**Principe de fonctionnement résumé :**

```
[Hôte]                          [Client]
Dossier GameSwap/               Scanner le réseau
  └── Jeux/                     → Trouve le partage SMB "GameSwap"
       └── MonJeu/              → Voir la liste des jeux disponibles
            └── MonJeu.vhdx     → Télécharger MonJeu.vhdx
                MonJeu.xml      → Installer (exécute install.ps1 du VHDX)
                MonJeu_info.xml → Jouer (monte le VHDX sur U:, lance exe)
                MonJeu.jpg
```

---

## Prérequis système

| Élément | Requis |
|---|---|
| Windows 10/11 | Oui |
| PowerShell 5.1+ | Oui |
| Droits administrateur | Oui (partage SMB, montage VHDX, compte local) |
| Hyper-V / Disques virtuels (`Mount-DiskImage`) | Oui |
| nmap | Oui (installé automatiquement via winget au premier lancement) |
| .NET Framework 4.x (WPF) | Inclus dans Windows |

---

## Architecture et structure des fichiers

```
GameSwap/
├── GameSwap.ps1              Point d'entrée principal
├── Start-GameSwap.bat        Lanceur (élève les droits admin, console se ferme à la sortie)
├── Uninstall.ps1             Désinstallation complète
├── Uninstall.bat             Lanceur de désinstallation (élève les droits)
├── GAMESWAP.md               Documentation technique complète
├── README.md                 Présentation GitHub
├── GameSwap_Guide.html       Guide utilisateur (imprimable en PDF)
│
├── Modules/
│   ├── GS-Log.psm1           Journalisation
│   ├── GS-Init.psm1          Vérifications, settings, assistant premier lancement
│   ├── GS-Account.psm1       Compte local Windows "GameSwap"
│   ├── GS-Share.psm1         Partage SMB + file de téléchargement
│   ├── GS-Network.psm1       Scan réseau (nmap) + connexion aux partages distants
│   ├── GS-VHDX.psm1          Montage/démontage des fichiers VHDX (lettre U:)
│   ├── GS-Games.psm1         Gestion des jeux locaux (liste, install, lancement)
│   └── GS-UI.psm1            Interface WPF complète (XAML + handlers)
│
├── Templates/
│   ├── install.ps1           Template d'installation à placer dans chaque VHDX
│   ├── gameinfo.xml          Template du fichier de métadonnées visuelles
│   └── gameswap_user.json    Template d'identification pour NAS
│
└── logs/
    └── GameSwap_YYYYMMDD.log Logs journaliers
```

**Données persistantes (hors dossier d'installation) :**

```
%APPDATA%\GameSwap\
└── settings.json             Paramètres du joueur local
```

**Structure du dossier GameSwap choisi par l'utilisateur :**

```
[GameSwapFolder]/             Ex : D:\GameSwap
├── Jeux/
│   ├── MonJeu/
│   │   ├── MonJeu.vhdx       Disque virtuel du jeu (seul fichier obligatoire)
│   │   ├── MonJeu.xml        Créé à l'installation (LaunchCommand, ServerCommand...)
│   │   ├── MonJeu_info.xml   Métadonnées visuelles (Trailer, MaxPlayers, vignette...)
│   │   └── MonJeu.jpg        Vignette portrait (PNG ou JPG, recommandé 300×400px)
│   └── AutreJeu/
│       └── ...
├── gameswap_info.json        Identification de l'hôte (PlayerName, ShareName)
├── gameswap_user.json        Identification NAS (PlayerName uniquement)
└── download_queue.json       File de téléchargement (gérée par GS-Share)
```

---

## Flux de démarrage

```
Start-GameSwap.bat
  └── Élève les droits admin
      └── GameSwap.ps1
            1. Charge les 8 modules dans l'ordre
            2. Initialise les logs (logs/GameSwap_YYYYMMDD.log)
            3. Vérifie les droits admin → erreur bloquante sinon
            4. Vérifie Mount-DiskImage → erreur bloquante sinon
            5. Charge settings.json (%APPDATA%\GameSwap\settings.json)
            
            [Premier lancement]
            6a. Show-GSWizard → assistant de configuration (PlayerName, GameSwapFolder)
            6b. Crée le dossier GameSwapFolder
            6c. New-GSLocalAccount → crée l'utilisateur Windows "GameSwap"
            6d. New-GSShare → crée le partage SMB "GameSwap" sur GameSwapFolder
            6e. Set-GSQueueMaxSlots → écrit maxSlots dans download_queue.json
            6f. Install-NmapIfNeeded → installe nmap via winget si absent
            6g. Sauvegarde settings.json
            
            [Lancement normal]
            6a. Vérifie si le lecteur U: est déjà monté → tente de démonter (VHDX résiduel)
                → si démontage impossible : MessageBox d'avertissement (non bloquant)
            6b. Vérifie que le partage SMB "GameSwap" existe → le recrée si absent
            6c. Set-GSQueueMaxSlots → s'assure que maxSlots est publié
            6d. Install-NmapIfNeeded
            
            7. Show-GSMainWindow → boucle WPF (interface principale)
```

---

## Modules — rôle et fonctions

### GS-Log.psm1
Journalisation dans `logs/GameSwap_YYYYMMDD.log`.

| Fonction | Rôle |
|---|---|
| `Initialize-GSLog -LogDir` | Crée le dossier logs, ouvre le fichier du jour |
| `Write-GSLog -Message -Level` | Écrit une ligne horodatée. Niveaux : `INFO`, `WARNING`, `ERROR`, `DEBUG` |

---

### GS-Init.psm1
Vérifications système et gestion des paramètres.

| Fonction | Rôle |
|---|---|
| `Test-AdminRights` | Retourne `$true` si le process tourne en admin |
| `Test-MountDiskImage` | Vérifie la disponibilité de `Mount-DiskImage` |
| `Get-GSSettings` | Lit `settings.json`, applique les migrations de champs manquants |
| `Save-GSSettings -Settings` | Sauvegarde `settings.json` |
| `Install-NmapIfNeeded` | Installe nmap via `winget` si introuvable dans le PATH |
| `Get-AppDataPath` | Retourne `%APPDATA%\GameSwap` |

**Structure de `settings.json` :**
```json
{
  "Initialized": true,
  "PlayerName": "NomDuJoueur",
  "GameSwapFolder": "D:\\GameSwap",
  "ShareName": "GameSwap",
  "SelectedAdapterIP": "192.168.1.10",
  "MaxDownloadSlots": 3
}
```

---

### GS-Account.psm1
Gestion du compte local Windows utilisé pour authentifier les connexions SMB entrantes.

| Fonction | Rôle |
|---|---|
| `Test-GSLocalAccount` | Vérifie si le compte "GameSwap" existe |
| `New-GSLocalAccount` | Crée le compte local "GameSwap" (mot de passe fixe, jamais expirant) |
| `Get-GSAccountName` | Retourne `"GameSwap"` |
| `Get-GSAccountPassword` | Retourne `"Edams-Bourbe0"` |

> **Note :** Ce compte est utilisé uniquement pour les connexions SMB locales sur le réseau LAN. Il n'a pas de droits supplémentaires sur le système.

---

### GS-Share.psm1
Création/suppression du partage SMB et gestion de la file de téléchargement.

| Fonction | Rôle |
|---|---|
| `Test-GSShare` | Vérifie si le partage "GameSwap" existe |
| `New-GSShare -FolderPath -PlayerName` | Crée le partage SMB avec permission CHANGE (lecture+écriture) pour le compte GameSwap, crée le sous-dossier `Jeux/`, configure les permissions NTFS Modify, écrit `gameswap_info.json` |
| `Remove-GSShare` | Supprime le partage SMB |
| `Save-GSShareInfo -FolderPath -PlayerName` | Écrit `gameswap_info.json` à la racine du dossier |
| `Get-GSShareName` | Retourne `"GameSwap"` |
| `Set-GSQueueMaxSlots -ShareRootPath -MaxSlots` | **Hôte uniquement.** Écrit/met à jour `maxSlots` dans `download_queue.json` |
| `Add-GSDownloadSlot -ShareRootPath -PlayerName -GameName` | Ajoute un slot (retourne `{ Success, Blockers }`). Lit `maxSlots` depuis le fichier |
| `Remove-GSDownloadSlot -ShareRootPath -PlayerName -GameName` | Retire le slot d'un joueur |
| `Get-GSDownloadQueue -ShareRootPath` | Retourne les slots actifs (purge les expirés > 30 min) |
| `Clear-GSDownloadSlot -ShareRootPath -SlotIndex` | Libère manuellement un slot par index |
| `Read-GSQueueInfo -QueueFile` | Retourne `{ maxSlots, slots[] }` depuis le fichier JSON |

---

### GS-Network.psm1
Découverte réseau via nmap et connexion aux partages distants.

| Fonction | Rôle |
|---|---|
| `Get-AllNetworkAdapters` | Liste les adaptateurs réseau IPv4 valides (hors loopback/APIPA) |
| `Get-LocalIPInfo -SelectedIP` | Retourne l'adaptateur sélectionné ou le premier disponible |
| `Find-GSSharesOnNetwork -Subnet` | Scan nmap du sous-réseau (port 445), puis vérifie chaque hôte avec `Connect-GSShare` |
| `Connect-GSShare -HostIP` | Tente une connexion au partage `\\IP\GameSwap` (d'abord avec identifiants GameSwap, puis anonyme pour NAS). Lit `gameswap_info.json`, puis `gameswap_user.json` si PlayerName absent |
| `Get-RemoteGameList -HostIP` | Connexion au partage distant, liste les dossiers `Jeux/`, retourne les objets jeux avec métadonnées |

---

### GS-VHDX.psm1
Montage et démontage des fichiers VHDX. **Toujours monté sur la lettre `U:`.**

| Fonction | Rôle |
|---|---|
| `Mount-GSVhdx -VhdxPath` | Monte le VHDX sur `U:`. Arrête ShellHWDetection pour éviter l'autoplay. Démonte d'abord ce qui est sur U: |
| `Dismount-GSVhdx` | Démonte le VHDX actuellement suivi par `$script:MountedVhdxPath`. Fallback : retrouve le chemin via `$disk.Location` si la variable est vide |
| `Dismount-GSVhdxByPath -VhdxPath` | Démonte un VHDX spécifique par chemin |
| `Get-MountedGSVhdxPath` | Retourne le chemin du VHDX actuellement monté |
| `Get-DriveLetter` | Retourne `"U"` |

> **Note :** La fonction interne `Get-MountedGSVhdxPathByDrive` utilise `(Get-Disk -Number N).Location` pour retrouver le chemin du VHDX monté sur U: sans appeler `Get-DiskImage` (qui demanderait `-ImagePath` interactivement si omis).

---

### GS-Games.psm1
Gestion des jeux installés localement et téléchargement depuis un hôte distant.

| Fonction | Rôle |
|---|---|
| `Get-LocalGames -GamesFolder` | Parcourt `Jeux/`, retourne les objets jeux avec `IsInstalled`, `SizeMB`, `GameInfo`, `ExtraInfo`, `ThumbPath` |
| `Get-GSGameInfo -XmlPath` | Lit `[GameName].xml` (LaunchCommand, ServerCommand, Version...) |
| `Get-GSGameExtraInfo -XmlPath` | Lit `[GameName]_info.xml` (DisplayName, ReleaseYear, Trailer, MaxPlayers, Thumbnail, Description, Instructions) |
| `Install-GSGame -VhdxPath -GameFolder -GameName` | Monte le VHDX, exécute `install.ps1` (présent à la racine du VHDX), démonte |
| `Start-GSGame -Game` | Monte le VHDX, lance la commande `LaunchCommand` via `cmd.exe` |
| `Start-GSServer -Game` | Monte le VHDX, lance `ServerCommand` via `cmd.exe` |
| `Copy-RemoteGame -RemoteVhdxPath -LocalGamesFolder -GameName -HostIP -PlayerName -ShareRootPath -OnProgress -OnComplete -OnError` | Téléchargement dans un Runspace séparé (non bloquant). Copie aussi `_info.xml` et vignette. Libère le slot dans le `finally` |

---

### GS-UI.psm1
Interface WPF complète définie en XAML inline. **Point d'entrée : `Show-GSMainWindow -Settings -ScriptDir`.**

Contient aussi l'assistant de premier lancement (`Show-GSWizard`).

L'interface comporte 4 onglets :

| Onglet | Contenu |
|---|---|
| **Mes Jeux** | Liste des jeux locaux (DataGrid), boutons Installer/Jouer/Serveur/Désinstaller/Supprimer, panneau de détails à droite (vignette, année de sortie, joueurs max, trailer, description, instructions) |
| **Réseau** | Scan réseau, liste des joueurs, liste des jeux disponibles, téléchargement avec barre de progression, file d'attente automatique, panneau de détails à droite (vignette, année, joueurs max, description, trailer) |
| **Paramétrage** | Nom du joueur, dossier GameSwap (avec déplacement), nombre de téléchargements simultanés, redistribuables système (VC++ toutes versions + DirectX June 2010), liste des téléchargements actifs avec libération manuelle |

---

## Format des fichiers de données

### `gameswap_info.json` — Identification de l'hôte
Créé automatiquement par `New-GSShare`. Placé à la racine du `GameSwapFolder`.
```json
{
  "PlayerName": "NomDuJoueur",
  "Version": "1.0",
  "ShareName": "GameSwap"
}
```

### `gameswap_user.json` — Configuration NAS
À créer manuellement sur un NAS. Placé à la racine du dossier partagé.
```json
{
  "PlayerName": "NomDuJoueur",
  "MaxDownloadSlots": 3
}
```
- `PlayerName` : nom affiché dans la liste des joueurs du réseau
- `MaxDownloadSlots` : limite de téléchargements simultanés depuis ce NAS (remplace `maxSlots` dans `download_queue.json` si ce fichier n'existe pas encore)

### `download_queue.json` — File de téléchargement
Géré par `GS-Share.psm1`. Placé à la racine du `GameSwapFolder`. **Seul l'hôte écrit `maxSlots`.** Les clients écrivent/suppriment uniquement leurs propres slots.
```json
{
  "maxSlots": 3,
  "slots": [
    {
      "PlayerName": "Alice",
      "GameName": "Diablo2",
      "StartedAt": "2026-04-08 14:30:00"
    },
    {
      "PlayerName": "Bob",
      "GameName": "Diablo2",
      "StartedAt": "2026-04-08 14:31:15"
    }
  ]
}
```
- Les slots plus anciens que 30 minutes sont automatiquement purgés.
- `maxSlots` est publié par l'hôte lors de la création du partage et à chaque modification dans Paramétrage.

### `[GameName].xml` — Métadonnées d'installation
Créé par `install.ps1` lors de l'installation. Sa présence signifie que le jeu est installé.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<GameInfo>
  <GameName>MonJeu</GameName>
  <LaunchCommand>U:\game.exe</LaunchCommand>
  <ServerCommand>U:\server.exe -port 27015</ServerCommand>
  <Version>1.0</Version>
  <InstalledDate>2026-04-08</InstalledDate>
  <Description>Description du jeu</Description>
</GameInfo>
```

### `[GameName]_info.xml` — Métadonnées visuelles
Fichier optionnel, créé manuellement par l'administrateur du VHDX. Visible avant téléchargement depuis l'onglet Réseau.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<GameExtraInfo>
  <DisplayName>Nom Complet Du Jeu</DisplayName>
  <ReleaseYear>2004</ReleaseYear>
  <Trailer>https://www.youtube.com/watch?v=...</Trailer>
  <MaxPlayers>8</MaxPlayers>
  <Thumbnail>MonJeu.jpg</Thumbnail>
  <Description>Courte description visible avant téléchargement.</Description>
  <Instructions>Instructions visibles dans l'onglet Mes Jeux après installation.</Instructions>
</GameExtraInfo>
```
- `DisplayName` : nom complet avec espaces, affiché dans les DataGrids (fallback sur le nom du dossier si absent)
- `ReleaseYear` : année de sortie, affichée dans le panneau de détails des deux onglets

### Vignette (`[GameName].png` ou `[GameName].jpg`)
- Formats acceptés : PNG ou JPG uniquement (WebP non supporté par .NET Framework natif)
- Dimensions recommandées : **300×400 px** (ratio portrait 3:4)
- Dimensions maximales : 600×900 px
- Taille fichier maximum : 300 Ko
- Placée dans le même dossier que le VHDX

---

## Partage SMB et compte de service

### Compte Windows "GameSwap"
- Créé automatiquement au premier lancement
- Mot de passe : `Edams-Bourbe0` (fixe, jamais expirant)
- Rôle : authentification SMB pour les connexions entrantes depuis les clients
- N'a pas de droits admin

### Partage SMB "GameSwap"
- Créé sur `[GameSwapFolder]` (ex : `D:\GameSwap`)
- Permission SMB : `CHANGE` (lecture + écriture) pour le compte GameSwap
- Permission NTFS : `Modify` (hérité sur sous-dossiers et fichiers)
- L'écriture est nécessaire pour que les clients puissent mettre à jour `download_queue.json`

### Connexion client
Les clients se connectent via :
```
net use \\IP\GameSwap /USER:GameSwap Edams-Bourbe0 /PERSISTENT:NO
```
La connexion est établie ponctuellement puis supprimée immédiatement après usage.

---

## File de téléchargement

### Principe
`download_queue.json` est un **sémaphore basé sur fichier** stocké sur le partage de l'hôte. Il limite le nombre de téléchargements simultanés depuis un même hôte.

### Cycle de vie d'un téléchargement (côté client)
1. Connexion au partage de l'hôte
2. Lecture de `download_queue.json` via `Read-GSQueueInfo` → obtenir `maxSlots` et `slots`
3. Appel de `Add-GSDownloadSlot` → ajoute le slot si `slots.Count < maxSlots`
4. Si succès : démarrage immédiat de `Copy-RemoteGame` (Runspace séparé)
5. Si plein : proposition de mise en file d'attente → `DispatcherTimer` à 30 secondes qui relit le fichier et tente d'acquérir un slot dès qu'un se libère
6. Fin de téléchargement (succès ou erreur) → suppression du slot dans le `finally` du Runspace

### Annulation d'un téléchargement
- Le bouton "■ Stopper" arrête le Runspace, supprime le fichier VHDX partiel et libère manuellement le slot (le `finally` du Runspace arrêté ne s'exécute pas).

### Gestion des slots expirés
Un slot sans activité depuis plus de 30 minutes est automatiquement ignoré. La purge se fait lors de chaque lecture de la file.

---

## Interface utilisateur — onglets

### Onglet Mes Jeux
- **DataGrid** : liste tous les sous-dossiers de `Jeux/` contenant un `.vhdx`
  - Colonnes : Nom du jeu, Taille, Joueurs max, Statut (Installé / Non installé)
- **Panneau de détails** (colonne droite, toujours visible) :
  - Vignette, Joueurs max, bouton Trailer, Description, Instructions
- **Boutons** (actifs selon l'état du jeu sélectionné) :
  - **Installer** : monte le VHDX, exécute `install.ps1`, démonte
  - **Jouer** : monte le VHDX sur U:, lance `LaunchCommand`
  - **Serveur** (visible si `ServerCommand` non vide) : toggle Démarrer/Arrêter serveur. Le VHDX reste monté tant que le serveur est actif
  - **Désinstaller** : supprime uniquement `[GameName].xml` (le VHDX est conservé)
  - **Supprimer** : supprime le dossier complet du jeu (VHDX + tous fichiers)

> **Comportement VHDX :** Le VHDX est démonté automatiquement quand le processus du jeu se ferme, **sauf** si le serveur est en cours d'exécution (`$script:ServerRunning = $true`).

### Onglet Réseau
- **Barre de scan** : bouton "Scanner le réseau" (toggle, re-clic annule le scan en cours)
  - Utilise nmap pour trouver les hôtes avec le port 445 ouvert sur le sous-réseau
  - Filtre l'IP locale pour ne pas s'afficher soi-même
- **Colonne gauche** : liste des joueurs trouvés (PlayerName + IP)
- **Colonne centrale** : jeux disponibles chez le joueur sélectionné
- **Colonne droite** : détails du jeu sélectionné (vignette, max joueurs, description, trailer)
- **Boutons bas** :
  - **↓ Télécharger ce jeu** : vérifie les slots, télécharge ou propose la file d'attente
  - **■ Stopper** : annule le téléchargement en cours
  - **Annuler l'attente** : annule la file d'attente automatique
- **Sélection de la carte réseau** (liste déroulante) : permet de choisir l'interface réseau pour le scan

### Onglet Paramétrage
- **Nom du joueur** : modifiable + Appliquer
- **Dossier GameSwap** : modifiable + parcourir + Appliquer (propose de déplacer les fichiers existants, recrée le partage SMB)
- **Téléchargements simultanés** : compteur +/- (1 à 10) + Appliquer (publie `maxSlots` dans `download_queue.json`)
- **Redistribuables système** :
  - **Visual C++ (toutes versions)** : installe les VC++ 2005 à 2022 (x86 + x64) via `winget` dans une console visible
  - **DirectX June 2010** : télécharge `dxwebsetup.exe` depuis Microsoft et l'installe en mode silencieux (`/Q`) pour éviter la proposition de la barre Bing
- **Téléchargements actifs** : DataGrid des slots actifs + bouton Actualiser + bouton Libérer (libération manuelle d'urgence)

---

## Préparer un jeu pour GameSwap

### Structure d'un VHDX GameSwap
```
[Racine du VHDX U:\]
├── install.ps1          OBLIGATOIRE — exécuté à l'installation
├── game.exe             Exécutable principal du jeu
├── server.exe           (optionnel) Serveur dédié
└── ...                  Fichiers du jeu
```

### Template `install.ps1`
Le fichier `Templates/install.ps1` est le point de départ pour créer l'installeur d'un jeu. Il reçoit automatiquement :
- `$GameFolder` : chemin local de destination (`[GameSwapFolder]\Jeux\[GameName]`)
- `$GameName` : nom du jeu
- `$PlayerName` : nom du joueur lu depuis `settings.json`
- `$VhdxDrive` : lettre du VHDX monté (`U:`)

**Étapes du template :**

| Étape | Fichier cible | Champ modifié | Obligatoire |
|---|---|---|---|
| 1 | — | Prérequis (vcredist, DirectX...) | Non |
| 2 | Registre Windows | Clés d'installation | Non |
| 3 | `settings/account_name.txt` | Nom du joueur | Non |
| 3b | `steam_settings/force_account_name.txt` | Nom du joueur (Goldberg) | Non |
| 3c | `steam_emu.ini` | `UserName=`, `Language=` | Non |
| 3d | `SmartSteamEmu.ini` | `SteamIdGeneration`, `PersonaName`, `Language` | Non |
| 3e | `config.ini` | `Name=` | Non |
| 3f | `configs.user.ini` | `account_name=`, `language=` | Non |
| 3g | `Launcher.bat` | `--name "NomJoueur"` | Non |
| 3h | Tout fichier texte (INI/CFG/TXT) | Champ libre (`$universalFile` + `$universalField`) | Non |
| 4 | AppData / Documents | Fichiers de config utilisateur | Non |
| 4b | — | Lancement du configurateur graphique (résolution, qualité) | Non |
| 5 | — | Actions personnalisées | Non |
| **6** | `[GameName].xml` | **LaunchCommand, ServerCommand** | **OUI** |

> L'étape 6 est la seule obligatoire. Elle crée `[GameName].xml` dans `$GameFolder`, ce qui marque le jeu comme installé.

> **Important :** Toutes les regex utilisées dans le template utilisent `[^\r\n]*` (et non `.*`) pour préserver les fins de ligne CRLF des fichiers INI/BAT Windows.

### Fichier `[GameName]_info.xml`
À créer manuellement dans le même dossier que le VHDX (avant ou après téléchargement). Il est copié automatiquement lors du téléchargement.

---

## Support NAS

GameSwap prend en charge les partages hébergés sur un NAS. Le NAS utilise **exactement le même compte** que les PC (`GameSwap` / `Edams-Bourbe0`).

### Configuration du NAS

1. **Créer un utilisateur** `GameSwap` avec le mot de passe `Edams-Bourbe0` sur le NAS
2. **Créer un dossier partagé** nommé `GameSwap` avec les sous-dossiers :
   ```
   GameSwap/
   ├── Jeux/
   │    └── [dossiers de jeux...]
   └── gameswap_user.json    ← créer ce fichier manuellement
   ```
3. **Donner les droits en lecture/écriture** à l'utilisateur `GameSwap` sur ce dossier partagé (nécessaire pour que les clients puissent gérer `download_queue.json`)
4. **Créer `gameswap_user.json`** à la racine du partage :
   ```json
   {
     "PlayerName": "NomDuNAS",
     "MaxDownloadSlots": 3
   }
   ```

### Détection automatique
`Connect-GSShare` tente toujours la connexion avec les identifiants GameSwap. La distinction PC / NAS se fait sur les fichiers présents :
- `gameswap_info.json` présent → **PC** (créé automatiquement par GameSwap)
- `gameswap_user.json` présent → **NAS** (créé manuellement par l'admin)
- Ni l'un ni l'autre → partage ignoré

### Gestion du `maxSlots` sur NAS
Le NAS ne fait pas tourner GameSwap, donc `maxSlots` ne peut pas être publié automatiquement. La priorité est :
1. `maxSlots` dans `download_queue.json` s'il existe déjà (créé par le premier client)
2. `MaxDownloadSlots` dans `gameswap_user.json` (valeur configurée par l'admin NAS)
3. Valeur par défaut du module (3)

Le premier client à télécharger depuis le NAS crée `download_queue.json` en lisant `MaxDownloadSlots` depuis `gameswap_user.json`, puis cette valeur est préservée à chaque réécriture.

---

## Désinstallation

Lancer `Uninstall.bat` (droits admin requis). Les étapes :

1. Suppression du partage SMB "GameSwap"
2. Suppression du compte local Windows "GameSwap"
3. Suppression du dossier `%APPDATA%\GameSwap` (settings, etc.)
4. Désinstallation de nmap via `winget uninstall --id Insecure.Nmap`
5. Proposition de supprimer le dossier des jeux (avec démontage du VHDX si nécessaire)

---

## Conventions de code

| Convention | Valeur |
|---|---|
| Encodage des fichiers | UTF-8 BOM |
| Fins de ligne | CRLF |
| PowerShell minimum | 5.1 |
| Lettre de montage VHDX | `U:` (fixe) |
| Nom du partage SMB | `GameSwap` (fixe) |
| Nom du compte service | `GameSwap` |
| Mot de passe du compte service | `Edams-Bourbe0` |
| Variables de portée dans les closures WPF | Préfixe `$script:` pour les DispatcherTimer |
| Caractères Unicode dans les strings PS | `[char]0xNNNN` (BMP uniquement, ≤ U+FFFF) |
| Caractères Unicode dans le XAML | `&#xNNNN;` |
| Regex sur fichiers INI/BAT | `[^\r\n]*` pour préserver CRLF |
| ItemsSource WPF | Toujours wrappé dans `[object[]]@(...)` |

### Architecture des Runspaces
Le téléchargement (`Copy-RemoteGame`) s'exécute dans un Runspace STA séparé pour ne pas bloquer l'UI WPF. Les variables sont passées via `SessionStateProxy.SetVariable()`. La communication UI ↔ Runspace se fait via un `[hashtable]::Synchronized`.

### DispatcherTimer
Tous les timers WPF (`$script:DlTimer`, `$script:QueueTimer`, `$script:ScanTimer`, `$script:ListTimer`) sont stockés avec le préfixe `$script:` pour être accessibles depuis les closures des handlers d'événements.

---

## Historique des décisions de conception

Cette section consigne toutes les instructions et décisions prises au fil du développement.

### Fonctionnement général
- Les jeux sont distribués sous forme de fichiers VHDX (disques virtuels Windows), montés à la demande sur la lettre `U:`.
- L'installation d'un jeu exécute `install.ps1` depuis le VHDX — ce script configure le nom du joueur dans les fichiers de config du jeu.
- Un jeu est considéré comme "installé" uniquement si `[GameName].xml` existe dans son dossier local.
- "Désinstaller" supprime uniquement le fichier XML (le VHDX reste intact et peut être réinstallé).

### Bouton Serveur
- Le bouton Serveur est un toggle Démarrer/Arrêter, pas lié à l'état du processus `cmd.exe`.
- `$script:ServerRunning` est le seul indicateur d'état (booléen).
- Quand le serveur est actif, le VHDX **ne doit pas** être démonté même si le jeu client se ferme.
- Le VHDX est monté lors du démarrage du serveur et démonté lors de l'arrêt.

### Gestion du VHDX à la fermeture
- Si le bouton Serveur est dans l'état "Arrêter serveur" à la fermeture de l'application, le VHDX est démonté.
- Vérification dans le timer de surveillance du processus : `if ($script:GameVhdxPath -and -not $script:ServerRunning)`.

### Identification visuelle des jeux
- Chaque jeu peut avoir un fichier `[GameName]_info.xml` distinct du `[GameName].xml` (métadonnées d'installation).
- Le fichier `_info.xml` est lu aussi bien en local (onglet Mes Jeux) que sur le réseau avant téléchargement (onglet Réseau).
- Lors d'un téléchargement, `Copy-RemoteGame` copie aussi `_info.xml` et la vignette PNG/JPG.

### Vignette
- Format portrait 3:4, recommandé 300×400 px, max 600×900 px, max 300 Ko.
- Formats PNG et JPG uniquement (WebP non supporté nativement par .NET Framework).
- Nommée `[GameName].png` ou `[GameName].jpg`, dans le même dossier que le VHDX.

### Onglet Réseau — mise en page
- Le panneau de détails du jeu est dans une colonne fixe à droite (toujours visible), pas en dessous de la liste.
- La mise en page utilise 5 colonnes : `260px joueurs | 12 spacer | * jeux | 12 spacer | 230px détails`.

### File de téléchargement (download_queue.json)
- Limite configurable par l'hôte (défaut : 3 téléchargements simultanés).
- `maxSlots` est écrit **uniquement par l'hôte** (lors de la création du partage et depuis l'onglet Paramétrage). Les clients ne modifient jamais `maxSlots`.
- Les clients lisent `maxSlots` depuis le fichier pour afficher "X/Y slots utilisés".
- Timeout automatique des slots : 30 minutes.
- Quand les slots sont pleins, le client peut se mettre en file d'attente : un `DispatcherTimer` (30 secondes) relit le fichier et démarre automatiquement le téléchargement dès qu'un slot se libère.

### Emplacements des fichiers de settings
- `settings.json` est dans `%APPDATA%\GameSwap\` (par utilisateur Windows), pas dans le dossier de l'application.
- Le dossier de l'application lui-même (`[GameSwapFolder]`) est choisi par l'utilisateur à la configuration initiale.

### Template install.ps1
- Les étapes 3 à 3g sont toutes optionnelles (commentées par défaut).
- Le dossier Settings n'est pas toujours à la même place selon les jeux — le chemin est à définir par l'administrateur du VHDX.
- Les regex doivent utiliser `[^\r\n]*` pour ne pas consommer les `\r` des fins de ligne CRLF.
- L'approche pour `Launcher.bat` : chercher et remplacer `--name "AncienNom"` (pas `SET PLAYER_NAME=`).
- `Launcher.bat` est lu/écrit en ASCII (pas UTF-8) pour compatibilité avec les fichiers BAT Windows.

### Scan réseau
- nmap est installé automatiquement via `winget install --id Insecure.Nmap` si absent.
- Le bouton Scanner est un toggle : re-cliquer pendant un scan l'annule.
- Le scan filtre l'IP locale pour qu'un hôte ne se voie pas lui-même dans la liste.

### Support NAS
- Le NAS utilise **le même compte GameSwap** (`GameSwap` / `Edams-Bourbe0`) que les PC — pas de connexion anonyme.
- Identification via `gameswap_user.json` si `gameswap_info.json` absent ou sans PlayerName.
- `gameswap_user.json` contient `PlayerName` et `MaxDownloadSlots` (configure la limite de téléchargements du NAS).
- Un partage sans PlayerName identifiable est ignoré.
- `maxSlots` dans `download_queue.json` est initialisé depuis `MaxDownloadSlots` de `gameswap_user.json` lors de la première écriture du fichier par un client.

### Désinstallation
- `Uninstall.ps1` supprime le partage SMB, le compte Windows, les settings AppData et nmap.
- Propose séparément de supprimer le dossier des jeux (avec démontage préalable des VHDX).

### Vérification du lecteur U: au démarrage
- Au démarrage normal, GameSwap vérifie si `U:\` est déjà accessible (VHDX résiduel d'un crash précédent).
- Si oui : tentative de démontage via `Dismount-GSVhdx` (utilise `$disk.Location` pour retrouver le chemin).
- Si le démontage échoue : MessageBox d'avertissement non bloquant — l'application continue.

### Fermeture de la console PowerShell
- `Start-GameSwap.bat` relance `powershell.exe` directement en élevé (pas le `.bat` lui-même).
- Quand `GameSwap.ps1` se termine, `powershell.exe` se ferme → la fenêtre console se ferme automatiquement.
- Raison : relancer le `.bat` en élevé via `Start-Process -Verb RunAs` ouvre `cmd.exe /k` qui garde la fenêtre ouverte après la fin du script.

### Redistribuables système dans l'onglet Paramétrage
- Bouton VC++ : installe les 12 packages winget (`Microsoft.VCRedist.2005.x86` à `Microsoft.VCRedist.2015+.x64`) dans une console PowerShell visible. Le code de sortie `-1978335189` signifie "déjà installé" (non-fatal).
- Bouton DirectX : télécharge `dxwebsetup.exe` depuis `download.microsoft.com` dans `%TEMP%`, l'exécute avec `/Q` (silencieux, sans proposition de barre Bing), puis supprime le fichier.

### DisplayName et ReleaseYear dans `_info.xml`
- `DisplayName` permet un nom de jeu avec espaces et caractères spéciaux dans les DataGrids (le nom de dossier reste le nom technique sans espaces).
- Si `DisplayName` est absent ou vide, le nom du dossier est utilisé en fallback.
- `ReleaseYear` est affiché dans le panneau de détails des deux onglets (Mes Jeux et Réseau).
- Ces champs sont lus par `Get-GSGameExtraInfo` (local) et inline dans `Get-RemoteGameList` (réseau).

### Template install.ps1 — étapes ajoutées
- **Étape 3h** : solution universelle — `$universalFile` (chemin) + `$universalField` (nom du champ). Remplace `Champ=valeur` par `Champ=$PlayerName` dans n'importe quel fichier texte via regex `(?m)^Champ=[^\r\n]*`. Utilise `[regex]::Escape()` pour sécuriser le nom du champ.
- **Étape 4b** : lancement optionnel d'un configurateur graphique (`$configuratorExe`). Lancé avec `-Wait` — l'installation attend la fermeture avant de continuer. Ignoré silencieusement si le chemin est vide.
