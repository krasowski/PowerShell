function Set-DKRDSCertificate
{
	<#
	.SYNOPSIS
		Funktionen binder nytt certifikat till Remote Desktop-lyssnaren
	.DESCRIPTION
		Funktionen Set-DKRDSCertificate tar första certitikatet från LocalMachine-storen
		som har Subject CN=[datornamn].* och binder det till Remote Desktop-lyssnaren 
	.EXAMPLE
		Uppdatera certifikat
		Set-DKRDSCertificate
	.NOTES
		Funktionen kräver administrativa rättighet på maskinen.

		Author: David Krasowski - david.krasowski@gmail.com
	#>
    [cmdletbinding(SupportsShouldProcess=$True)]

	# Hämta referens till konfigurationsinstansen
	$wmiTSGS = Get-WMIObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'"

	# Hämta tumavtryck på första certifikatet i datorns certifikatstore som har server.domän som Subject
	$certThumbprint = (Get-ChildItem -path cert:/LocalMachine/My | Where Subject -like CN=$env:computername* | select -first 1).thumbprint

	# Kör endast om certifikat hittas
	if($certThumbprint -ne $null)
	{
		# Uppdatera RD-inställningar med ny tumavtryck
		try
		{
			Set-WMIInstance -path $wmiTSGS.__path -argument @{SSLCertificateSHA1Hash="$certThumbprint"}
		}
		catch [System.UnauthorizedAccessException]
		{
			Write-Host "Du saknar rättigheter att utföra förändringen. Kör skriptet som administratör."
		}
	}
	else
	{
		Write-Host "Hittar inte lämpligt certifikat" 
	}
}