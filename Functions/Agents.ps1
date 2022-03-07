<#
.SYNOPSIS
Gets 2FA settings for an agent. Returns false if there were no 2FA settings for the agent.

.PARAMETER ComputerName
The computer name of the agent to get 2FA settings for.

.PARAMETER AgentID
The agent Id of the agent to get 2FA settings for.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37303.htm

#>
Function Get-K2FASettings
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID
	)
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentId
        }

        $AgentID | Foreach-Object {
            try {
                Invoke-AdvancedRestMethod @ParamHash -URI "$VSA/assetmgmt/agent/$_/twofasettings"
            }
            catch {
                if ($_.ErrorDetails.Message -like "No 2FA settings found for specified agentId.") {
                    return $False
                }
                else {
                    throw $_
                }
            }
        } | Write-Output
	}
}

<#
.SYNOPSIS
Gets a list of agents by specified criteria. 

.PARAMETER ComputerName
Get agents that include this in their computer name.

.PARAMETER AgentID
A list of agent IDs to get agent objects for.

.PARAMETER AgentView
Gets agents in this agent view.

.PARAMETER SortBy
Sorts the result by one of the agent's sortable properties.

.PARAMETER Filters
Optional filters to use to speed up the API call.
For information on the format that each element of Filters must be in:
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31622.htm

.EXAMPLE
# Gets a list of computers that bobert is on.
Get-KAgents | ? {$_.CurrentUser -like "bobert"} | Select AgentName, CurrentUser

.LINK
Remove-KAgent
Rename-KAgent
Get-KAgentViews
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31642.htm
#>

<#Function Get-KAgents
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AgentID,

		[Parameter(Mandatory = $False)]
		[ArgumentCompleter({
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				Get-KAgentViews -ViewDefName "$WordToComplete" | Select-Object -Expand ViewDefName
		})]
		[ValidateScript({ (Get-KAgentViews -ViewDefName $_ | Select-Object -Expand ViewDefName).Count -eq 1 })]
		[String]$AgentView,


		[Parameter(Mandatory = $False)]
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KAgent]::GetSortableParameters([KAgent]).Name
			}
		)]
		[ValidateScript({ $_ -in [KAgent]::GetSortableParameters([KAgent]).Name })]
		[String]$SortBy = "AgentName",
		[String[]]$Filters = $NULL
	)


	Begin
	{
		Connect-Kaseya
	}

	Process
	{
        $ParamHash = @{
            URI 	= "$VSA/assetmgmt/agents"
            Method 	= "GET"
			Headers = @{ "Authorization" = "Bearer $Token" }
			SortBy 	= $SortBy
			Filters = @(
				"substringof('$ComputerName',ComputerName)"
			)
		}

		if ($PSCmdlet.ParameterSetName -like "ById") {
			$ParamHash.Filters = $ParamHash.Filters + (($AgentID | Foreach-Object {"AgentId eq $($_)M"}) -join " or ")
		}

		if ($AgentView) {
			$ViewDefId = Get-KAgentViews -ViewDefName $AgentView | Select-Object -Expand ViewDefID -First 1
			$ParamHash.URI = "$VSA/assetmgmt/agentsinview/$ViewDefId"
		}
		
		Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

#>
Function Get-KAgents
{
	[CmdletBinding()]
	Param (

	
		[Parameter(Mandatory = $False)]
		[ArgumentCompleter({
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				Get-KAgentViews -ViewDefName "$WordToComplete" | Select-Object -Expand ViewDefName
		})]
		[ValidateScript({ (Get-KAgentViews -ViewDefName $_ | Select-Object -Expand ViewDefName).Count -eq 1 })]
		[String]$AgentView,



		[Parameter(Mandatory = $False)]
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KAgent]::GetSortableParameters([KAgent]).Name
			}
		)]
		[ValidateScript({ $_ -in [KAgent]::GetSortableParameters([KAgent]).Name })]
		[String]$SortBy = "AgentName",




		[Parameter(Mandatory = $False)][String[]]$Filters = @()
	)

	
    DynamicParam {
        # Create a new dynamic parameter dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        # Get a list of all filterable parameters as defined in VorexDefinitions.cs
        $Filterables = [KAgent]::GetFilterableParameters([KAgent])

        # Iterate through each one.
        foreach ($f in $Filterables)
        {
            # Add a new dynamic parameter to the dictionary with my helper function.
            $RuntimeParameterDictionary.Add($f.Name, (
                New-DynamicParameter -Name $f.Name -Type ($f.PropertyType) -ValueFromPipelineByPropertyName
            ))
        }
		return $RuntimeParameterDictionary
    }


	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI 	= "$VSA/assetmgmt/agents"
            Method 	= "GET"
			Headers = @{ "Authorization" = "Bearer $Token" }
			SortBy 	= $SortBy
			Filters = $Filters
		}


		if ($AgentView) {
			$ViewDefId = Get-KAgentViews -ViewDefName $AgentView | Select-Object -Expand ViewDefID -First 1
			$ParamHash.URI = "$VSA/assetmgmt/agentsinview/$ViewDefId"
		}
		else {
			Foreach ($Key in $PSBoundParameters.Keys)
			{
				$CurVal = $PSBoundParameters[$Key]
				$Type = $CurVal.GetType()
	
				Switch ($Type)
				{
					([Int32])   {   $ParamHash.Filters = $ParamHash.Filters + "$Key eq $($CurVal)M"       }
					([String])  {   $ParamHash.Filters = $ParamHash.Filters + "startswith($Key, '$CurVal')" <#"$Key eq '$CurVal'"#>         }
					([Double])  {   $ParamHash.Filters = $ParamHash.Filters + "$Key eq $($CurVal)M"       }
					([Bool])    {   $ParamHash.Filters = $ParamHash.Filters + "$Key eq $($CurVal)"        }
				}
			}
		}
		
		Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}


<#
.SYNOPSIS
Gets the agent settings for a specific agent.

.PARAMETER ComputerName
Get agent settings for this computer name filter.

.PARAMETER AgentID
Get agent settings for these agent ids.

.EXAMPLE
Get-KAgents -ComputerName "Laptop-" | Get-KAgentSettings

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33827.htm

#>
Function Get-KAgentSettings
{

	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
            Filters = $Filters
        }

        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -ExpandProperty AgentId
        }

        Foreach ($Id in $AgentID)
        {
            Invoke-AdvancedRestMethod @ParamHash -URI "$VSA/assetmgmt/agent/$Id/settings" | Select-Object *, @{N="AgentId"; E={$Id}} | Write-Output
        }
	}
}


<#
.SYNOPSIS
Gets the total uptime for an agent.

.PARAMETER ComputerName
The computer that you want to get the uptime for.

.PARAMETER AgentID
The agent ids you want to get the uptime for.

.PARAMETER Since
Only get computers that have been online since this date.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38506.htm
#>
Function Get-KAgentUptime
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $False, Position=1)][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $False, ValueFromPipelineByPropertyName)][String[]]$AgentID,

        [Parameter(Mandatory =$False)][DateTime]$Since = (Get-Date)
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/assetmgmt/agents/uptime/$($Since.ToString("yyyy-MM-dd"))"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
            Filters = @(
                "substringof('$ComputerName',AgentName)"
            )
        }
        if ($AgentID) {
			$ParamHash.Filters = $ParamHash.Filters + (($AgentID | Foreach-Object {"AgentId eq $($_)M"}) -join " or ")
        }

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}


<#
.SYNOPSIS
Gets a list of agent views.

.PARAMETER ViewDefName
A substring of the view's name.

.EXAMPLE
# Upgrades all Windows 10 build 1703 to the latest. you must have the corresponding AgentView and Procedure.
Get-KAgentViews -ViewDefName "WinX-1703" | Start-KAgentProcedure -AgentProcedureName "UpgradeWinX" -DistributionMagnitude 5 -DistributionInterval Hours

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33829.htm
#>
Function Get-KAgentViews
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)][String]$ViewDefName = ""
    )
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/system/views"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
            Filters = @("substringof('$ViewDefName',ViewDefName)")
        }

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}


<#
.SYNOPSIS
Gets the remote control notification policy for an agent.

.PARAMETER ComputerName
The computer name of the agent you want to get the policy for.

.PARAMETER AgentID
The agentId of the agent you want to get the policy for.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33700.htm
#>
Function Get-KRemoteControlNotifyPolicy
{

	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID
	)
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentId
        }

        $AgentID | Foreach-Object {
            Invoke-AdvancedRestMethod @ParamHash -URI "$VSA/remotecontrol/notifypolicy/$_"
        } | Write-Output
	}
}


<#
.SYNOPSIS
Removes an agent from Kaseya. Prompts for confirmation before it removes the agent.

.PARAMETER ComputerName
The computer name for an agent. Doesn't support multiple computers.

.PARAMETER AgentIDs
A list of agent IDs to remove agents for.

.PARAMETER UninstallFirst
Tells Kaseya to uninstall the agent from the target machine before removing the agent account.

.PARAMETER ReadOnly
Don't remove the agent. Only return the properties that will be used to remove the agent.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
Get-KAgents
New-KAgent
Rename-KAgent
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38501.htm
#>
Function Remove-KAgent
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String]$AgentID,
        [Parameter(Mandatory = $False)][Switch]$UninstallFirst,
        [Parameter(Mandatory = $False)][Switch]$ReadOnly,
        [Parameter(Mandatory = $False)][Switch]$Force
    )
	Begin
	{
		Ensure-Connected
    }
	Process
	{

        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $Ids = Get-KAgents -ComputerName $ComputerName | Select-Object -ExpandProperty AgentId
            if ($Ids.Count -eq 1) {
                $AgentID = $Ids
            }
            else {
                throw "$ComputerName matches to $($Ids.Count) agents. This is not allowed."
            }
        }

        
        $ParamHash = @{
            URI = "$VSA/assetmgmt/agents/$AgentId$(if ($UninstallFirst) { "/uninstallfirst"})"
            Method 	= "DELETE"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        if ($ReadOnly) {
            [PSCustomObject]$ParamHash | Write-Output
        }
        else {
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Remove agent for ($AgentId)?")) {
                    throw "Operation canceled by user."
                }
            }
            
            Invoke-AdvancedRestMethod @ParamHash | Write-Output
        }
	}
}


<#
.SYNOPSIS
Renames an agent. Only works on one agent at a time.

.PARAMETER ComputerName
The computer name for an agent. Doesn't support multiple computers.

.PARAMETER AgentID
The Agent Id to rename

.PARAMETER NewName
The new name for the agent. Must be unique.

.PARAMETER ReadOnly
Don't rename the agent. Only return the properties that will be used to rename the agent.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38502.htm
#>
Function Rename-KAgent
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String]$AgentID,
        [Parameter(Mandatory = $True)][String]$NewName,
        [Parameter(Mandatory = $False)][Switch]$ReadOnly,
        [Parameter(Mandatory = $False)][Switch]$Force
        
    )
	Begin
	{
		Ensure-Connected
    }
	Process
	{
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $Agents = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
            if ($Agents.Count -eq 1) {
                $AgentID = $Agents
            }
            else {
                Throw "$($Agents.Count) agents found with $ComputerName in their computer names. This is not allowed for renaming."
            }
        }
        $ParamHash = @{
            URI = "$VSA/assetmgmt/agents/$AgentID/rename/$NewName"
            Method 	= "PUT"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        
        if ($ReadOnly) {
            [PSCustomObject]@{
                AgentID = $AgentID
                URI = $ParamHash.URI
                NewName = $NewName
            } | Write-Output
        }
        else {
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Rename agent for ($Id) to $NewName?")) {
                    throw "Operation canceled by user."
                }
            }
            Invoke-RestMethod @ParamHash | Write-Output
        }

	}
}

<#
.SYNOPSIS
Sets the check-in data for a selection of agents. This is data pertaining to where an agent reports to.

.PARAMETER ComputerName
The computer name of the agents. Can be empty.

.PARAMETER AgentID
The agent id to modify.

.PARAMETER PrimaryKServer
The primary Kaseya server this agent reports to

.PARAMETER PrimaryKServerPort
The port that the primary K server uses.

.PARAMETER SecondaryKServer
The secondary Kaseya server this agent reports to if the primary is unreachable.

.PARAMETER SecondaryKServerPort
The port that the secondary K server uses.

.PARAMETER QuickCheckInTimeInSeconds
TODO: No clue what this does

.PARAMETER BandwidthThrottle
TODO: No clue what this does

.PARAMETER ReadOnly
Don't set the check-in settings. Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.


.EXAMPLE
# Points all agents to a new Secondary K Server.
Get-KAgentSettings | ? {$_.CheckInControl.SecondaryKServer -like "old_server"} | Set-KCheckInControl -SecondaryKServer "new_server"

.LINK
Get-KAgentSettings
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33831.htm

#>
Function Set-KCheckinControl
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][AllowEmptyString()][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
        [Parameter(Mandatory = $False)][String]$PrimaryKServer = "",
        [Parameter(Mandatory = $False)][Int]$PrimaryKServerPort = -1,
        [Parameter(Mandatory = $False)][String]$SecondaryKServer = "",
        [Parameter(Mandatory = $False)][Int]$SecondaryKServerPort = -1,
        [Parameter(Mandatory = $False)][Int]$QuickCheckInTimeInSeconds = -1,
        [Parameter(Mandatory = $False)][Int]$BandwidthThrottle = -1,
        [Parameter(Mandatory = $False)][Switch]$ReadOnly,
        [Parameter(Mandatory = $False)][Switch]$Force
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

        
        $Body = @{}

        
        if ($PrimaryKServer) {
            $Body["PrimaryKServer"] = $PrimaryKServer
        }
        if ($SecondaryKServer) {
            $Body["SecondaryKServer"] = $SecondaryKServer
        }

        if ($PrimaryKServerPort -ne -1) {
            $Body["PrimaryKServerPort"] = $PrimaryKServerPort
        }
        if ($SecondaryKServerPort -ne -1) {
            $Body["SecondaryKServerPort"] = $SecondaryKServerPort
        }
        if ($QuickCheckInTimeInSeconds -ne -1) {
            $Body["QuickCheckInTimeInSeconds"] = $QuickCheckInTimeInSeconds
        }
        if ($BandwidthThrottle -ne -1) {
            $Body["BandwidthThrottle"] = $BandwidthThrottle
        }



        foreach ($id in $AgentId)
        {
            $ParamHash = @{
                URI = "$VSA/assetmgmt/agent/$id/settings/checkincontrol"
                Method 	= "PUT"
                Headers = @{"Authorization" = "Bearer $Token"}
                ContentType="application/json"
                Body = $Body
            }

            if ($ReadOnly.IsPresent) {
                [PSCustomObject]$ParamHash | Write-Output
            }
            else 
            {
                if (!$DisableKConfirmations -and !$Force.IsPresent) {
                    if (!(Get-Confirmation -Message "Set the Checkin control settings for $Id?")) {
                        throw "Operation canceled by user."
                    }
                }
                Invoke-AdvancedRestMethod @ParamHash | Write-Output
            }
        }

	}
}


<#
.SYNOPSIS
Sets a new temporary directory for an agent. 

.PARAMETER ComputerName
The computer name of the agent to modify.

.PARAMETER AgentID
The agent id of the agent to modify.

.PARAMETER NewDirectory
The new directory to use as a temporary directory for kaseya.

.PARAMETER ReadOnly
Don't make any changes. Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.EXAMPLE
# Sets all agent temp directories to C:\ktemp
Set-KTempDirectory -NewDirectory "C:\ktemp"

.EXAMPLE
# Finds agents that have their temp directory on a non-C drive and set it to be on the C drive,
Get-KAgentSettings | ? TempDirectory -notlike "C:*" | Set-KTempDirectory -NewDirectory "C:\ktemp"

.LINK
Get-KAgentSettings
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33835.htm
#>

Function Set-KTempDirectory
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][AllowEmptyString()][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
        [Parameter(Mandatory = $True)][String]$NewDirectory,
        [Parameter(Mandatory = $False)][Switch]$ReadOnly,
        [Parameter(Mandatory = $False)][Switch]$Force
    )
	Begin
	{
        Ensure-Connected
        throw "Not implemented due to inconsistencies in the help pages"
    }
	Process
	{
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
        }


        foreach ($id in $AgentId) {

            $ParamHash = @{
                URI = "$VSA/assetmgmt/agents/$Id/settings/tempdir"
                Method 	= "PUT"
                Headers = @{"Authorization" = "Bearer $Token"}
                ContentType = "application/json"
                Body = "[
                    {
                    `"key`": `"TempDirectory`",
                    `"value`": `"$NewDirectory`"
                    }
                ]"
            }

            if ($ReadOnly.IsPresent)
            {
                [PSCustomObject]$ParamHash | Write-Output
            }
            else
            {
                if (!$DisableKConfirmations -and !$Force.IsPresent) {
                    if (!(Get-Confirmation -Message "Set the temp directory for agent $Id to $NewDirectory ?")) {
                        throw "Operation canceled by user."
                    }
                }
                
                Invoke-RestMethod @ParamHash | Write-Output
            }
        }
	}
}


<#
.SYNOPSIS
Set's user profile information for a selection of agents.

.PARAMETER ComputerName
The computer name of the agent to modify.

.PARAMETER AgentID
The agent id of the agent to modify.

.PARAMETER AdminEmail
The administrator email.

.PARAMETER UserName
The user's name.

.PARAMETER UserEmail
The user's email.

.PARAMETER UserPhone
The user's phone. Doesn't enforce any formatting.

.PARAMETER Notes
Any notes associated with this profile.

.PARAMETER ReadOnly
Don't make any changes. Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.


.EXAMPLE 
# Sets all admin emails for every agent.
Set-KUserProfile -ComputerName "" -AdminEmail "it@company.com"

.LINK
Get-KAgentSettings
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33833.htm
#>
Function Set-KUserProfile
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][AllowEmptyString()][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

        [Parameter(Mandatory=$False)][String]$AdminEmail,
        [Parameter(Mandatory=$False)][String]$UserName,
        [Parameter(Mandatory=$False)][String]$UserEmail,
        [Parameter(Mandatory=$False)][String]$UserPhone,
        [Parameter(Mandatory=$False)][String]$Notes,
        [Parameter(Mandatory = $False)][Switch]$ReadOnly,
        [Parameter(Mandatory = $False)][Switch]$Force
    )
	Begin
	{
		Ensure-Connected
    }
	Process
	{
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentId = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
        }

        
        $Body = @{}

        if ($AdminEmail) {
            $Body["AdminEmail"] = $AdminEmail
        }
        if ($UserName) {
            $Body["UserName"] = $UserName
        }
        if ($UserEmail) {
            $Body["UserEmail"] = $UserEmail
        }
        if ($UserPhone) {
            $Body["UserPhone"] = $UserPhone
        }
        if ($Notes) {
            $Body["Notes"] = $Notes
        }


        Foreach ($Id in $AgentId)
        {
            $ParamHash = [PSCustomObject]@{
                URI = "$VSA/assetmgmt/agent/$Id/settings/userprofile"
                Method 	= "PUT"
                Headers = @{"Authorization" = "Bearer $Token"}
                ContentType = "application/json"
                Body = $Body
            }

            if ($ReadOnly.IsPresent)
            {
                $ParamHash | Write-Output
            }
            else
            {
                if (!$DisableKConfirmations -and !$Force.IsPresent) {
                    if (!(Get-Confirmation -Message "Set the user profile information for agent $Id?")) {
                        throw "Operation canceled by user."
                    }
                }
                
                Invoke-AdvancedRestMethod @ParamHash | Write-Output
            }
        }
	}
}
