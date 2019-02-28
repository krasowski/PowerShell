function Update-DKO365EquipmentCalendar
{
	<#
	.SYNOPSIS
		St�ller in standardinst�llningar p� en Exchange Online-kalender
	.DESCRIPTION
		Funktionen Update-UK365EquipmentCalendar tar emot ett eller flera konton
		f�r en Exchange Online-kalender och s�tter sedan ett upps�ttning av standardv�rden
		p� kalendern.
	.EXAMPLE
		Update-DKO365EquipmentCalendar rkalit001
	.PARAMETER name
		En eller flera anv�ndarobjekt eller str�ng med sAMAccountName
	.NOTES
		Funktionen kr�ver r�ttighet i Office 365. 

		Author: David Krasowski - david.krasowski@gmail.com
	#>

	[cmdletbinding(SupportsShouldProcess=$True)]
    PARAM (
        [Parameter(ValueFromPipeLine = $true)]
        [array]$name
        )

	BEGIN {
		$CalendarProcessingDefaults = @{
			'AutomateProcessing'          = 'AutoAccept';
			'AllowConflicts'              = $False;
			'BookingWindowInDays'         = '365';
			'MaximumDurationInMinutes'    = '10080'; 
			'AllowRecurringMeetings'      = $True;
			'EnforceSchedulingHorizon'    = $True;
			'ScheduleOnlyDuringWorkHours' = $False;
			'ConflictPercentageAllowed'   = '0';
			'MaximumConflictInstances'    = '0';
			'ForwardRequestsToDelegates'  = $True;
			'DeleteAttachments'           = $True;
			'DeleteComments'              = $True;
			'RemovePrivateProperty'       = $True;
			'DeleteSubject'               = $False;
			'AddOrganizerToSubject'       = $True;
			'DeleteNonCalendarItems'      = $True;
			'TentativePendingApproval'    = $True;
			'EnableResponseDetails'       = $True;
			'OrganizerInfo'               = $True
			}
		$MailboxCalendarConfiguration = @{
			'WorkingHoursStartTime'      = '08:00:00';
			'WorkingHoursEndTime'        = '17:00:00';
			'WorkingHoursTimeZone'       = 'W. Europe Standard Time';
			'WeekStartDay'               = 'Monday'
		}
	}

	PROCESS {
			foreach ($calendar in $name)
			{
				Set-CalendarProcessing -Identity $calendar @CalendarProcessingDefaults
				Set-MailboxCalendarConfiguration -Identity $calendar @MailboxCalendarConfiguration
			}
	} #PROCESS

	END {}
}