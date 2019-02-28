function Set-DKUPN
{
	<#
	.SYNOPSIS
		Sätter om användarens User Principal Name till samma som epostadress
	.DESCRIPTION
		Funktionen Set-DKUPN tar emot ett eller flera användarid för en AD-användare 
		och sätter sedan om UPN till samma värde som epostadressen.
	.EXAMPLE
		Sätt om UPN för användare kiltro
		Set-DKUPN kiltro
	.EXAMPLE
		Sätt om UPN för en hel AD-grupp. Visa endast rader för användare som saknar
		epost eller har missmatchat UPN.
		Get-ADGroupMember "Ekonomiavdelningen" | ForEach-Object {Set-DKUPN $_ -showOnlyErrors:$true}
	.PARAMETER userInput
		En eller flera användarobjekt eller sträng med sAMAccountName
	.PARAMETER showAll
		Visa all info
	.NOTES
		Funktionen kräver rättighet att ändra använaruppgifter i Active Directory. 
		RSAT måste vara installerad på datorn som kör skriptet.

		Author: David Krasowski - david.krasowski@gmail.com
	#>
    [cmdletbinding(SupportsShouldProcess=$True)]
    PARAM (
    [Parameter(ValueFromPipeLine = $true, Mandatory = $true, Position=0)]
    [array]$userInput,

	[Parameter(Position=1)]
    [switch]$showAll = $false
    )

    foreach ($user in $userInput)
    {
			# Ta bort eventuella mellanslag före och efter om inmatningen är en sträng
			if ($userInput.GetType() -eq "String")
			{
				$user = $user.Trim()
			}
			# Nolla användarobjektet just-in-case
			$objUser = $null
			# Kolla om inmatningen är en sAMAccountName eller UPN och hantera därefter
			if ($user -match '\w+@\w+\.\w+')
			{
				# Sök användaren i AD:et - inget objekt returneras om användaren inte finns
				$objUser = Get-ADUser -Filter {userPrincipalName -eq $user} -Properties emailAddress, `
				msRTCSIP-PrimaryUserAddress, targetAddress, proxyAddresses, userPrincipalName
			}
			else
			{
				# Testa om användaren finns
				try
				{
					$objUser = Get-ADUser -Identity $user -Properties emailAddress, `
					msRTCSIP-PrimaryUserAddress, targetAddress, proxyAddresses
				}
				# Fånga felet om användaren saknas i AD:et
				catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
			}

        if ($objUser.emailAddress -ne $null)
        {
            if ($objUser.emailAddress -eq $objUser.userPrincipalName)
            {
                if ($showAll)
				{
					Write-Host "Användaren" $objUser.name / $objUser.userPrincipalName "har korrekt UPN" -ForegroundColor Green
				}
            }
            else
            {
                Write-Host "Användaren" $objUser.name "har mismatchad UPN. Sätter UPN till" $objUser.emailAddress -ForegroundColor Yellow

                Set-ADUser $objUser -UserPrincipalName $objUser.emailAddress
            }
        }
        else
        {
            Write-Host "Användaren" $objUser.name "saknar epostadress" -ForegroundColor Red
        }
    }
}