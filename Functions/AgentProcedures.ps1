<#
.SYNOPSIS
	Gets a list of agent procedures matching specified filters. You can specify any of either a ProcedureName,
	ProcedurePath, or Scope. Each parameter is NOT its separate parameter set, so you can specify any number of
	combinations. When querying the K API, the values of these parameters are included in the query filter. That
	means that the more precise you are in specifying the name,path, or scope, the quicker the results will be downloaded.
	By offloading the Selection to K, we can ensure that we won't have to spend time and resources downloaded procedures that
	will just end up being thrown away and not used.
	Often used in conjunction with Run-KAgentProcedure. In fact, if you wanted to cause some major havoc, just run this:
	              Get-KAgentProcedure | Run-KAgentProcedure -ComputerName ""

	I'm sure you don't need to guess about what that will do... There are built-in roadblocks that will prevent you from accidentally
	doing this, but that's discussed in the help file for Run-KAgentProcedure. Just know that running Get-KAgentProcedure without
	limiting the scope of the search will get TONS of procedures.

.PARAMETER AgentProcedureId
	Specifies the ID of the procedure you want to get. You must specify the full procedure id, no substrings are allowed.

.PARAMETER AgentProcedureName
	Specifies the partial name of the procedure's name. Can simply be 'Get', and that will return all procedures that have Get in the name.
	Asterisks are not supported as wildcard characters; assume that the wildcards are on both sides of the name you specify.
	The K query filter that is applied here is: ?$filter=substringof('$ProcedureName',AgentProcedureName)"

.PARAMETER AgentProcedurePath
	Specifies the partial name of the procedure's path. Can simply be 'zach', and that will return all procedures that have zach in the path; this
	can be used to determine all the scripts that original in zach's private folder.
	Asterisks are not supported as wildcard characters; assume that the wildcards are on both sides of the path you specify.
	The K query filter that is applied here is: ?$filter=substringof('$ProcedurePath',Path)"

.PARAMETER Scope
	Specifies the scope of the script; whether it is publicly accessible or if it's a private script. Wildcards and partial names are not supported,
	the parameter is validated to a set of either Shared or Private.
	The K query filter that is applied here is: ?$filter=startswith(Path,'$Scope')"

.EXAMPLE
	Get-KAgentProcedure
	# Gets a list of every agent procedure. 

.EXAMPLE
	Get-KAgentProcedure -ProcedureName "Upgrade to WinX-2004"
	# Gets a Windows 10 update procedure

.EXAMPLE 
	Get-KAgentsInAgentViews -ViewDefName "OS - Windows 10 - 1803" | Foreach-Object {
		Start-KAgentProcedure -AgentProcedureName "Upgrade to WinX-2004" -AgentID $_.AgentID -DistributionInterval Hours -DistributionMagnitude 8
	}
	# Upgrades all Windows 10 1803 computers to 2004. Distributes the script across the next 8 hours.

#>
Function Get-KAgentProcedure
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $True, ParameterSetName = "ByID")]
		[String]$AgentProcedureID,

		[Parameter(Mandatory = $False, Position=1, ParameterSetName = "ByName")]
		[String]$AgentProcedureName = "",

		[Parameter(Mandatory = $False, ParameterSetName = "ByName")]
		[String]$AgentProcedurePath = "",

		[Parameter(Mandatory = $False, ParameterSetName = "ByName")]
		[ValidateSet("Shared", "Private", "")]
		[String]$Scope = "Shared"
	)
	Begin
	{
		Ensure-Connected
	}
	Process
	{
		$ParamHash = @{
			URI 	= "$VSA/automation/agentprocs"
			Method 	= "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
			Filters = @("substringof('$AgentProcedureName',AgentProcedureName)",
						"substringof('$AgentProcedurePath',Path)",

						# Yes, that is backwards. Trust me, it works.
						"startswith(Path, '$Scope')")
		}

		if ($PSCmdlet.ParameterSetName -like "ByID") {
			$ParamHash.Filters = $ParamHash.Filters + "AgentProcedureId eq $($AgentProcedureID)M"
		}

		Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="FullPath"; E={"$($_.Path)/$($_.AgentProcedureName)"}} | Write-Output
	}
}
<#
.SYNOPSIS
Gets the agent procedure history on a specific agent. It does not include scripts that are scheduled, it only includes scripts that have
finished running. 

.PARAMETER AgentID
	The ID of the agent that you want to get the history of.

.PARAMETER ComputerName
	The name of the computer that you want to get the history of.

.PARAMETER AgentProcedureName
	When specified, only includes the history of this specific procedure.

.PARAMETER Status
	When specified, only includes procedures with a specific status.

.PARAMETER Admin
	When specified, only includes procedures ran by this admin.

.PARAMETER Before
	Only include entries before a specific date.

.PARAMETER After
	Only include entries after a specific date.

.EXAMPLE
	Get-KAgentProcedureHistory -ComputerName "" -AgentProcedureName "iloveyou" -Admin "bob" | Select ScriptName, LastExecutionTime, Admin
	# Bob was a naughty admin and this shows all the computers that he has hacked and when.

.LINK
	Get-KAgentProcedure
	http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33679.htm
#>

Function Get-KAgentProcedureHistory
{
	[CmdletBinding(DefaultParameterSetName="ById")]
	Param(
		[Parameter(Mandatory=$True, ParameterSetName="ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
		[Parameter(Mandatory=$True, Position = 1, ParameterSetName="ByName")][AllowEmptyString()][String]$ComputerName,
		[Parameter(Mandatory=$False)][String]$AgentProcedureName = "",
		[Parameter(Mandatory=$False)][ValidateSet("Success", "Failed", "")][String]$Status = "",
		[Parameter(Mandatory=$False)][String]$Admin = "",
		[Parameter(Mandatory=$False)]
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KAgentProcedureHistory]::GetSortableParameters([KAgentProcedureHistory]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KAgentProcedureHistory]::GetSortableParameters([KAgentProcedureHistory]).Name
			}
		)]
		[String]$SortBy = "LastExecutionTime",
		[Parameter(Mandatory=$False)][Datetime]$Before,
		[Parameter(Mandatory=$False)][DateTime]$After
	)

	Begin
	{
		Ensure-Connected
	}

	Process
	{
		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		$ParamHash = @{
			URI     = ""
			Method 	= "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
			Filters = @(
				"substringof('$AgentProcedureName',ScriptName)",
				"substringof('$Admin',Admin)",
				"substringof('$Status',Status)"

			)
			SortBy = $SortBy
		}

		if ($Before) {
			$ParamHash.Filters = $ParamHash.Filters + "LastExecutionTime le DATETIME'$(Format-Time $Before -LongFormat)'"
		}

		if ($After) {
			$ParamHash.Filters = $ParamHash.Filters + "LastExecutionTime ge DATETIME'$(Format-Time $After -LongFormat)'"
		}

		Foreach ($ID in $AgentID) {
			$ParamHash["URI"] = "$VSA/automation/agentprocs/$ID/history"
			(Invoke-AdvancedRestMethod @ParamHash) | Select-Object *, @{N = "AgentID"; E = {$ID}} | Write-Output
		}
	}
}
<#
.SYNOPSIS
Gets the current ask "Ask Before Running" setting. Returns boolean.

.LINK
Set-KAskBeforeRunningSetting
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33687.htm

#>

Function Get-KAskBeforeRunningSetting
{
	Begin
	{
		Ensure-Connected
	}
	Process
	{

		$ParamHash = @{
			URI       =  "$VSA/automation/agentprocs/quicklaunch/askbeforeexecuting"
			Method    =  "GET"
			Headers   =  @{ "Authorization" = "Bearer $Token" }
		}
	
		Invoke-RestMethod @ParamHash | Select-Object -Expand Result | Write-Output
	}
}

<#
.SYNOPSIS
Gets the list of quick launch procedures.

.LINK
Update-KQuickLaunchProcedure
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33683.htm
#>
Function Get-KQuickLaunchProcedures
{
	Begin
	{
		Ensure-Connected
	}
	Process
	{
		$ParamHash = @{
			URI = "$VSA/automation/agentprocs/quicklaunch"
			Method = "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
		}
		Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Gets a list of procedures that are scheduled to run on an Agent. 

.PARAMETER ComputerName
The computer name of the agent that you want to get the scheduled procedures for.

.PARAMETER AgentId
The agent Ids you want to get the scheduled procedures for. This is what's used when piping the results of Get-KAgents.

.PARAMETER AgentProcedureID
Optionally, specify to only include a specific agent procedure.

.EXAMPLE
# Using the parameters
Get-KScheduledAgentProcedures -ComputerName "IT-" -AgentProcedureId 123456789123456

.EXAMPLE
# Piping to supply the AgentIDs
Get-KAgents -ComputerName "IT-" | Get-KScheduledAgentProcedures

.EXAMPLE
# Piping to supply the AgentProcedureID. Gets a list of all laptops that have a scheduled backup.
Get-KAgentProcedure -AgentProcedureName "Scheduled Backup" | Get-KScheduledAgentProcedures -ComputerName "Laptop-"

.EXAMPLE
# Stops all scheduled instances of a specified script.
Get-KAgents | Get-KScheduledAgentProcedure -AgentProcedureName "Wipe SSD" | Stop-KAgentProcedure

.LINK
Get-KAgentProcedure
Get-KAgentProcedureHistory
Start-KAgentProcedure
Stop-KAgentProcedure
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31643.htm

#>
Function Get-KScheduledAgentProcedures
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
		[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName)][String]$AgentProcedureID = ""
	)

	Begin
	{
		Ensure-Connected
	}

	Process
	{
		$ParamHash = @{
			URI     = ""
			Method 	= "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
			Filters = @()
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		if ($AgentProcedureID) {
			$ParamHash.Filters = $ParamHash.Filters + "AgentProcedureId eq $($AgentProcedureID)M"
		}

		Foreach ($ID in $AgentID) {
			$ParamHash.URI = "$VSA/automation/agentprocs/$ID/scheduledprocs"
			(Invoke-AdvancedRestMethod @ParamHash) | Select-Object *, @{N = "AgentID"; E = {$ID}} | Write-Output
		}
	}
}

<#
.SYNOPSIS
Gets a list of all procedures exposed to the Kaseya portal.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37305.htm
#>
Function Get-KUserPortalProcedures
{
	Begin
	{
		Ensure-Connected
	}
	Process
	{
		$ParamHash = @{
			URI = "$VSA/automation/agentprocsportal"
			Method = "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
		}
		Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
	
}


<#
.SYNOPSIS
Executes a Powershell command on a remote computer.

.DESCRIPTION
This cmdlet relies on calling a Kaseya Agent Procedure called Invoke-PowerShell.
All this procedure does is take a psCode parameter and passes it to executePowershell.

.PARAMETER ComputerName
Get agents that include this in their computer name.

.PARAMETER AgentID
A list of agent IDs to get agent objects for.

.PARAMETER Code
The PowerShell scriptblock to run on the remote system.

.PARAMETER Wait
Wait for the powershell command to complete. Doesn't time out, it will wait infinitely, even if the computer is offline. 
Once the PowerShell has completed, this cmdlet will return the output of the script.

.PARAMETER AsJob
Creates this command as a job.

.PARAMETER Force
Bypasses the confirmation prompt.

#>


Function Invoke-KPowershell
{
	[CmdletBinding(DefaultParameterSetName="ById")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String]$AgentID,
        [Parameter(Mandatory=$True)][ScriptBlock]$Code,
        [Parameter(Mandatory=$False)][Switch]$Wait,
        [Parameter(Mandatory=$False)][Switch]$AsJob,
        [Parameter(Mandatory=$False)][Switch]$Force
    )
    Begin
    {
        Ensure-Connected
    }
    Process
    {
        if ($PSCmdlet.ParameterSetName -like "ByName")
        {
            if ($Wait.IsPresent)
            {
                Start-KAgentProcedure -ComputerName $ComputerName -AgentProcedureName "Execute-Powershell" -ScriptPrompts @{
                    Name = "psCode"
                    Value = $Code.ToString()
                } -Wait -Force:$Force | Out-Null
                
                Show-KDocument -ComputerName $ComputerName -FilePath "psoutput.txt" | Write-Output
            }
            elseif ($AsJob.IsPresent)
            {
                Start-KAgentProcedure -ComputerName $ComputerName -AgentProcedureName "Execute-Powershell" -ScriptPrompts @{
                    Name = "psCode"
                    Value = $Code.ToString()
                } -AsJob -Force:$Force | Write-Output
            }
            else {
                Start-KAgentProcedure -ComputerName $ComputerName -AgentProcedureName "Execute-Powershell" -ScriptPrompts @{
                    Name = "psCode"
                    Value = $Code.ToString()
                } -Force:$Force | Write-Output
            }
        }
        else {
            if ($Wait.IsPresent)
            {
                Start-KAgentProcedure -AgentID $AgentID -AgentProcedureName "Execute-Powershell" -ScriptPrompts @{
                    Name = "psCode"
                    Value = $Code.ToString()
                } -Force:$Force | Out-Null
                
                Show-KDocument -AgentID $AgentID -FilePath "psoutput.txt" | Write-Output
            }
            elseif ($AsJob.IsPresent)
            {
                Start-KAgentProcedure -AgentID $AgentID -AgentProcedureName "Execute-Powershell" -ScriptPrompts @{
                    Name = "psCode"
                    Value = $Code.ToString()
                } -AsJob -Force:$Force | Write-Output
            }
            else {
                Start-KAgentProcedure -AgentID $AgentID -AgentProcedureName "Execute-Powershell" -ScriptPrompts @{
                    Name = "psCode"
                    Value = $Code.ToString()
                } -Force:$Force | Write-Output
            }
        }
    }

    
}

<#
.SYNOPSIS
Removes a procedure from the quick launch menu.

.PARAMETER AgentProcedureId
The ID of the procedure to delete.

.PARAMETER AgentProcedureName
The name of the procedure to delete.

.LINK
Get-KQuickLaunchProcedures
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33685.htm
#>
Function Remove-KQuickLaunchProcedure
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByProcedureID")][String]$AgentProcedureID,
		[Parameter(Mandatory = $True, ParameterSetName = "ByProcedureName")][String]$AgentProcedureName
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{
		if ($PSCmdlet.ParameterSetName -like "ByProcedureName") {
			$AgentProcedureID = Get-KAgentProcedure -AgentProcedureName $AgentProcedureName | Select-Object -Expand AgentProcedureId
		}

		$ParamHash = @{
			URI       =  "$VSA/automation/agentprocs/quicklaunch/$AgentProcedureID"
			Method    =  "DELETE"
			Headers   =  @{ "Authorization" = "Bearer $Token" }
		}

		Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}	
}

<#
.SYNOPSIS
Sets the organization wide "Ask Before Running" setting for quick launch procedures.

.PARAMETER NewValue
The new value.

.LINK
Get-KAskBeforeRunningSetting
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33688.htm
#>
Function Set-KAskBeforeRunningSetting
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)][Bool]$NewValue
	)
	Begin
	{
		Ensure-Connected
	}
	Process
	{
		$ParamHash = @{
			URI       =  "$VSA/automation/agentprocs/quicklaunch/askbeforeexecuting"
			Method    =  "PUT"
			Headers   =  @{ 
				"Authorization" = "Bearer $Token" 
				"flag" = if ($NewValue) { "true" } else { "false" }
			}
		}
	
		Invoke-RestMethod @ParamHash | Select-Object -Expand Result | Write-Output
	}
}


<#
.SYNOPSIS
Runs an agent procedure on specified computers. Supports distribution, scheduling, and recurrence.

.PARAMETER AgentProcedureID
The ID of the procedure to run. 

.PARAMETER AgentProcedureName
The name of the procedure to run. If the name you provided matches to multiple procedures, 
the cmdlet with throw an exception.

.PARAMETER AgentID
An array of agent IDs to run the procedure on.

.PARAMETER ComputerName
The name of the computer to run the procedure on. Allows matching to multiple computers.

.PARAMETER SkipIfOffline
The procedure will not run if the computer is online. 
If specified with PowerUpIfOffline, it will first try to turn the computer on. If that fails. it skips.

.PARAMETER PowerUpIfOffline
K tries to send a WoL packet to the computer.
If specified with SkipIfOffline, it will first try to turn the computer on. If that fails. it skips.

.PARAMETER Scheduled
Specify to enable the Scheduling parameters. 

.PARAMETER Recurrence
Specify to enable the Recurrence parameters

.PARAMETER DistributionInterval
The unit of time to spread the execution out. Can be Minutes, Hours, or Days

.PARAMETER DistributionMagnitude
How many units of time will this procedure be spread out.

.PARAMETER ReadOnly
Don't run the script. Just write out what will happen.

.PARAMETER Force
If the module's confirm preference is set to True, Force will bypass the confirmation prompts.

.PARAMETER StartOn
The date this script will be scheduled to begin.

.PARAMETER ExcludeFrom
The date to begin an exclusion zone. A DateTime is specified, but this script only uses the hours and minutes.

.PARAMETER ExcludeTo
The date to end an exclusion zone. A DateTime is specified, but this script only uses the hours and minutes.

.PARAMETER RepeatInterval
The unit of time to spread the repeat for. Can be Never, Minutes, Hours, Days, Weeks, Months, or Years

.PARAMETER RepeatMagnitude
How many units of time will be in between repetitions.

.PARAMETER EndOn
The date that the recurrence ends.

.PARAMETER ScriptPrompts
Optional parameters to send to a procedure. Must be in this format:
@{
	Caption = "(Optional Caption)"
	Name = "Name of the parameter"
	Value = "What you supply the parameter"
}

.PARAMETER Wait
Waits for the agent procedure to finish before moving on.

.PARAMETER Callback
A script-block to execute once the procedure has finished executing. This code is ran on the current computer, not on the remote agent.
You can use the callback to run other Kaseya commands as well. This parameter is only used in conjunction with AsJob
Just be cautious of long jobs that extend past the token's validity period (30 minutes).

.PARAMETER AsJob
Creates and returns a job that waits for this script to finish executing.

.EXAMPLE
# Gets all laptop agents and runs a procedure that enabled L2TP. All of the following methods are allowed.

# Method 1: Passing agents via pipeline
Get-KAgents -ComputerName "Laptop-" | Start-KAgentProcedure -AgentProcedureName "Allow-L2TP" -PowerUpIfOffline

# Method 2: Passing Procedure via pipeline
Get-KAgentProcedure -AgentProcedureName "Allow-L2TP" | Start-KAgentProcedure -ComputerName "Laptop-" -PowerUpIfOffline

# Method 3: No pipeline
Start-KAgentProcedure -AgentProcedureName "Allow-L2TP" -ComputerName "Laptop-" -PowerUpIfOffline

.EXAMPLE
# Start a weekly hard drive repair procedure that doesn't run in between 8am and 5pm.
Get-KAgents | Start-KAgentProcedure -AgentProcedureName "Repair-SSD" -Recurrence -Scheduled `
	-RepeatInterval Weeks -RepeatMagnitude 1 -DistributionMagnitude 3 -DistributionInterval Hours `
	-ExcludeFrom (Get-Date -Hour 8) -ExcludeTo (Get-Date -Hour 17)

.EXAMPLE
# Executes a remote PowerShell command
Start-KAgentProcedure -ComputerName "IT-01" -AgentProcedureName "Execute-Powershell" -ScriptPrompts @{
	Name="psCode"
	Value = "Get-Process | Export-CSV C:\temp\processes.csv"
}

.LINK
Get-KAgentProcedure
Stop-KAgentProcedure
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31668.htm
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31766.htm
#>

Function Start-KAgentProcedure
{
	[CmdletBinding(DefaultParameterSetName = "ProcID")]
	Param (
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc1")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc2")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ProcID")]
		[String]$AgentProcedureID,


		[Parameter(Mandatory = $True, ParameterSetName = "proc3")]
		[Parameter(Mandatory = $True, ParameterSetName = "proc4")]
		[Parameter(Mandatory = $True, ParameterSetName = "ProcName")]
		[String]$AgentProcedureName,


		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc1")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc3")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "AgentID")]
		[String[]]$AgentID,


		[Parameter(Mandatory = $True, ParameterSetName = "proc2")]
		[Parameter(Mandatory = $True, ParameterSetName = "proc4")]
		[Parameter(Mandatory = $True, ParameterSetName = "ComputerName")]
		[String]$ComputerName,


		[Parameter(Mandatory = $False)][Switch]$SkipIfOffLine,
		[Parameter(Mandatory = $False)][Switch]$PowerUpIfOffline,


		[Parameter(Mandatory = $False)][Switch]$Scheduled,
		[Parameter(Mandatory = $False)][Switch]$Recurrence,


		[Parameter(Mandatory = $False, HelpMessage = "What unit of time do we use for our distribution. Example: Within 5 (Days)")]
		[ValidateSet("Minutes", "Hours", "Days")]
		[String]$DistributionInterval = "Minutes",


		[Parameter(Mandatory = $False, HelpMessage = "What's the magnitude of our distribution. Example: Within (5) Days")]
		[Int]$DistributionMagnitude = 1,


		[Parameter(Mandatory=$False)][System.Collections.IDictionary[]]$ScriptPrompts,

		[Parameter(Mandatory = $False)][Switch]$ReadOnly,
		[Parameter(Mandatory = $False)][Switch]$Force,


		[Parameter(Mandatory = $False)][Switch]$Wait,
		[Parameter(Mandatory = $False)][Switch]$AsJob
	)

	DynamicParam {
		$RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		if ($Scheduled) {
			$RuntimeParameterDictionary.Add("StartOn", `
			(New-DynamicParameter -Name "StartOn" -Type ([DateTime]) -HelpMessage "The day and time to run this script." -DefaultValue (Get-Date)))

			$RuntimeParameterDictionary.Add("ExcludeFrom", (New-DynamicParameter -Name "ExcludeFrom" -Type ([DateTime]) `
				-HelpMessage "The time to start an exclusion range. The date portion is ignored." -DefaultValue $NULL))


			$RuntimeParameterDictionary.Add("ExcludeTo", (New-DynamicParameter -Name "ExcludeTo" -Type ([DateTime]) `
				-HelpMessage "The time to end an exclusion range. The date portion is ignored." -DefaultValue $NULL))
		}


		if ($Recurrence) {
			$RuntimeParameterDictionary.Add("RepeatInterval", (New-DynamicParameter -Name "RepeatInterval" -Type ([String]) -ValidateSet @(
				"Never", "Minutes", "Hours", "Days", "Weeks", "Months", "Years"
			) -HelpMessage "What is the unit of time for our recurrence?" -DefaultValue "Never" -Mandatory))


			$RuntimeParameterDictionary.Add("RepeatMagnitude", (New-DynamicParameter -Name "RepeatMagnitude" -Type ([Int]) `
				-HelpMessage "How many times should we repeat" -DefaultValue 0 -Mandatory))


			$RuntimeParameterDictionary.Add("EndOn", (New-DynamicParameter -Name "EndOn" -Type ([DateTime]) -HelpMessage "When does our recurrence end."))
		}


		if ($AsJob.IsPresent) {
			$RuntimeParameterDictionary.Add("Callback", (New-DynamicParameter -Name "Callback" -Type ([ScriptBlock])))
		}

		return $RuntimeParameterDictionary
	}

	Begin
	{
		Ensure-Connected
	}
	
	Process
	{
		$Body  =  @{
			ServerTimeZone     =   $True
			SkipIfOffLine      =   [Bool]$SkipIfOffLine
			PowerUpIfOffLine   =   [Bool]$PowerUpIfOffline
			Distribution       =   @{
				Interval       =   $DistributionInterval
				Magnitude      =   $DistributionMagnitude
			}
		}


		if ($Recurrence) {
			$Body["Recurrence"] = @{
				Repeat = $PSBoundParameters.RepeatInterval
				Times = $PSBoundParameters.RepeatMagnitude
			}

			if ($PSBoundParameters.EndOn) {
				$Body["Recurrence"].EndOn = $(Format-Time $PSBoundParameters.EndOn -LongFormat)
			}
		}


		if ($Scheduled -and $PSBoundParameters.StartOn) {
			$Body["Start"] = @{
				StartOn = $(Format-Time $PSBoundParameters.StartOn -LongFormat)
			}
		}


		if ($PSBoundParameters.ExcludeFrom -and $PSBoundParameters.ExcludeTo) {
			$Body["Exclusion"] = @{
				From = $(Format-Time $PSBoundParameters.ExcludeFrom -ShortTimeFormat)
				To = $(Format-Time $PSBoundParameters.ExcludeTo -ShortTimeFormat)
			}
		}


		if ($ComputerName) {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID 
		}


		if ($AgentProcedureName) { 
			$Ids = Get-KAgentProcedure -AgentProcedureName $AgentProcedureName | Select-Object -Expand "AgentProcedureId"
			if ($Ids.Count -eq 1) {
				$AgentProcedureID = $Ids
			}
			else {
				throw "$agentProcedureName matches to $($Ids.Count) procedures. This is not allowed."
			}
		}

		if ($ScriptPrompts) {
			$Body["ScriptPrompts"] = $ScriptPrompts
		}


		$ParamHash = @{
			Method = "PUT"
			Body = $Body
			Headers = @{'Authorization' = "Bearer $Token"}
			ContentType = "application/json"
		}

		
		Foreach ($Id in $AgentId)
		{
			if ($ReadOnly) {
				[PSCustomObject]@{
					AgentID = $Id
					AgentProcedureID = $AgentProcedureID
					Body = [PSCustomObject]$Body
					ScriptPrompts = $ScriptPrompts
				} | Write-Output
			}
			else {
				if (!$DisableKConfirmations -and !$Force.IsPresent) {
					if ([String]::IsNullOrEmpty($AgentProcedureName)) {
						$AgentProcedureName = Get-KAgentProcedure -AgentProcedureId $AgentProcedureId | Select-Object -Expand AgentProcedureName
					}
					if ([String]::IsNullOrEmpty($AgentName)) {
						$AgentName = Get-KAgents -AgentId $Id | Select-Object -Expand ComputerName
					}
					if (!(Get-Confirmation -Message "Run procedure ($AgentProcedureName|$AgentProcedureId) on agent ($AgentName|$Id)?")) {
						throw "Operation canceled by user."
					}
				}
				
				#Executes the agent procedure.
				Invoke-AdvancedRestMethod -URI "$VSA/automation/agentprocs/$Id/$AgentProcedureID/schedule" @ParamHash
				
				# Wait until the script isn't running any more.
				if ($Wait.IsPresent) {
					do {
						Start-Sleep -Seconds 1
					} until (!(Get-KScheduledAgentProcedures -AgentId $Id | Where-Object {$_.AgentProcedureId -like "$AgentProcedureID"}))
				}

				elseif ($AsJob.IsPresent) {
					Start-Job -ScriptBlock {
						Param($ModuleDirectory, $Token, $AgentId, $AgentProcedureId, $Callback)
						. "$ModuleDirectory\PSk.ps1" | Out-Null

						$Script:Token = $Token

						do {
							Start-Sleep -Seconds 1
						} until (!(Get-KScheduledAgentProcedures -AgentId $AgentId | Where-Object {$_.AgentProcedureId -like "$AgentProcedureId"}))
						
						# Invoke our callback function if it's valid.
						if ($Callback) {
							([ScriptBlock]::Create($CallBack)).Invoke() | Write-Output
						}

					} -ArgumentList @($(Split-Path $PSScriptRoot), $Script:Token, $Id, $AgentProcedureID, $PSBoundParameters.Callback)
				}
			}
		}
	}
}


<#
.SYNOPSIS
Stops a procedure that's either scheduled or is currently running.

.PARAMETER AgentProcedureID
The agent procedure ID to stop

.PARMAETER AgentProcedureName
The name of the agent procedure to stop

.PARAMETER AgentID
The agent id to stop the procedure on.

.PARAMETER ComputerName
The computer name to stop the procedure on.
#>
Function Stop-KAgentProcedure
{
	[CmdletBinding(DefaultParameterSetName = "ProcID")]
	Param (
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc1")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc2")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ProcID")]
		[String]$AgentProcedureID,


		[Parameter(Mandatory = $True, ParameterSetName = "proc3")]
		[Parameter(Mandatory = $True, ParameterSetName = "proc4")]
		[Parameter(Mandatory = $True, ParameterSetName = "ProcName")]
		[String]$AgentProcedureName,


		[Parameter(Mandatory = $True, ParameterSetName = "proc1")]
		[Parameter(Mandatory = $True, ParameterSetName = "proc3")]
		[Parameter(Mandatory = $True, ParameterSetName = "AgentID")]
		[String]$AgentID,


		[Parameter(Mandatory = $True, ParameterSetName = "proc2")]
		[Parameter(Mandatory = $True, ParameterSetName = "proc4")]
		[Parameter(Mandatory = $True, ParameterSetName = "ComputerName")]
		[String]$ComputerName
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{
		if ($AgentProcedureName) {
			$Ids = Get-KAgentProcedure -AgentProcedureName $AgentProcedureName | Select-Object -Expand "AgentProcedureId"
			if ($Ids.Count -eq 1) {
				$AgentProcedureID = $Ids
			}
			else {
				throw "$agentProcedureName matches to $($Ids.Count) procedures. This is not allowed."
			}
		}
	
		$AgentIDs = @()
	
		if ($ComputerName) {
			$AgentIDs = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}
		else {
			$AgentIDs = $AgentID
		}
	
	
		$ParamHash = @{
			URI 	= "$VSA/automation/agentprocs"
			Method 	= "DELETE"
			Headers = @{ "Authorization" = "Bearer $Token" }
		}
	
		Foreach ($ID in $AgentIDs) {
			$ParamHash["URI"] = "$VSA/automation/agentprocs/$ID/$AgentProcedureID"
			(Invoke-AdvancedRestMethod @ParamHash) | Write-Output
		}
	}

}
