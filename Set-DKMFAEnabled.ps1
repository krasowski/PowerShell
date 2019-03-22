function Set-DKMFAEnabled
	<#
	.SYNOPSIS
		Ändrar användarens MFA-status i Azure till Enabled
	.DESCRIPTION
		Funktionen Set-DKMFAEnabled tar emot ett eller flera användarid för en AD-användare 
		och ändrar sedan användarens MFA-status i Office 365 till Enabled.
	.EXAMPLE
		Set-DKMFAEnabled agneta
	.EXAMPLE
		Set-DKMFAEnabled agneta@example.com
	.PARAMETER userInput
		En eller flera användarobjekt eller sträng med sAMAccountName
	.NOTES
		Funktionen kräver rättighet i Office 365. 
		Modulen MSOnline måste vara installerad på datorn som kör skriptet.

		Author: David Krasowski - david.krasowski@gmail.com
	#>

{
    [cmdletbinding(SupportsShouldProcess=$True)]
    PARAM (
    [Parameter(ValueFromPipeLine = $true)]
    [array]$userInput
    )

	# Importera modul om inte redan inläst
    if (-not(Get-Module -name AzureAD))
    {
        Import-Module AzureAD
    }

    # Logga in om ingen befintlig session hittas
    try
    {
        Get-AzureADDomain -ErrorAction Stop > $null
    }
    catch 
    {
        Connect-AzureAD
    }

    # Ta fram nödvändiga objekt
    $auth = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $auth.RelyingParty = "*"
    $auth.State = "Enabled"
    $auth.RememberDevicesNotIssuedBefore = (Get-Date)

    foreach ($user in $userInput)
    {
        
        # Rensa objekt
        $objUser = $null

        # Kolla om inmatningen är en sAMAccountName eller UPN och hantera därefter
        if ($user -match '\w+@\w+\.\w+')
        {
            # Sök användaren i AD:et - inget objekt returneras om användaren inte finns
            $objUser = Get-ADUser -Filter {UserPrincipalName -eq $user}
        }
        else
        {
            # Testa om användaren finns
            try
            {
                $objUser = Get-ADUser -Identity $user
            }
            # Fånga felet om användaren saknas i AD:et
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
        }

        # Ändra behörigheter endast om användaren finns
        if ($objUser)
        {
            Set-MsolUser -UserPrincipalName $objUser.UserPrincipalName -StrongAuthenticationRequirements $auth
            Write-Host "Användaren" $user "har MFA satt till Enabled" -ForegroundColor Green
        }
        else
        {
            Write-Host "Användaren" $user "Finns inte" -ForegroundColor Red
        }
    }
}