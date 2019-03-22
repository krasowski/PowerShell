function Set-DKEXOCalendarReviewer
{
	<#	
		Måste köras från EXO-PowerShell
		Author: David Krasowski - david.krasowski@gmail.com
	#>

    [cmdletbinding(SupportsShouldProcess=$True)]
    PARAM (
    [Parameter(ValueFromPipeLine = $true,
		Position=0)]
    [array]$userInput,
    [Parameter(Mandatory = $false,
		Position=1)]
	[string]$reviewer = "NetwiseSync"

	)

    foreach ($user in $userInput)
    {
        
        # Rensa objekt
        $objUser = $null

        # Kolla om inmatningen är en sAMAccountName eller UPN och hantera därefter
        if ($user -match '\w+@\w+\.\w+')
        {
            # Sök användaren i AD:et - inget objekt returneras om användaren inte finns
            $objUser = Get-ADUser -Filter {UserPrincipalName -eq $user}
        }
        else
        {
            # Testa om användaren finns
            try
            {
                $objUser = Get-ADUser -Identity $user
            }
            # Fånga felet om användaren saknas i AD:et
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {}
        }

        # Ändra behörigheter endast om användaren finns
        if ($objUser)
        {
			# Hitta användarens kalender
			$mailboxCalendar = Get-MailboxFolderStatistics $objUser.name |  where-object {$_.foldertype -eq "calendar"}

			$mailboxPath = $objUser.name + ":\" + $mailboxCalendar.name

			if ($mailboxCalendar)
			{
				try 
				{
					$Global:ErrorActionPreference = 'Stop' #Behövs för att fånga felet i en RemoteSession
					$currentPermissions = Get-MailboxFolderPermission $mailboxPath -user $reviewer -ErrorAction Stop
				}
				catch [System.Management.Automation.RemoteException] # Fånga felet i Get-MailboxFolderPermission
				{
					#Write-Output "Fångade: System.Management.Automation.RemoteException!"
					if ($error[0].CategoryInfo.Reason -eq "UserNotFoundInPermissionEntryException")
					{
						Write-Verbose "Användaren $($reviewer) hittades inte i behörighetslistan. Lägger till behörigheter"
						Add-MailboxFolderPermission -identity $mailboxPath -user $reviewer -AccessRights "Reviewer"
					}
				}
				finally {
					#H�mta r�ttigheter igen
					$currentPermissions = Get-MailboxFolderPermission $mailboxPath -user $reviewer -ErrorAction Stop
					if ($currentPermissions.AccessRights -ne "Reviewer")
					{
						Write-Verbose "Nuvarande rättigheter för användaren $($reviewer) är felaktiga ($("$currentPermissions.AccessRights")). Korrigerar."
						Set-MailboxFolderPermission -identity $mailboxPath -user $reviewer -AccessRights "Reviewer"
					}
					else
					{
						Write-Verbose "$($mailboxCalendar.Identity) : har korrekta behörigheter för användare $($reviewer)."
					}
				}
			}
        }
        else
        {
            Write-Verbose "Användaren" $user "Finns inte" -ForegroundColor Red
        }
    }
}