#Requires -Version 5.1
# Module GS-Network.psm1 - Decouverte reseau et listage des partages GameSwap via nmap
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

function Get-AllNetworkAdapters {
    $entries = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notmatch '^127\.' -and
            $_.IPAddress -notmatch '^169\.254\.' -and
            $_.PrefixOrigin -ne 'WellKnown'
        }

    $result = @()
    foreach ($e in $entries) {
        $ipParts = $e.IPAddress -split '\.'
        $subnet  = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2]).0/$($e.PrefixLength)"
        $result += [PSCustomObject]@{
            InterfaceAlias = $e.InterfaceAlias
            IPAddress      = $e.IPAddress
            Subnet         = $subnet
            PrefixLength   = $e.PrefixLength
            DisplayName    = "$($e.InterfaceAlias)  ($($e.IPAddress))"
        }
    }
    return $result
}

function Get-LocalIPInfo {
    param([string]$SelectedIP = "")

    $adapters = Get-AllNetworkAdapters
    if (-not $adapters) {
        Write-GSLog "Aucune interface reseau valide trouvee" -Level "WARNING"
        return $null
    }

    $adapter = $null
    if ($SelectedIP) {
        $adapter = $adapters | Where-Object { $_.IPAddress -eq $SelectedIP } | Select-Object -First 1
    }
    if (-not $adapter) {
        $adapter = $adapters | Select-Object -First 1
    }

    return $adapter
}

function Find-GSSharesOnNetwork {
    param(
        [Parameter(Mandatory)]
        [string]$Subnet
    )

    $nmapCmd = Get-Command nmap.exe -ErrorAction SilentlyContinue
    if (-not $nmapCmd) {
        Write-GSLog "nmap introuvable - scan impossible" -Level "ERROR"
        return @()
    }

    Write-GSLog "Scan nmap du sous-reseau: $Subnet" -Level "INFO"

    # Scan rapide: detecter les hotes avec le port SMB 445 ouvert
    $nmapArgs = @("-p", "445", "--open", "-T4", "--host-timeout", "3s", $Subnet)
    $nmapOut  = & $nmapCmd.Source @nmapArgs 2>&1

    $hostsWithSMB = @()
    $currentIP    = $null
    foreach ($line in $nmapOut) {
        if ($line -match 'Nmap scan report for (.+)') {
            $raw = $matches[1].Trim()
            # Extraire l'IP si format "hostname (IP)"
            if ($raw -match '\((\d+\.\d+\.\d+\.\d+)\)') {
                $currentIP = $matches[1]
            } elseif ($raw -match '^\d+\.\d+\.\d+\.\d+$') {
                $currentIP = $raw
            } else {
                $currentIP = $raw
            }
        }
        if ($line -match '445/tcp\s+open' -and $currentIP) {
            $hostsWithSMB += $currentIP
            Write-GSLog "  Port 445 ouvert: $currentIP" -Level "DEBUG"
        }
    }

    Write-GSLog "Hotes avec SMB: $($hostsWithSMB.Count)" -Level "INFO"

    # Verifier le partage GameSwap sur chaque hote
    $gsShares = @()
    foreach ($ip in $hostsWithSMB) {
        Write-GSLog "  Verification GameSwap sur $ip..." -Level "DEBUG"
        $info = Connect-GSShare -HostIP $ip
        if ($info) {
            $gsShares += $info
            Write-GSLog "  Partage GameSwap trouve: $ip (joueur: $($info.PlayerName))" -Level "INFO"
        }
    }

    Write-GSLog "Partages GameSwap trouves: $($gsShares.Count)" -Level "INFO"
    return $gsShares
}

function Connect-GSShare {
    param(
        [Parameter(Mandatory)]
        [string]$HostIP
    )

    $sharePath = "\\$HostIP\GameSwap"
    $gsUser    = "GameSwap"
    $gsPass    = "Edams-Bourbe0"

    # Deconnecter d'abord si une connexion existe
    cmd /c "net use $sharePath /DELETE /Y" 2>&1 | Out-Null

    # Connexion avec les identifiants GameSwap (PC et NAS utilisent le meme compte)
    cmd /c "net use $sharePath /USER:$gsUser $gsPass /PERSISTENT:NO" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    try {
        $playerName = ""
        $isNas      = $false

        # Cas 1 : partage PC GameSwap standard (gameswap_info.json)
        $infoFile = "$sharePath\gameswap_info.json"
        if (Test-Path $infoFile) {
            try {
                $shareInfo  = Get-Content $infoFile -Raw -Encoding UTF8 | ConvertFrom-Json
                $playerName = $shareInfo.PlayerName
            } catch {}
        }

        # Cas 2 : partage NAS (gameswap_user.json, cree manuellement par l'admin NAS)
        if ([string]::IsNullOrWhiteSpace($playerName)) {
            $userFile = "$sharePath\gameswap_user.json"
            if (Test-Path $userFile) {
                try {
                    $userInfo   = Get-Content $userFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    $playerName = $userInfo.PlayerName
                    $isNas      = $true
                    Write-GSLog "  Identification NAS depuis gameswap_user.json : $playerName" -Level "DEBUG"
                } catch {}
            }
        }

        # Aucune identification possible
        if ([string]::IsNullOrWhiteSpace($playerName)) {
            Write-GSLog "  Partage GameSwap sur $HostIP sans identification" -Level "DEBUG"
            return $null
        }

        return [PSCustomObject]@{
            IPAddress   = $HostIP
            PlayerName  = $playerName
            SharePath   = $sharePath
            IsNas       = $isNas
        }
    } catch {
        Write-GSLog "Erreur lecture info partage $HostIP : $_" -Level "DEBUG"
        return $null
    } finally {
        cmd /c "net use $sharePath /DELETE /Y" 2>&1 | Out-Null
    }
}

function Get-RemoteGameList {
    param(
        [Parameter(Mandatory)]
        [string]$HostIP
    )

    $sharePath = "\\$HostIP\GameSwap"
    $gsUser    = "GameSwap"
    $gsPass    = "Edams-Bourbe0"

    # Connexion avec les identifiants GameSwap (PC et NAS utilisent le meme compte)
    cmd /c "net use $sharePath /DELETE /Y" 2>&1 | Out-Null
    cmd /c "net use $sharePath /USER:$gsUser $gsPass /PERSISTENT:NO" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-GSLog "Impossible de se connecter a $sharePath" -Level "WARNING"
        return @()
    }

    $games     = @()
    $jeuxPath  = "$sharePath\Jeux"

    try {
        if (-not (Test-Path $jeuxPath)) {
            Write-GSLog "Dossier Jeux absent sur $HostIP" -Level "WARNING"
            return @()
        }

        $folders = Get-ChildItem -Path $jeuxPath -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $folders) {
            $vhdx = Get-ChildItem -Path $folder.FullName -Filter "*.vhdx" -ErrorAction SilentlyContinue |
                    Select-Object -First 1
            if ($vhdx) {
                $sizeMB  = [math]::Round($vhdx.Length / 1MB, 1)
                $sizeStr = if ($sizeMB -ge 1024) { "$([math]::Round($sizeMB/1024,2)) Go" } else { "$sizeMB Mo" }

                # Lire le fichier _info.xml s'il existe
                $extraInfo = $null
                $thumbPath = $null
                $infoXmlPath = Join-Path $folder.FullName "$($folder.Name)_info.xml"
                if (Test-Path $infoXmlPath) {
                    try {
                        [xml]$xi = Get-Content $infoXmlPath -Encoding UTF8
                        $extraInfo = [PSCustomObject]@{
                            DisplayName  = $xi.GameExtraInfo.DisplayName
                            ReleaseYear  = $xi.GameExtraInfo.ReleaseYear
                            Trailer      = $xi.GameExtraInfo.Trailer
                            MaxPlayers   = $xi.GameExtraInfo.MaxPlayers
                            Thumbnail    = $xi.GameExtraInfo.Thumbnail
                            Description  = $xi.GameExtraInfo.Description
                            Instructions = $xi.GameExtraInfo.Instructions
                        }
                        if ($extraInfo.Thumbnail) {
                            $tp = Join-Path $folder.FullName $extraInfo.Thumbnail
                            if (Test-Path $tp) { $thumbPath = $tp }
                        }
                    } catch {}
                }

                # Lire les bytes de la vignette pendant que le partage est connecte
                $thumbBytes = $null
                if ($thumbPath) {
                    try { $thumbBytes = [System.IO.File]::ReadAllBytes($thumbPath) } catch {}
                }

                $games += [PSCustomObject]@{
                    GameName    = $folder.Name
                    SizeText    = $sizeStr
                    SizeMB      = $sizeMB
                    RemotePath  = $vhdx.FullName
                    HostIP      = $HostIP
                    ExtraInfo   = $extraInfo
                    ThumbPath   = $thumbPath
                    ThumbBytes  = $thumbBytes
                }
            }
        }
    } catch {
        Write-GSLog "Erreur listage jeux sur $HostIP : $_" -Level "ERROR"
    } finally {
        cmd /c "net use $sharePath /DELETE /Y" 2>&1 | Out-Null
    }

    return $games
}

Export-ModuleMember -Function Get-AllNetworkAdapters, Get-LocalIPInfo, Find-GSSharesOnNetwork, Connect-GSShare, Get-RemoteGameList
