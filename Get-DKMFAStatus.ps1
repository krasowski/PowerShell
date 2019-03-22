function Get-DKMFAStatus
{
	<#
	.SYNOPSIS
		Returnerar användarens MFA-status i Azure
	.DESCRIPTION
		Funktionen Get-DKMFAStatus tar emot ett eller flera användarid för en AD-användare 
		och returnera sedan användarens MFA-status i Office 365.
	.EXAMPLE
		Get-DKMFAStatus agneta
	.EXAMPLE
		Get-DKMFAStatus agneta@example.com
	.PARAMETER userInput
		En eller flera användarobjekt eller sträng med sAMAccountName
	.NOTES
		Funktionen kräver rättighet i Office 365. 
		Modulen MSOnline måste vara installerad på datorn som kör skriptet.

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
            $userMFA = Get-MsolUser -UserPrincipalName $objUser.UserPrincipalName | Select-Object -ExpandProperty StrongAuthenticationRequirements

			if ($userMFA.State -eq "Enforced" -or $userMFA.state -eq "Enabled")
			{
				Write-Host "Användaren" $user "har MFA satt till" $userMFA.State
			}
			else
			{
				Write-Host "Användaren" $user "har inte MFA aktiverad"
			}
        }
        else
        {
            Write-Host "Användaren" $user "Finns inte" -ForegroundColor Red
        }
    }
}