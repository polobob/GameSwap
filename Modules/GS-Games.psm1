#Requires -Version 5.1
# Module GS-Games.psm1 - Gestion des jeux locaux (liste, installation, lancement, telechargement)
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

function Get-LocalGames {
    param(
        [Parameter(Mandatory)]
        [string]$GamesFolder
    )

    $games = @()
    if (-not (Test-Path $GamesFolder)) {
        Write-GSLog "Dossier Jeux absent: $GamesFolder" -Level "WARNING"
        return $games
    }

    $folders = Get-ChildItem -Path $GamesFolder -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $folders) {
        $vhdx = Get-ChildItem -Path $folder.FullName -Filter "*.vhdx" -ErrorAction SilentlyContinue |
                Select-Object -First 1
        if (-not $vhdx) { continue }

        $xmlPath      = Join-Path $folder.FullName "$($folder.Name).xml"
        $infoXmlPath  = Join-Path $folder.FullName "$($folder.Name)_info.xml"
        $installed    = Test-Path $xmlPath
        $sizeMB       = [math]::Round($vhdx.Length / 1MB, 1)
        $sizeStr      = if ($sizeMB -ge 1024) { "$([math]::Round($sizeMB/1024,2)) Go" } else { "$sizeMB Mo" }
        $gameInfo     = $null
        $extraInfo    = $null
        $thumbPath    = $null

        if ($installed) {
            $gameInfo = Get-GSGameInfo -XmlPath $xmlPath
        }

        if (Test-Path $infoXmlPath) {
            $extraInfo = Get-GSGameExtraInfo -XmlPath $infoXmlPath
            if ($extraInfo -and $extraInfo.Thumbnail) {
                $tp = Join-Path $folder.FullName $extraInfo.Thumbnail
                if (Test-Path $tp) { $thumbPath = $tp }
            }
        }

        $games += [PSCustomObject]@{
            GameName    = $folder.Name
            FolderPath  = $folder.FullName
            VhdxPath    = $vhdx.FullName
            XmlPath     = $xmlPath
            IsInstalled = $installed
            SizeMB      = $sizeMB
            SizeText    = $sizeStr
            GameInfo    = $gameInfo
            ExtraInfo   = $extraInfo
            ThumbPath   = $thumbPath
        }
    }

    return $games
}

function Get-GSGameInfo {
    param(
        [Parameter(Mandatory)]
        [string]$XmlPath
    )
    if (-not (Test-Path $XmlPath)) { return $null }

    try {
        [xml]$xml = Get-Content $XmlPath -Encoding UTF8
        return [PSCustomObject]@{
            GameName      = $xml.GameInfo.GameName
            LaunchCommand = $xml.GameInfo.LaunchCommand
            ServerCommand = $xml.GameInfo.ServerCommand
            Version       = $xml.GameInfo.Version
            InstalledDate = $xml.GameInfo.InstalledDate
            Description   = $xml.GameInfo.Description
        }
    } catch {
        Write-GSLog "Erreur lecture XML '$XmlPath': $_" -Level "ERROR"
        return $null
    }
}

function Get-GSGameExtraInfo {
    param(
        [Parameter(Mandatory)]
        [string]$XmlPath
    )
    if (-not (Test-Path $XmlPath)) { return $null }

    try {
        [xml]$xml = Get-Content $XmlPath -Encoding UTF8
        return [PSCustomObject]@{
            DisplayName  = $xml.GameExtraInfo.DisplayName
            ReleaseYear  = $xml.GameExtraInfo.ReleaseYear
            Trailer      = $xml.GameExtraInfo.Trailer
            MaxPlayers   = $xml.GameExtraInfo.MaxPlayers
            Thumbnail    = $xml.GameExtraInfo.Thumbnail
            Description  = $xml.GameExtraInfo.Description
            Instructions = $xml.GameExtraInfo.Instructions
        }
    } catch {
        Write-GSLog "Erreur lecture _info.xml '$XmlPath': $_" -Level "WARNING"
        return $null
    }
}

function Install-GSGame {
    param(
        [Parameter(Mandatory)]
        [string]$VhdxPath,
        [Parameter(Mandatory)]
        [string]$GameFolder,
        [Parameter(Mandatory)]
        [string]$GameName
    )

    Write-GSLog "Debut d'installation: $GameName" -Level "INFO"
    $driveLetter = $null

    try {
        $driveLetter = Mount-GSVhdx -VhdxPath $VhdxPath
        Write-GSLog "VHDX monte sur $driveLetter" -Level "INFO"

        $installScript = Join-Path $driveLetter "install.ps1"
        if (-not (Test-Path $installScript)) {
            throw "Fichier install.ps1 introuvable a la racine de $driveLetter"
        }

        Write-GSLog "Execution de install.ps1 pour $GameName" -Level "INFO"
        $proc = Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$installScript`"", "-GameFolder", "`"$GameFolder`"", "-GameName", "`"$GameName`"" `
            -Wait -PassThru

        if ($proc.ExitCode -ne 0) {
            throw "install.ps1 a echoue (code de sortie: $($proc.ExitCode))"
        }

        Write-GSLog "Installation de '$GameName' terminee avec succes" -Level "INFO"
        return $true

    } catch {
        Write-GSLog "Erreur installation '$GameName': $_" -Level "ERROR"
        throw
    } finally {
        if ($driveLetter) {
            Dismount-GSVhdx
        }
    }
}

function Start-GSGame {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Game
    )

    if (-not $Game.IsInstalled -or -not $Game.GameInfo) {
        throw "Le jeu '$($Game.GameName)' n'est pas installe"
    }

    Write-GSLog "Lancement de '$($Game.GameName)'" -Level "INFO"

    Mount-GSVhdx -VhdxPath $Game.VhdxPath | Out-Null
    $cmd = $Game.GameInfo.LaunchCommand

    if ([string]::IsNullOrWhiteSpace($cmd)) {
        throw "Commande de lancement vide dans le fichier XML"
    }

    Write-GSLog "Commande: $cmd" -Level "INFO"

    # Extraire le dossier de travail depuis l'executable
    $workDir = $null
    if ($cmd -match '^"(.+?)"') {
        $exePath = $matches[1]
    } else {
        $exePath = ($cmd -split '\s+', 2)[0]
    }
    if (Test-Path $exePath) {
        $workDir = Split-Path $exePath -Parent
    }

    # Lancer via cmd.exe pour un environnement MS-DOS natif
    $cmdArgs = if ($workDir) {
        "/c cd /d `"$workDir`" && $cmd"
    } else {
        "/c $cmd"
    }

    Write-GSLog "Lancement cmd.exe $cmdArgs" -Level "INFO"
    $startParams = @{
        FilePath     = "cmd.exe"
        ArgumentList = $cmdArgs
        PassThru     = $true
    }
    if ($workDir) { $startParams.WorkingDirectory = $workDir }
    $proc = Start-Process @startParams

    return [PSCustomObject]@{
        Process  = $proc
        VhdxPath = $Game.VhdxPath
    }
}

function Start-GSServer {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Game
    )

    if (-not $Game.IsInstalled -or -not $Game.GameInfo) {
        throw "Le jeu '$($Game.GameName)' n'est pas installe"
    }

    $cmd = $Game.GameInfo.ServerCommand
    if ([string]::IsNullOrWhiteSpace($cmd)) {
        throw "Aucune commande serveur definie pour '$($Game.GameName)'"
    }

    Write-GSLog "Lancement serveur '$($Game.GameName)'" -Level "INFO"

    Mount-GSVhdx -VhdxPath $Game.VhdxPath | Out-Null

    Write-GSLog "Commande serveur: $cmd" -Level "INFO"

    $workDir = $null
    if ($cmd -match '^"(.+?)"') {
        $exePath = $matches[1]
    } else {
        $exePath = ($cmd -split '\s+', 2)[0]
    }
    if (Test-Path $exePath) {
        $workDir = Split-Path $exePath -Parent
    }

    $cmdArgs = if ($workDir) {
        "/c cd /d `"$workDir`" && $cmd"
    } else {
        "/c $cmd"
    }

    Write-GSLog "Lancement cmd.exe $cmdArgs" -Level "INFO"
    $startParams = @{
        FilePath     = "cmd.exe"
        ArgumentList = $cmdArgs
        PassThru     = $true
    }
    if ($workDir) { $startParams.WorkingDirectory = $workDir }
    $proc = Start-Process @startParams

    return [PSCustomObject]@{
        Process  = $proc
        VhdxPath = $Game.VhdxPath
    }
}

function Copy-RemoteGame {
    param(
        [Parameter(Mandatory)]
        [string]$RemoteVhdxPath,
        [Parameter(Mandatory)]
        [string]$LocalGamesFolder,
        [Parameter(Mandatory)]
        [string]$GameName,
        [Parameter(Mandatory)]
        [string]$HostIP,
        [Parameter(Mandatory)]
        [string]$PlayerName,
        [Parameter(Mandatory)]
        [string]$ShareRootPath,
        [scriptblock]$OnProgress,
        [scriptblock]$OnComplete,
        [scriptblock]$OnError
    )

    Write-GSLog "Debut telechargement: $GameName depuis $HostIP" -Level "INFO"

    $destFolder = Join-Path $LocalGamesFolder $GameName
    if (-not (Test-Path $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }
    $destFile = Join-Path $destFolder "$GameName.vhdx"

    # Lancer le telechargement dans un runspace separe pour ne pas bloquer l'UI
    $syncHash = [hashtable]::Synchronized(@{
        Progress    = 0
        Status      = "Connexion..."
        IsComplete  = $false
        HasError    = $false
        ErrorMsg    = ""
        DestFile    = $destFile
        GameName    = $GameName
        StartTime   = [datetime]::Now
        Elapsed     = ""
        ETA         = ""
    })

    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()
    $rs.SessionStateProxy.SetVariable("syncHash",       $syncHash)
    $rs.SessionStateProxy.SetVariable("remoteVhdxPath", $RemoteVhdxPath)
    $rs.SessionStateProxy.SetVariable("destFile",       $destFile)
    $rs.SessionStateProxy.SetVariable("destFolder",     $destFolder)
    $rs.SessionStateProxy.SetVariable("gameName",       $GameName)
    $rs.SessionStateProxy.SetVariable("gsUser",         "GameSwap")
    $rs.SessionStateProxy.SetVariable("gsPass",         "Edams-Bourbe0")
    $rs.SessionStateProxy.SetVariable("hostIP",         $HostIP)
    $rs.SessionStateProxy.SetVariable("playerName",     $PlayerName)
    $rs.SessionStateProxy.SetVariable("shareRootPath",  $ShareRootPath)

    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript({
        $sharePath = "\\$hostIP\GameSwap"
        cmd /c "net use $sharePath /DELETE /Y" 2>&1 | Out-Null
        $out = cmd /c "net use $sharePath /USER:$gsUser $gsPass /PERSISTENT:NO" 2>&1
        if ($LASTEXITCODE -ne 0) {
            $syncHash.HasError  = $true
            $syncHash.ErrorMsg  = "Impossible de se connecter au partage: $out"
            $syncHash.IsComplete = $true
            return
        }

        try {
            $srcItem   = Get-Item $remoteVhdxPath -ErrorAction Stop
            $totalSize = $srcItem.Length
            $bufSize   = 4MB
            $buffer    = New-Object byte[] $bufSize
            $copied    = 0

            $syncHash.Status = "Telechargement en cours..."
            $src = [System.IO.File]::OpenRead($remoteVhdxPath)
            $dst = [System.IO.File]::Create($destFile)

            do {
                $read = $src.Read($buffer, 0, $bufSize)
                if ($read -gt 0) {
                    $dst.Write($buffer, 0, $read)
                    $copied += $read
                    if ($totalSize -gt 0) {
                        $syncHash.Progress = [int](($copied / $totalSize) * 100)
                        $elapsed = [datetime]::Now - $syncHash.StartTime
                        $syncHash.Elapsed = "$([int]$elapsed.TotalMinutes)m$($elapsed.Seconds.ToString('00'))s"
                        if ($copied -gt 0) {
                            $bytesPerSec = $copied / $elapsed.TotalSeconds
                            $remaining  = ($totalSize - $copied) / $bytesPerSec
                            $eta = [timespan]::FromSeconds($remaining)
                            $syncHash.ETA = "$([int]$eta.TotalMinutes)m$($eta.Seconds.ToString('00'))s"
                        }
                    }
                }
            } while ($read -gt 0)

            $syncHash.Status = "Termine"

            # Copier le fichier _info.xml s'il existe
            $remoteFolder  = Split-Path $remoteVhdxPath -Parent
            $remoteInfoXml = Join-Path $remoteFolder "$gameName`_info.xml"
            if (Test-Path $remoteInfoXml) {
                Copy-Item -Path $remoteInfoXml -Destination (Join-Path $destFolder "$gameName`_info.xml") -Force -ErrorAction SilentlyContinue
            }

            # Copier la vignette si elle existe (PNG ou JPG)
            foreach ($ext in @("png", "jpg")) {
                $remoteThumb = Join-Path $remoteFolder "$gameName.$ext"
                if (Test-Path $remoteThumb) {
                    Copy-Item -Path $remoteThumb -Destination (Join-Path $destFolder "$gameName.$ext") -Force -ErrorAction SilentlyContinue
                    break
                }
            }

            $syncHash.IsComplete = $true

        } catch {
            $syncHash.HasError  = $true
            $syncHash.ErrorMsg  = $_.ToString()
            $syncHash.IsComplete = $true
            if (Test-Path $destFile) { Remove-Item $destFile -Force -ErrorAction SilentlyContinue }
        } finally {
            if ($src) { try { $src.Close() } catch {} }
            if ($dst) { try { $dst.Close() } catch {} }
            cmd /c "net use $sharePath /DELETE /Y" 2>&1 | Out-Null
            # Liberer uniquement notre slot (conserver ceux des autres joueurs)
            try {
                $queueFile  = Join-Path $shareRootPath "download_queue.json"
                $myPlayer   = $playerName
                $myGame     = $syncHash.GameName
                if (Test-Path $queueFile) {
                    $json  = Get-Content $queueFile -Raw -Encoding UTF8
                    $data  = $json | ConvertFrom-Json
                    $slots = @($data.slots | Where-Object { -not ($_.PlayerName -eq $myPlayer -and $_.GameName -eq $myGame) })
                    ([PSCustomObject]@{ slots = $slots }) | ConvertTo-Json -Depth 3 | Set-Content $queueFile -Encoding UTF8
                }
            } catch {}
        }
    })

    [void]$ps.BeginInvoke()

    return [PSCustomObject]@{
        SyncHash  = $syncHash
        Runspace  = $rs
        PowerShell = $ps
    }
}

Export-ModuleMember -Function Get-LocalGames, Get-GSGameInfo, Get-GSGameExtraInfo, Install-GSGame, Start-GSGame, Start-GSServer, Copy-RemoteGame
