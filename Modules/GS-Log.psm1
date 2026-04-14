#Requires -Version 5.1
# Module GS-Log.psm1 - Gestion des logs GameSwap
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

$script:LogFile = $null

function Initialize-GSLog {
    param(
        [Parameter(Mandatory)]
        [string]$LogDir
    )
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    $date = Get-Date -Format "yyyyMMdd"
    $script:LogFile = Join-Path $LogDir "GameSwap_$date.log"
    Write-GSLog "========================================" -Level "INFO"
    Write-GSLog "Session demarree - GameSwap" -Level "INFO"
    Write-GSLog "========================================" -Level "INFO"
}

function Write-GSLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet("INFO","WARNING","ERROR","DEBUG")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $line -Encoding UTF8
    }
    switch ($Level) {
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "WARNING" { Write-Host $line -ForegroundColor Yellow }
        "DEBUG"   { Write-Host $line -ForegroundColor DarkGray }
        default   { Write-Host $line -ForegroundColor Cyan }
    }
}

Export-ModuleMember -Function Initialize-GSLog, Write-GSLog
