function Update-DKSipAddress 
{
	<#
	.SYNOPSIS
		Kontrollerar användarens msRTCSIP-PrimaryUserAddress
	.DESCRIPTION
		Kontrollerar om användarens msRTCSIP-PrimaryUserAddress matchar UPN.
		Korrigerar vid behov.
	.EXAMPLE
		Kontrollera användare utifrån sAMAccountName:

		Update-UKSipAddress anvid
	.EXAMPLE
		Kontrollera användare utifrån UPN:

		Update-UKSipAddress agneta@example.com
	.EXAMPLE
		Kontrollera användare utifrån en textfil:

		$lista = Get-Content .\lista.txt
		Update-DKSipAddress lista.txt
	.PARAMETER userInput
		En eller flera användarID (sAMAccountName), användarobjekt eller userPrincipalName
	.NOTES
		Author: David Krasowski - david.krasowski@gmail.se
	#>

    [cmdletbinding(SupportsShouldProcess=$True)]
    PARAM (
        [Parameter(ValueFromPipeLine = $true, Mandatory = $true, Position=0)]
        [array]$userInput,

		[Parameter(Position=1)]
        [bool]$showOnlyErrors
        )

    foreach ($user in $userInput)
    {
        # Ta bort eventuella mellanslag före och efter
        $user = $user.Trim()		
		# Nolla användarobjektet just-in-case
		$objUser = $null
        # Kolla om inmatningen är en sAMAccountName eller UPN och hantera därefter
        if ($user -match '\w+@\w+\.\w+')
        {
            # Säk användaren i AD:et - inget objekt returneras om användaren inte finns
            $objUser = Get-ADUser -Filter {userPrincipalName -eq $user} -Properties emailAddress, `
			msRTCSIP-PrimaryUserAddress, userPrincipalName
        }
        else
        {
            # Testa om användaren finns
            try
            {
                $objUser = Get-ADUser -Identity $user -Properties emailAddress, `
				msRTCSIP-PrimaryUserAddress
            }
            # Fånga felet om användaren saknas i AD:et
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
        }

		# Kolla om sip-adressen är korrekt
        if ($objUser.'msRTCSIP-PrimaryUserAddress' -ne $null)
        {
			$strCorrectSipAddress = "sip:" + $objUser.userPrincipalName
            if ($objUser.'msRTCSIP-PrimaryUserAddress' -eq $strCorrectSipAddress )
            {
                if (!$showOnlyErrors)
				{
					Write-Host $objUser.name ": har korrekt sip-adress" -ForegroundColor Green
				}
            }
            else
            {
				# Kontrollera om UPN matchar epostaddress
                if ($objUser.emailAddress -eq $objUser.userPrincipalName)
				{
					# Write-Host "Användaren" $objUser.name "har korrekt UPN" -ForegroundColor Green
					Write-Host $objUser.name ": Sätter sip-adress till" $strCorrectSipAddress -ForegroundColor Yellow
					Set-ADUser $objUser -replace @{'msRTCSIP-PrimaryUserAddress' = $strCorrectSipAddress}

				}
				else
				{
					Write-Host "Användaren" $objUser.name "har mismatchad UPN. Sätter UPN till" $objUser.emailAddress -ForegroundColor Red
				}

				
				
				Write-Host $objUser.name ": har mismatchad sip-adress." -ForegroundColor Red
				# Kontrollera om UPN matchar epost-adress

            }
        }
        else
        {
            if (!$showOnlyErrors)
			{
				Write-Host $objUser.name ": saknar sip-adress i AD" -ForegroundColor Yellow
			}
        }
	}
}