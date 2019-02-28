function Set-DKUPN
{
	<#
	.SYNOPSIS
		S�tter om anv�ndarens User Principal Name till samma som epostadress
	.DESCRIPTION
		Funktionen Set-DKUPN tar emot ett eller flera anv�ndarid f�r en AD-anv�ndare 
		och s�tter sedan om UPN till samma v�rde som epostadressen.
	.EXAMPLE
		S�tt om UPN f�r anv�ndare kiltro
		Set-DKUPN kiltro
	.EXAMPLE
		S�tt om UPN f�r en hel AD-grupp. Visa endast rader f�r anv�ndare som saknar
		epost eller har missmatchat UPN.
		Get-ADGroupMember "Ekonomiavdelningen" | ForEach-Object {Set-DKUPN $_ -showOnlyErrors:$true}
	.PARAMETER userInput
		En eller flera anv�ndarobjekt eller str�ng med sAMAccountName
	.PARAMETER showAll
		Visa all info
	.NOTES
		Funktionen kr�ver r�ttighet att �ndra anv�naruppgifter i Active Directory. 
		RSAT m�ste vara installerad p� datorn som k�r skriptet.

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
			# Ta bort eventuella mellanslag f�re och efter om inmatningen �r en str�ng
			if ($userInput.GetType() -eq "String")
			{
				$user = $user.Trim()
			}
			# Nolla anv�ndarobjektet just-in-case
			$objUser = $null
			# Kolla om inmatningen �r en sAMAccountName eller UPN och hantera d�refter
			if ($user -match '\w+@\w+\.\w+')
			{
				# S�k anv�ndaren i AD:et - inget objekt returneras om anv�ndaren inte finns
				$objUser = Get-ADUser -Filter {userPrincipalName -eq $user} -Properties emailAddress, `
				msRTCSIP-PrimaryUserAddress, targetAddress, proxyAddresses, userPrincipalName
			}
			else
			{
				# Testa om anv�ndaren finns
				try
				{
					$objUser = Get-ADUser -Identity $user -Properties emailAddress, `
					msRTCSIP-PrimaryUserAddress, targetAddress, proxyAddresses
				}
				# F�nga felet om anv�ndaren saknas i AD:et
				catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
			}

        if ($objUser.emailAddress -ne $null)
        {
            if ($objUser.emailAddress -eq $objUser.userPrincipalName)
            {
                if ($showAll)
				{
					Write-Host "Anv�ndaren" $objUser.name / $objUser.userPrincipalName "har korrekt UPN" -ForegroundColor Green
				}
            }
            else
            {
                Write-Host "Anv�ndaren" $objUser.name "har mismatchad UPN. S�tter UPN till" $objUser.emailAddress -ForegroundColor Yellow

                Set-ADUser $objUser -UserPrincipalName $objUser.emailAddress
            }
        }
        else
        {
            Write-Host "Anv�ndaren" $objUser.name "saknar epostadress" -ForegroundColor Red
        }
    }
}