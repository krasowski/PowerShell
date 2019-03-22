function Convert-DKtoASCIIString
{
	<#
	.SYNOPSIS
		Ersätter icke-ASCII-tecken från sträng
	.DESCRIPTION
		Funktionen ConvertTo-DKtoASCIIString tar emot en sträng och ersätter öäå och 
		liknande icke-ASCII-tecken med motsvarande latinska tecken. 
	.EXAMPLE
		Ta bort å, ä och ö från "Håkan Hällström":

		Convert-DKtoASCIIString "Håkan Hällström"
		Hakan Hallstrom
	.PARAMETER String
		En eller flera textsträng.
	.NOTES
		Author: David Krasowski - david.krasowski@gmail.com
	#>
    [cmdletbinding()]
    PARAM (
        [Parameter(ValueFromPipeLine = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Mandatory = $true)]
		[string[]]$strings
	)
	BEGIN {}
	PROCESS {
		foreach ($string in $strings)
		{
			$convertedString = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($string))

			$obj = New-Object -TypeName PSObject -Property @{'convertedString'=$convertedString}
			# Namnge objektet för att kunna skapa en Cutrom Formatting View
			$obj.psobject.typenames.insert(0,'DK.PSTools.UKASCIIString')
			Write-Output $obj
		}
	}
	END {}
}