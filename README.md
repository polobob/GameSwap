# GameSwap

Application PowerShell/WPF de partage de jeux en réseau local via disques virtuels VHDX.

## Principe

Chaque joueur expose son dossier de jeux via un partage SMB. Les autres joueurs scannent le réseau, parcourent les bibliothèques disponibles, téléchargent les jeux qui les intéressent et les lancent directement — sans installation complexe.

```
[Hôte]                          [Client]
Dossier GameSwap/               Scanner le réseau
  └── Jeux/                     → Trouve le partage SMB
       └── MonJeu/              → Parcourt la bibliothèque
            └── MonJeu.vhdx     → Télécharge le VHDX
                MonJeu_info.xml → Lance l'installation
                MonJeu.jpg      → Joue
```

## Prérequis

| Élément | Détail |
|---|---|
| Windows 10 / 11 | |
| PowerShell 5.1+ | Inclus dans Windows |
| Droits administrateur | Partage SMB, montage VHDX, compte local |
| `Mount-DiskImage` | Inclus dans Windows (fonctionnalité Hyper-V) |
| nmap | Installé automatiquement via `winget` au premier lancement |

## Installation

1. Copier le dossier `GameSwap/` où vous le souhaitez (ex : `D:\`)
2. Lancer `Start-GameSwap.bat` en tant qu'administrateur
3. Suivre l'assistant de configuration (dossier d'installation + nom de joueur)

L'application crée automatiquement :
- Un compte Windows local `GameSwap` (pour l'authentification SMB)
- Un partage réseau `\\NomPC\GameSwap` accessible aux autres joueurs

## Structure du projet

```
GameSwap/
├── GameSwap.ps1              Point d'entrée principal
├── Start-GameSwap.bat        Lanceur (élève les droits admin)
├── Uninstall.bat             Désinstallation complète
│
├── Modules/
│   ├── GS-Log.psm1           Journalisation
│   ├── GS-Init.psm1          Paramètres et vérifications système
│   ├── GS-Account.psm1       Compte local Windows
│   ├── GS-Share.psm1         Partage SMB et file de téléchargement
│   ├── GS-Network.psm1       Scan réseau (nmap) et connexion aux partages
│   ├── GS-VHDX.psm1          Montage/démontage des fichiers VHDX
│   ├── GS-Games.psm1         Gestion des jeux locaux
│   └── GS-UI.psm1            Interface WPF (XAML + handlers)
│
└── Templates/
    ├── install.ps1           Template d'installation à placer dans chaque VHDX
    ├── gameinfo.xml          Template des métadonnées visuelles du jeu
    └── gameswap_user.json    Template d'identification pour NAS
```

## Interface

**Onglet Mes Jeux** — bibliothèque locale : installer, jouer, lancer un serveur dédié, désinstaller ou supprimer un jeu.

**Onglet Réseau** — scanner le LAN, parcourir les bibliothèques des autres joueurs et télécharger des jeux. Gestion d'une file d'attente automatique si les slots de téléchargement sont occupés.

**Onglet Paramétrage** — nom de joueur, dossier GameSwap, nombre de téléchargements simultanés autorisés, supervision des téléchargements en cours.

## Préparer un jeu (pour les créateurs de VHDX)

Chaque jeu est un fichier `.vhdx` contenant :

```
MonJeu.vhdx (monté sur U:)
├── install.ps1          Obligatoire — script d'installation
├── game.exe             Exécutable du jeu
└── ...
```

Le fichier `install.ps1` (basé sur le template `Templates/install.ps1`) gère :
- L'installation des redistribuables (VC++, DirectX…)
- La configuration des clés de registre
- L'écriture du nom du joueur dans les fichiers de config du jeu (formats : `account_name.txt`, `steam_emu.ini`, `SmartSteamEmu.ini`, `config.ini`, ou tout fichier/champ configurable librement)
- Le lancement optionnel d'un configurateur graphique
- La création du fichier XML de métadonnées GameSwap

Le fichier `[NomDuJeu]_info.xml` (optionnel) enrichit l'affichage dans l'interface :

```xml
<GameExtraInfo>
  <DisplayName>Nom complet du jeu</DisplayName>
  <ReleaseYear>2004</ReleaseYear>
  <MaxPlayers>8</MaxPlayers>
  <Trailer>https://www.youtube.com/watch?v=...</Trailer>
  <Thumbnail>MonJeu.jpg</Thumbnail>
  <Description>Description courte.</Description>
  <Instructions>Instructions d'installation ou notes.</Instructions>
</GameExtraInfo>
```

## Support NAS

Un NAS peut exposer un partage `GameSwap` avec le même compte (`GameSwap` / mot de passe partagé). Il suffit de déposer un fichier `gameswap_user.json` à la racine du partage :

```json
{ "PlayerName": "NomDuNAS", "MaxDownloadSlots": 3 }
```

## Documentation complète

Voir [GAMESWAP.md](GAMESWAP.md) pour la documentation technique détaillée (modules, formats de fichiers, décisions de conception).
