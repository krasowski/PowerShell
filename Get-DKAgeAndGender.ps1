function Get-DKAgeAndGender
{
	<#
	.SYNOPSIS
		Returnerar användarens ålder utifrån ett AD-attribut som lagrar personnummer
	.DESCRIPTION
		
	.EXAMPLE
		Get-AgeAndGender johsmith
	.EXAMPLE
		Get-AgeAndGender john.smith@domain.com
	.PARAMETER userInput
		Ett eller flera användarobjekt eller sträng med sAMAccountName
	.NOTES
		Author: David Krasowski - david.krasowski@gmail.com
	#>
   
	[cmdletbinding(SupportsShouldProcess=$True)]
    PARAM (
    [Parameter(ValueFromPipeLine = $true,
			   Position=0)]
    [array]$userInput,
	[Parameter(Mandatory = $true,
			   Position=1)]
    [string]$personnummerAttribute
	)

	BEGIN {
		$datePattern = 'yyyyMMdd'
	} #BEGIN

	PROCESS {

		foreach ($user in $userInput)
		{
        
			# Rensa objekt
			$objUser = $null

			# Kolla om inmatningen är en sAMAccountName eller UPN och hantera därefter
			if ($user -match '\w+@\w+\.\w+')
			{
				# S�k anv�ndaren i AD:et - inget objekt returneras om användaren inte finns
				$objUser = Get-ADUser -Filter {UserPrincipalName -eq $user} -Properties $personnummerAttribute
			}
			else
			{
				# Testa om användaren finns
				try
				{
					$objUser = Get-ADUser -Identity $user -Properties $personnummerAttribute
				}
				# Fånga felet om användaren saknas i AD:et
				catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
			}

			# Kör kod endast om användaren finns
			if ($objUser)
			{
				$personNummer = $objUser.$personnummerAttribute

				if ($personNummer -ne $null) {

					#Kolla ålder
					$birthday  = [DateTime]::ParseExact($personnummer.SubString(0,8), $datePattern, $null)

					$ageSpan   = [Datetime]::Now - $birthday
					$userAge   = New-Object DateTime -ArgumentList $ageSpan.Ticks
					$userYears = $userAge.Year -1

					#Kolla om man eller kvinna
					$genderNumber = $personNummer.Substring(10,1)
					if ($genderNumber % 2 -eq 0)
					{
						$userGender = 'F'
					}
					else
					{
						$userGender = 'M'
					}

					# Skapa objekt
					$obj = New-Object PsObject -Property @{
						'age'               = $userYears
						'gender'            = $userGender
						}

					Write-Output $obj

				}
			}
			else
			{
				#Användaren finns inte
			}
		}
	} #PROCESS

	END {}

}