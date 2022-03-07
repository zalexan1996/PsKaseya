<#
.SYNOPSIS
Returns an array of machine group records for an organization.

.PARAMETER OrgName
Look for departments that include this in their organization name.

.PARAMETER OrgIds
Look for departments in these organizations.

.PARAMETER MachineGroupName
Look for machine groups that include this in the name.

.PARAMETER MachineGroupId
Look for these machine groups.

.LINK
New-KMachineGroup
Remove-KMachineGroup
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33707.htm
#>
Function Get-KMachineGroups
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$OrgName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$OrgId,
		[Parameter(Mandatory = $False)][String]$MachineGroupName = "",
		[Parameter(Mandatory = $False, ValueFromPipelineByPropertyName)][String[]]$MachineGroupId
	)
	Begin
	{
		Ensure-Connected
	}

	Process
	{


        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $OrgId = Get-KOrganizations -OrgName $OrgName | Select-Object -Expand OrgId
        }

        Foreach ($Id in $OrgId)
        {
            $ParamHash = @{
                URI = "$vsa/system/machinegroups"
                Method 	= "GET"
                Headers = @{"Authorization" = "Bearer $Token"}
                Filters = @("substringof('$MachineGroupName', MachineGroupName)")
                SortBy 	= "MachineGroupName"
            }

            $ParamHash.Filters = $ParamHash.Filters + "OrgId eq $($Id)M"

            if ($MachineGroupId.Count -gt 0) {
                $ParamHash.Filters = $ParamHash.Filters + (($MachineGroupId | Foreach-Object {"MachineGroupId eq $($_)M"}) -join " or ")
            }
    
            Invoke-AdvancedRestMethod @ParamHash | Write-Output
        }
	}
}

<#
.SYNOPSIS
Adds a single machine group record to a specified organization.

.PARAMETER OrgName
Look for departments that include this in their organization name.

.PARAMETER OrgIds
Look for departments in these organizations.

.PARAMETER MachineGroupName
The name of the machine group to create. Must be unique.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31700.htm
#>
Function New-KMachineGroup
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$OrgName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String]$OrgId,


		[Parameter(Mandatory = $True)][String]$MachineGroupName = ""
	)
	Begin
	{
		Ensure-Connected
	}

	Process
	{

        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $ids = Get-KOrganizations -OrgName $OrgName | Select-Object -Expand OrgId
            if ($ids.Count -ne 1) {
                Throw "$OrgName matches with $($ids.Count) organizations. You can only create a machine group for one organization at a time."
            }
            $OrgId = $ids
        }


        
        $ParamHash = @{
            URI = "$vsa/system/orgs/$orgId/machinegroups"
            Method 	= "POST"
            Headers = @{"Authorization" = "Bearer $Token"}
            ContentType = "application/json"
            Body = @{
                MachineGroupName = "$MachineGroupName"
            } | ConvertTo-Json
        }

        Invoke-RestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Deletes a single machine group record.

.PARAMETER MachineGroupName
The name of the Machine Group to remove.

.PARAMETER MachineGroupId
The id of the Machine Group to remove.

.PARAMETER ReadOnly
Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31699.htm
#>
Function Remove-KMachineGroup
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName")][String]$MachineGroupName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String]$MachineGroupId,
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
            $ids = Get-KMachineGroups -MachineGroupName "$MachineGroupName" | Select-Object -Expand MachineGroupId
            if ($ids.Count -ne 1) {
                throw "$ids matches to $($ids.Count) machine groups!`nFor safety reasons, you can only delete one group at a time."
            }
            else {
                $MachineGroupId = $ids
            }
        }

        $ParamHash = @{
            URI = "$vsa/system/machinegroups/$MachineGroupId"
            Method 	= "DELETE"
            Headers = @{"Authorization" = "Bearer $Token"}
            ContentType = "application/json"
        }

        if ($ReadOnly)
        {
            [PSCustomObject]$ParamHash | Write-Output
        }
        else 
        {
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Remove machine group for ($MachineGroupId)?")) {
                    throw "Operation canceled by user."
                }
            }
            Invoke-RestMethod @ParamHash | Write-Output
        }
	}
}

<#
.SYNOPSIS
Renames a single machine group record.

.PARAMETER MachineGroupName
The name of the Machine Group to remove.

.PARAMETER MachineGroupId
The id of the Machine Group to remove.

.PARAMETER NewName
The new name for the Machine Group. Must be unique.

.PARAMETER ReadOnly
Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31699.htm
#>
Function Rename-KMachineGroup
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName")][String]$MachineGroupName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String]$MachineGroupId,

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
            $ids = Get-KMachineGroups -MachineGroupName "$MachineGroupName" | Select-Object -Expand MachineGroupId
            if ($ids.Count -ne 1) {
                throw "$ids matches to $($ids.Count) machine groups!`nFor safety reasons, you can only delete one group at a time."
            }
            else {
                $MachineGroupId = $ids
            }
        }

        $ParamHash = @{
            URI = "$vsa/system/machinegroups/$MachineGroupId"
            Method 	= "PUT"
            Headers = @{"Authorization" = "Bearer $Token"}
            ContentType = "application/json"
            Body = @{
                MachineGroupName = $NewName
            }
        }

        if ($ReadOnly)
        {
            [PSCustomObject]$ParamHash | Write-Output
        }
        else 
        {
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Rename machine group ($MachineGroupId) to $NewName?")) {
                    throw "Operation canceled by user."
                }
            }
            Invoke-AdvancedRestMethod @ParamHash | Write-Output
        }
	}
}

<#
.SYNOPSIS
Adds a machine group to a scope.

.PARAMETER ScopeId
The Id of the scope to add the machine group to.

.PARAMETER ScopeName
The name of the scope to add the machine group to.

.PARAMETER MachineGroupName
The name of the Machine Group to remove.

.PARAMETER MachineGroupId
The id of the Machine Group to remove.

.PARAMETER ReadOnly
Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38539.htm
#>
Function Set-KMachineGroupScope
{
	[CmdletBinding(DefaultParameterSetName = "ScopeId")]
	Param (
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc1")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc2")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ScopeId")]
		[String]$ScopeId,


		[Parameter(Mandatory = $True, ParameterSetName = "proc3")]
		[Parameter(Mandatory = $True, ParameterSetName = "proc4")]
		[Parameter(Mandatory = $True, ParameterSetName = "ScopeName")]
		[String]$ScopeName,


		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc1")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "proc3")]
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "GroupId")]
		[String]$MachineGroupId,


		[Parameter(Mandatory = $True, ParameterSetName = "proc2")]
		[Parameter(Mandatory = $True, ParameterSetName = "proc4")]
		[Parameter(Mandatory = $True, ParameterSetName = "GroupName")]
        [String]$MachineGroupName,
        

        [Parameter(Mandatory = $False)][Switch]$ReadOnly,
        [Parameter(Mandatory = $False)][Switch]$Force
	)
	Begin
	{
		Ensure-Connected
	}

	Process
	{


        if ($MachineGroupName) {
            $ids = Get-KMachineGroups -MachineGroupName "$MachineGroupName" | Select-Object -Expand MachineGroupId
            if ($ids.Count -ne 1) {
                throw "$ids matches to $($ids.Count) machine groups!`nFor safety reasons, you can only set one machine group at a time."
            }
            else {
                $MachineGroupId = $ids
            }
        }

        if ($ScopeName) {
            $ids = Get-KScopes -ScopeName "$ScopeName" | Select-Object -Expand ScopeId
            if ($ids.Count -ne 1) {
                throw "$ids matches to $($ids.Count) scopes!`nFor safety reasons, you can only set one machine group at a time."
            }
            else {
                $ScopeId = $ids
            }
        }

        $ParamHash = @{
            URI = "$vsa/system/scopes/$ScopeId/machinegroups/$MachineGroupId"
            Method 	= "PUT"
            Headers = @{"Authorization" = "Bearer $Token"}
            ContentType = "application/json"
        }

        if ($ReadOnly)
        {
            [PSCustomObject]$ParamHash | Write-Output
        }
        else 
        {
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Set machine group ($MachineGroupId) to new scope: ($scopeId)?")) {
                    throw "Operation canceled by user."
                }
            }
            Invoke-AdvancedRestMethod @ParamHash | Write-Output
        }
	}
}