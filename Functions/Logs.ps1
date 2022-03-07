<#
.SYNOPSIS
Gets various logs from an agent.

.DESCRIPTION
Log entry types include:
Agent Log                                       Agent Procedure Log
Alarms                                          Configuration Changes
Legacy Remote Control                           Monitor Actions
Network Stats                                   Remote Control
Event Log / Application                         Event Log / Directory Service
Event Log / DNS Server                          Event Log / Internet Explorer
Event Log / Security                            Event Log / System
Log Monitoring

.PARAMETER ComputerName
Get agent settings for this computer name filter.

.PARAMETER AgentID
Get agent settings for these agent ids.

.PARAMETER LogTypes
An array of log types to get from the specified agent.

.PARAMETER Before
Filter log entries before a certain date.

.PARAMETER After
Filter log entries after a certain date.

.PARAMETER Event
A specific event to get.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33825.htm

#>
Function Get-KLogs
{
    [CmdletBinding(DefaultParameterSetName="ByName")]
    Param(
        [Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
        [Parameter(Mandatory=$False)]
        [ValidateSet(
            "Agent", "AgentProcedure", "Alarms", "ConfigurationChanges",
            "LegacyRemoteControl", "MonitorActions", "NetworkStats",
            "RemoteControl", "EventLog/Application", "EventLog/DirectoryService",
            "EventLog/DnsServer", "EventLog/InternetExplorer", "EventLog/Security", "EventLog/System",
            "LogMonitoring")]
        [String[]]$LogTypes,

        [Parameter(Mandatory=$False)][DateTime]$Before,
        [Parameter(Mandatory=$False)][DateTime]$After,
        [Parameter(Mandatory=$False)][String]$ProcedureHistory,
        [Parameter(Mandatory=$False)][String]$Status
    )

	Begin
	{
		Ensure-Connected
	}

	Process
	{
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID -First 1
        }

        Foreach ($Log in $LogTypes)
        {
            $ParamHash = @{
                URI = "$VSA/assetmgmt/logs/$AgentID/$Log"
                Method 	= "GET"
                Headers = @{"Authorization" = "Bearer $Token"}
                Filters = @()
            }
            
            if ($Before) {
                $ParamHash.Filters = $ParamHash.Filters + "Time le DATETIME`'$(Format-Time -LongFormat -Time $Before)`'"
            }

            if ($After) {
                $ParamHash.Filters = $ParamHash.Filters + "Time ge DATETIME`'$(Format-Time -LongFormat -Time $After)`'"
            }

            if ($ProcedureHistory) {
                $ParamHash.Filters = $ParamHash.Filters + "substringof('$ProcedureHistory',ProcedureHistory)"
            }
            if ($Status) {
                $ParamHash.Filters = $ParamHash.Filters + "substringof('$Status',Status)"
            }

            Invoke-AdvancedRestMethod @ParamHash | Sort-Object Time -ErrorAction SilentlyContinue | Write-Output
        }
	}
}