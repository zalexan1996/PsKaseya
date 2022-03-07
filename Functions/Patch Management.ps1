<#
.SYNOPSIS
Returns an array of missing patches on an agent machine, with denied patches either included or excluded.

.PARAMETER ComputerName
Get patches for this computer name.

.PARAMETER AgentID
Get patches for these agents.

.PARAMETER HideDenied
Hide patches that are explicitly denied. The list would then only include patches that need to be installed but haven't been.

.PARAMETER KBArticleID
Filter patches by KB.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KPatch] with the [Sortable] attribute

.LINK
Get-KPatchHistory
Get-KPatchStatus
Start-KPatchScan
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33668.htm
#>
Function Get-KMissingPatches
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AgentID,

		[Parameter(Mandatory=$False)][Switch]$HideDenied,
		[Parameter(Mandatory=$False)][String]$KBArticleID,

		
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KPatch]::GetSortableParameters([KPatch]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KPatch]::GetSortableParameters([KPatch]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "KBArticleId"
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{
		$ParamHash = @{
			URI = "$VSA/assetmgmt/audit"
			Method = "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
		}


		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		foreach ($Id in $AgentID) {
			$ParamHash.URI = "$VSA.assetmgmt/patch/$Id/machineupdate/$($HideDenied.ToString())"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{ N = "AgentID"; E = { $Id } } | Write-Output
		} 

	}
}

<#
.SYNOPSIS
Returns the patch history for an agent.

.PARAMETER ComputerName
Get patches for this computer name.

.PARAMETER AgentID
Get patches for these agents.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KPatch] with the [Sortable] attribute

.LINK
Get-KMissingPatches
Get-KPatchStatus
Start-KPatchScan
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33666.htm
#>
Function Get-KPatchHistory
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AgentID,


		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KPatch]::GetSortableParameters([KPatch]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KPatch]::GetSortableParameters([KPatch]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "KBArticleId"
	)

	Begin
	{
		Ensure-Connected
	}

	Process
	{
		$ParamHash = @{
			Method = "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		Foreach ($ID in $AgentID) {
			Invoke-AdvancedRestMethod @ParamHash -URI "$VSA/assetmgmt/patch/$ID/history" | Select-Object *, @{ N = "AgentID"; E = { $Id } } | Write-Output
		}

	}
}

<#
.SYNOPSIS
Returns the patch status of an agent machine.

.PARAMETER ComputerName
Get patches for this computer name.

.PARAMETER AgentID
Get patches for these agents.

.LINK
Get-KMissingPatches
Get-KPatchHistory
Start-KPatchScan
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33673.htm

#>
Function Get-KPatchStatus
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AgentID
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{
		$ParamHash = @{
			URI = "$VSA/assetmgmt/audit"
			Method = "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
		}


		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		Foreach ($ID in $AgentID) {
			$ParamHash.URI = "$VSA/assetmgmt/patch/$ID/status"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="AgentID"; E={$Id}} | Write-Output
		}

	}
}


<#
.SYNOPSIS
Scans an agent machine immediately for missing patches.

Warning:	This command will remove any previously scheduled, recurring patch scans.
			If your patch scans are applied in a policy, the recurring patch scan that you set 
			in the browser will be re-applied during the next compliance check in Policy Management->Configure->Settings.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER Scheduled
Specifies that you want to use the dynamic parameters for scheduling.

.PARAMETER Recurrence
Specifies that you want to use the dynamic parameter for recurrence.

.PARAMETER DistributionInterval
The units of time to distribute this patch scan. Useful when running on a large batch of computers.

.PARAMETER DistributionMagnitude
The amount of units to distribute this patch scan.

.PARAMETER StartOn
The date to start the patch scan.

.PARAMETER ExcludeFrom
Exclude patch scans starting at this time. Only the hours, minutes, and seconds are used.

.PARAMETER ExcludeTo
Exclude patch scans until this time. Only the hours, minutes, and seconds are used.

.PARAMETER RepeatInterval
The unit of time to repeat this patch scan.

.PARAMETER RepeatMagnitude
The amount of units to repeat this patch scan.

.PARAMETER EndOn
Stop the recurrence on this date.

.EXAMPLE
# Starts a patch scan on all devices with missing patches.
Get-KMissingPatches | Select -AgentId -Unique | Start-KPatchScan

.LINK
Get-KMissingPatches
Get-KPatchHistory
Get-KPatchStatus
Start-KPatchScan
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33669.htm
#>
Function Start-KPatchScan
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AgentID,
		
		
		[Parameter(Mandatory = $False)][Switch]$SkipIfOffLine,
		[Parameter(Mandatory = $False)][Switch]$PowerUpIfOffline,


		[Parameter(Mandatory = $False)][Switch]$Scheduled,
		[Parameter(Mandatory = $False)][Switch]$Recurrence,


		[Parameter(Mandatory = $False, HelpMessage = "What unit of time do we use for our distribution. Example: Within 5 (Days)")]
		[ValidateSet("Minutes", "Hours", "Days")]
		[String]$DistributionInterval = "Minutes",


		[Parameter(Mandatory = $False, HelpMessage = "What's the magnitude of our distribution. Example: Within (5) Days")]
		[Int]$DistributionMagnitude = 1


	)

	DynamicParam {
		$RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		if ($Scheduled) {
			$RuntimeParameterDictionary.Add("StartOn", `
			(New-DynamicParameter -Name "StartOn" -Type ([DateTime]) -HelpMessage "The day and time to run this audit." -DefaultValue (Get-Date)))

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


		$ids = @()
		if ($ComputerName) {
			$ids = Get-KMissingPatches -ComputerName $ComputerName | Select-Object -ExpandProperty PatchDataId
		}
		elseif ($AgentID) {
			$ids = Get-KMissingPatches -AgentId $AgentID | Select-Object -ExpandProperty PatchDataId
		}

		

		$RuntimeParameterDictionary.Add("PatchIds", (New-DynamicParameter -Name "PatchIds" -Type ([string[]]) -ValidateSet $ids))

		return $RuntimeParameterDictionary
	}

	Begin
	{
		Ensure-Connected
	}
	
	Process
	{
		$Body  =  @{
			SkipIfOffLine      =   [Bool]$SkipIfOffLine
			PowerUpIfOffLine   =   [Bool]$PowerUpIfOffline
			Distribution       =   @{
				Interval       =   $DistributionInterval
				Magnitude      =   $DistributionMagnitude
            }
            PatchIds = $PSBoundParameters.PatchIds
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

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		$AgentID | Foreach-Object {
			if ($Scheduled -or $Recurrence) {
				Invoke-RestMethod -URI "$VSA/assetmgmt/patch/$_/schedule" -Method Put -Body ($Body | ConvertTo-Json) -Headers @{
					'Authorization' = "Bearer $Token"
				} -ContentType "application/json"
			}
			else {
				Invoke-RestMethod -URI "$VSA/assetmgmt/patch/$_/scannow" -Method Put -Body ($Body | ConvertTo-Json) -Headers @{
					'Authorization' = "Bearer $Token"
				} -ContentType "application/json"
			}
		} | Write-Output
	}
}
