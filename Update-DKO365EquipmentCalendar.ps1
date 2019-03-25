function Update-DKO365EquipmentCalendar
{
	<#
	.SYNOPSIS
		Ställer in standardinställningar på en Exchange Online-kalender
	.DESCRIPTION
		Funktionen Update-UK365EquipmentCalendar tar emot ett eller flera konton
		för en Exchange Online-kalender och sätter sedan ett uppsättning av standardvärden
		på kalendern.
	.EXAMPLE
		Update-DKO365EquipmentCalendar room001
	.PARAMETER name
		En eller flera användarobjekt eller sträng med sAMAccountName
	.NOTES
		Funktionen kräver rättighet i Office 365. 

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
