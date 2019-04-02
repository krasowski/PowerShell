function Get-DKSipInProxy 
{
	<#
	.SYNOPSIS
		Kontrollerar
	.DESCRIPTION
		Kontrollerar om anv�ndarens 
	.EXAMPLE
		Kontrollera anv�ndare utifr�n sAMAccountName:

		Get-DKSipInProxy anvid
	.EXAMPLE
		Kontrollera anv�ndare utifr�n UPN:

		Get-DKSipInProxy agneta@example.com
	.EXAMPLE
		Kontrollera anv�ndare utifr�n en textfil:

		$lista = Get-Content .\lista.txt
		Get-DKSipInProxy lista.txt
	.EXAMPLE
		Kontrollera anv�ndare utifr�n en textfil, filtrera p� anv�ndare som inte uppfyller kraven och
	    presentera resultatet som en lista med anv�ndarnamn, UPN, och 365_OK - status.

	   $lista = Get-Content .\lista.txt 
	   Get-DKSipInProxy $lista | Where-Object {$_."365_Ready" -eq $false} | Format-Table name, userPrincipalName, 365_Ready
	.PARAMETER userInput
		En eller flera anv�ndarID (sAMAccountName), anv�ndarobjekt eller userPrincipalName
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
				$objUser = Get-ADUser -Filter {userPrincipalName -eq $user} -Properties proxyAddresses, userPrincipalName
			}
			else
			{
				# Testa om anv�ndaren finns
				try
				{
					$objUser = Get-ADUser -Identity $user -Properties proxyAddresses
				}
				# F�nga felet om anv�ndaren saknas i AD:et
				catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
			}

			if ($objUser) # K�r bara om anv�ndarobjektet hittas
			{
				<# Kolla f�rekomster av SIP-adresser.#>
				$SIPproxyAddressFound = $false
				switch -Wildcard ($objUser.ProxyAddresses)
				{
					"SIP*" { 
						Write-Verbose "$($objUser.name) : SIP-adress funnen"
						$SIPproxyAddressFound = $true }
					#default { 
					#	Write-Verbose "$($objUser.name) : Anv�ndaren har korrekt proxyAddress"
					#	$SIPproxyAddressFound = $false }
				}

				# Skapa attribut f�r objektet
				$objProperties = [ordered]@{'name'                =$objUser.sAMAccountName;
											'userPrincipalName'   =$objUser.userPrincipalName;
											'SIPproxyAddressFound'=$SIPproxyAddressFound;
											}

				# Skapa objektet
				$obj = New-Object -TypeName PSObject -Property $objProperties
				# Namnge objektet f�r att kunna skapa en Custom Formatting View
				$obj.psobject.typenames.insert(0,'DK.PSTools.DK365User')

				Write-Output $obj
			}

		} #foreach

	} #PROCESS

	END {}
}