<#
.SYNOPSIS
Get's a list of alarms.

.PARAMETER AlarmId
Only get alarm details for a specific alarm.

.PARAMETER SortBy
Sort the resulting entries by an alarm property.

.EXAMPLE
# Clear all alarms
Get-KAlarms | Remove-KAlarm -Force

.LINK
Remove-KAlarm
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38512.htm
#>
Function Get-KAlarms
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)][String]$AlarmId,
		[Parameter(Mandatory=$False)][String]$SortBy
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI 	= "$VSA/assetmgmt/alarms/$(if ($AlarmId) {$AlarmId} else {"true"})"
            Method 	= "GET"
            Headers = @{ "Authorization" = "Bearer $Token" }
            SortBy = $SortBy
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}
<#
.SYNOPSIS
Removes a selection of alarms.

.PARAMETER AlarmId
The alarm id for the alarm to remove.

.PARAMETER Reason
The reason specified for closing the alarm.

.PARAMETER Force
Bypasses the confirmation prompts.

.EXAMPLE
# Clear all alarms.
Get-KAlarms | Remove-KAlarm -Force

.LINK
Get-KAlarms
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38511.htm
#>
Function Remove-KAlarm
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName)][String[]]$AlarmId,
        [Parameter(Mandatory=$False)][String]$Reason = "Acknowledged.",
        [Parameter(Mandatory = $False)][Switch]$Force
    )
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI 	= ""
            Method 	= "PUT"
            Headers = @{"Authorization" = "Bearer $Token"}
            Body = "[
                {
                `"key`": `"notes`",
                `"value`": `"$Reason`"
                }
            ]"
            ContentType = "application/json"
        }

        foreach ($Id in $AlarmId)
        {
            $ParamHash.URI = "$VSA/assetmgmt/alarms/$Id/close"
            
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Remove alarm $Id ?")) {
                    throw "Operation canceled by user."
                }
            }

            Invoke-RestMethod @ParamHash | Write-Output
        }
	}
}

