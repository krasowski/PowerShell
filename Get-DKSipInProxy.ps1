function Get-DKSipInProxy 
{
	<#
	.SYNOPSIS
		Kontrollerar
	.DESCRIPTION
		Kontrollerar om användarens 
	.EXAMPLE
		Kontrollera användare utifrån sAMAccountName:

		Get-DKSipInProxy anvid
	.EXAMPLE
		Kontrollera användare utifrån UPN:

		Get-DKSipInProxy agneta@example.com
	.EXAMPLE
		Kontrollera användare utifrån en textfil:

		$lista = Get-Content .\lista.txt
		Get-DKSipInProxy lista.txt
	.EXAMPLE
		Kontrollera användare utifrån en textfil, filtrera på användare som inte uppfyller kraven och
	    presentera resultatet som en lista med användarnamn, UPN, och 365_OK - status.

	   $lista = Get-Content .\lista.txt 
	   Get-DKSipInProxy $lista | Where-Object {$_."365_Ready" -eq $false} | Format-Table name, userPrincipalName, 365_Ready
	.PARAMETER userInput
		En eller flera användarID (sAMAccountName), användarobjekt eller userPrincipalName
	.NOTES
		Author: David Krasowski - david.krasowski@gmail.com
	#>

	[CmdletBinding()]
    PARAM (
        [Parameter(ValueFromPipeLine = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Mandatory = $true,
				   Position=0)]
        [array]$userInput
        )

	BEGIN {}

	PROCESS {

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
				$objUser = Get-ADUser -Filter {userPrincipalName -eq $user} -Properties proxyAddresses, userPrincipalName
			}
			else
			{
				# Testa om användaren finns
				try
				{
					$objUser = Get-ADUser -Identity $user -Properties proxyAddresses
				}
				# Fånga felet om användaren saknas i AD:et
				catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
			}

			if ($objUser) # Kör bara om användarobjektet hittas
			{
				<# Kolla förekomster av SIP-adresser.#>
				$SIPproxyAddressFound = $false
				switch -Wildcard ($objUser.ProxyAddresses)
				{
					"SIP*" { 
						Write-Verbose "$($objUser.name) : SIP-adress funnen"
						$SIPproxyAddressFound = $true }
					#default { 
					#	Write-Verbose "$($objUser.name) : Användaren har korrekt proxyAddress"
					#	$SIPproxyAddressFound = $false }
				}

				# Skapa attribut för objektet
				$objProperties = [ordered]@{'name'                =$objUser.sAMAccountName;
											'userPrincipalName'   =$objUser.userPrincipalName;
											'SIPproxyAddressFound'=$SIPproxyAddressFound;
											}

				# Skapa objektet
				$obj = New-Object -TypeName PSObject -Property $objProperties
				# Namnge objektet för att kunna skapa en Custom Formatting View
				$obj.psobject.typenames.insert(0,'DK.PSTools.DK365User')

				Write-Output $obj
			}

		} #foreach

	} #PROCESS

	END {}
}