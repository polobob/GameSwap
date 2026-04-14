#Requires -Version 5.1
# Module GS-Account.psm1 - Gestion du compte local GameSwap
# Encodage: UTF-8 BOM | Fins de ligne: CRLF

$script:GSUser     = "GameSwap"
$script:GSPassword = "Edams-Bourbe0"

function Test-GSLocalAccount {
    $user = Get-LocalUser -Name $script:GSUser -ErrorAction SilentlyContinue
    return ($null -ne $user)
}

function New-GSLocalAccount {
    if (Test-GSLocalAccount) {
        Write-GSLog "Compte local '$($script:GSUser)' existe deja" -Level "INFO"
        return
    }
    try {
        $secPwd = ConvertTo-SecureString $script:GSPassword -AsPlainText -Force
        New-LocalUser -Name $script:GSUser `
                      -Password $secPwd `
                      -Description "Compte de service GameSwap - ne pas supprimer" `
                      -PasswordNeverExpires:$true `
                      -UserMayNotChangePassword:$true | Out-Null
        Write-GSLog "Compte local '$($script:GSUser)' cree avec succes" -Level "INFO"
    } catch {
        Write-GSLog "Erreur creation compte local: $_" -Level "ERROR"
        throw
    }
}

function Get-GSAccountName     { return $script:GSUser }
function Get-GSAccountPassword { return $script:GSPassword }

Export-ModuleMember -Function Test-GSLocalAccount, New-GSLocalAccount, Get-GSAccountName, Get-GSAccountPassword
