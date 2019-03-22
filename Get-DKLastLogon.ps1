function Get-DKLastLogon
{
	<#
	.SYNOPSIS
	.DESCRIPTION
	.EXAMPLE
		$users = Get-ADUser -Filter {name -like "pad*"}
		Get-DKLastLogon $users | ft sAMAccountName, lastLogonDate
	.PARAMETER userInput
		En eller flera användare som sAMAccount eller userPrincipalName.
	.NOTES
	#>
    [cmdletbinding(SupportsShouldProcess=$True)]
    PARAM (
		[Parameter(ValueFromPipeLine = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Mandatory = $true,
				   Position=0)]
		[Alias('name','userPrincipalName')]
		[array]$userInput
    )

	BEGIN {
			# Definera alla properties vi måste plocka ut från användarkontot
			$userProperties = "lastLogonDate",
							  "msDS-LastFailedInteractiveLogonTime",
							  "msDS-LastSuccessfulInteractiveLogonTime"
	}

	PROCESS {

		foreach ($user in $userInput)
		{
			# Ta bort eventuella mellanslag före och efter om inmatningen är en sträng
			if ($user.GetType() -eq "String")
			{
				$user = $user.Trim()
			}
			# Nolla användarobjektet just-in-case
			$objUser = $null
			# Kolla om inmatningen är en sAMAccountName eller UPN och hantera därefter
			if ($user -match '\w+@\w+\.\w+')
			{
				# Sök användaren i AD:et - inget objekt returneras om användaren inte finns
				$objUser = Get-ADUser -Filter {userPrincipalName -eq $user} -Properties $userProperties
			}
			else
			{
				# Testa om användaren finns
				try
				{
					$objUser = Get-ADUser -Identity $user -Properties $userProperties
				}
				# Fånga felet om användaren saknas i AD:et
				catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
			}

			if ($objUser)
			{
				$lastFailedLogon      = [datetime]::FromFileTime($objUser.'msDS-LastFailedInteractiveLogonTime')
				$lastSuccessfullLogon = [datetime]::FromFileTime($objUser.'msDS-LastSuccessfulInteractiveLogonTime')
				$lastLogonDate        = $objUser.lastLogonDate

				#Write-Debug $objUser.'msDS-LastSuccessfulInteractiveLogonTime'
				#Write-Debug $objUser.'msDS-LastFailedInteractiveLogonTime'
				Write-Output $lastLogonDate

				# Skapa objekt
				$obj = New-Object PsObject -Property @{
					'DisplayName'          = $objUser.DisplayName
					'sAMAccountName'       = $objUser.name
					'userPrincipalName'    = $objUser.userPrincipalName
					'emailAddress'         = $objUser.emailAddress
					'description'          = $objUser.description
					'lastFailedLogon'      = $lastFailedLogon
					'lastSuccessfullLogon' = $lastSuccessfullLogon
					'lastLogonDate'        = $lastLogonDate
					}

				Write-Output $obj
			} # if objUser
		} #foreach manager
	} #Process

	END {}
} #Function