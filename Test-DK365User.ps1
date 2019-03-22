function Test-DK365User 
{
	<#
	.SYNOPSIS
		Kontrollerar om användarens msRTCSIP-PrimaryUserAddress, targetAddress och proxyAddresser är korrekta
	.DESCRIPTION
		Kontrollerar om användarens msRTCSIP-PrimaryUserAddress, targetAddress och proxyAddresser är korrekta.
		UPN måste matcha epostadressen och sip-adressen måste matcha UPN
	.EXAMPLE
		Kontrollera användare utifrån sAMAccountName:

		Test-DK365User anvid
	.EXAMPLE
		Kontrollera användare utifrån UPN:

		Test-DK365User agneta@example.com
	.EXAMPLE
		Kontrollera användare utifrån en textfil:

		$lista = Get-Content .\lista.txt
		Test-DK365User lista.txt
	.EXAMPLE
		Kontrollera användare utifrån en textfil, filtrera på användare som inte uppfyller kraven och
	    presentera resultatet som en lista med användarnamn, UPN, och 365_OK - status.

	   $lista = Get-Content .\lista.txt 
	   Test-DK365User $lista | Where-Object {$_."365_Ready" -eq $false} | Format-Table name, userPrincipalName, 365_Ready
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

			if ($objUser) # Kör bara om användarobjektet hittas
			{
				# Testa targetAddress - ersätt adress med korrekt för din domän
				$correctTargetAddress = "SMTP:" + $objUser.sAMAccountName + "@example.com"
				switch ($objUser.targetAddress)
				{
					"$($null)" {
						Write-Verbose "$($objUser.name) : Användarens brevlåda är inte migrerad till Office 365" 
						$targetAddressCorrect = $true }
					"$($correctTargetAddress)" { 
						Write-Verbose "$($objUser.name) : Användarens brevlåda finns i Office 365 och är korrekt"
						$targetAddressCorrect = $true }
					default { 
						Write-Verbose "$($objUser.name) : Användaren har inkorrekt targetAdress: $($objUser.targetAddress)"
						$targetAddressCorrect = $false }
				}

				<# Kolla förekomster av gamla adresser. Ange dina egna domäner i koden nedan #>
				$proxyAddressesCorrect = $false
				$correctProxyAddress = "smtp:" + $objUser.sAMAccountName + "@correctdomain.com"
				Write-Verbose "$($objUser.name) : Användarens korrekta smtpadress är $($correctProxyAddress)"
				switch -Wildcard ($objUser.ProxyAddresses)
				{
					"*@old.exampledomain.com" { 
						Write-Verbose "$($objUser.name) : Gammalt *@old.exampledomain.comm adress funnen"
						$proxyAddressesCorrect = $false }
					"*wrongdomain.com" { 
						Write-Verbose "$($objUser.name) : Gammalt *@wrongdomain.com adress funnen"
						$proxyAddressesCorrect = $false }
					"$($correctProxyAddress)" { 
						Write-Verbose "$($objUser.name) : Användaren har korrekt proxyAddress"
						$proxyAddressesCorrect = $true }
				}

				# Kolla om UPN är korrekt
				switch ($objUser.emailAddress)
				{
					"$($null)" {
						Write-Verbose "$($objUser.name) : saknar epostadress" 
						$UPNCorrect = $false }
					"$($objUser.userPrincipalName)" {
						Write-Verbose "$($objUser.name) : har korrekt UPN"
						$UPNCorrect = $true }
					default {
						Write-Verbose "$($objUser.name) : har mismatchad UPN"
						$UPNCorrect = $false }
				}
			
				<# Kolla om sip-adressen är korrekt. Adress som är samma som UPN eller tom adress
				   betraktas som korrekt #>
				switch ($objUser.'msRTCSIP-PrimaryUserAddress')
				{
					"$($null)" {
						Write-Verbose "$($objUser.name) : saknar sip-adress i AD"
						$SIPCorrect = $true }
					"sip:$($objUser.userPrincipalName)" {
						Write-Verbose "$($objUser.name) : har korrekt sip-adress"
						$SIPCorrect = $true }
					default {
						Write-Verbose "$($objUser.name) : har mismatchad sip-adress"
						$SIPCorrect = $false }
				}

				# Aggregera alla tester till en variabel
				if ($UPNCorrect -and $proxyAddressesCorrect -and $targetAddressCorrect -and $SIPCorrect) 
				{
					$365Ready = $true
				}
				else
				{
					$365Ready = $false
				}

				# Skapa attribut för objektet
				$objProperties = [ordered]@{'name'=$objUser.sAMAccountName;
											'userPrincipalName'=$objUser.userPrincipalName;
											'365_Ready'=$365Ready;
											'UPN_OK'=$UPNCorrect;
											'proxyAddressOK'=$proxyAddressesCorrect;
											'TargetAddressOK'=$targetAddressCorrect;
											'SIP_OK'=$SIPCorrect
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