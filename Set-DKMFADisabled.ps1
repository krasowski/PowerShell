function Set-DKMFADisabled
{
	<#
	.SYNOPSIS
		Ändrar användarens MFA-status i Azure till Disabled.
	.DESCRIPTION
		Funktionen Set-UKMFADisabled tar emot ett eller flera användarid för en AD-användare 
		och ändrar sedan användarens MFA-status i Office 365 till Enforced.
	.EXAMPLE
		Set-UKMFADisabled agneta
	.EXAMPLE
		Set-UKMFADisabled agneta@example.com
	.PARAMETER userInput
		Ett eller flera användarobjekt eller strängar med sAMAccountName
	.NOTES
		Funktionen kräver rättighet i Office 365. 
		Modulen MSOnline mäste vara installerad på datorn som kör skriptet.

		Author: David Krasowski - david.krasowski@gmail.com
	#>

    [cmdletbinding(SupportsShouldProcess=$True)]
    PARAM (
    [Parameter(ValueFromPipeLine = $true)]
    [array]$userInput
    )

	# Importera modul om inte redan inläst
    if (-not(Get-Module -name MSOnline))
    {
        Import-Module MSOnline
    }

    # Logga in om ingen befintlig session hittas
    try
    {
        Get-MsolDomain -ErrorAction Stop > $null
    }
    catch 
    {
        Connect-MsolService
    }

    # Ta fram nädvändiga objekt
    $auth = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $auth.RelyingParty = "*"
    $auth.State = "Disabled"
    $auth.RememberDevicesNotIssuedBefore = (Get-Date)

    foreach ($user in $userInput)
    {
        
        # Rensa objekt
        $objUser = $null

        # Kolla om inmatningen är en sAMAccountName eller UPN och hantera därefter
        if ($user -match '\w+@\w+\.\w+')
        {
            # Säk användaren i AD:et - inget objekt returneras om användaren inte finns
            $objUser = Get-ADUser -Filter {UserPrincipalName -eq $user}
        }
        else
        {
            # Testa om användaren finns
            try
            {
                $objUser = Get-ADUser -Identity $user
            }
            # Fänga felet om användaren saknas i AD:et
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
        }

        # ändra behärigheter endast om användaren finns
        if ($objUser)
        {
            Set-MsolUser -UserPrincipalName $objUser.UserPrincipalName -StrongAuthenticationRequirements @()
            Write-Host "Användaren" $user "har MFA satt till Disabled" -ForegroundColor Green
        }
        else
        {
            Write-Host "Användaren" $user "Finns inte" -ForegroundColor Red
        }
    }
}