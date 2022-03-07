Function Add-KUserToRole
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True, ParameterSetName="ByRoleId", ValueFromPipelineByPropertyName)][Int[]]$RoleId,
        [Parameter(Mandatory=$True, ParameterSetName="ByRoleName")][String]$RoleName,
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName)][int]$UserId
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{

        if ($PSCmdlet.ParameterSetName -like "ByRoleName") {
            $RoleId = [int[]](Get-KUserRoles -RoleName $RoleName | Select-Object -Expand RoleId)
        }

        Foreach ($Id in $RoleId)
        {
            $ParamHash = @{
                URI     = "$VSA/system/roles/$Id/users/$UserId"
                Method 	= "PUT"
                Headers = @{"Authorization" = "Bearer $Token"}
            }
            #$ParamHash | ConvertTo-Json | Write-Output
            Invoke-AdvancedRestMethod @ParamHash | Write-Output
        }
	}
}

<#
.SYNOPSIS
Returns a collecton of user role records.

.PARAMETER RoleId
Only include these roles.

.PARAMETER RoleName
Only include roles with this role name.

.LINK
Get-KRoleTypes
New-KRole
Remove-KRoles
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31713.htm
#>
Function Get-KUserRoles
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$RoleName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$RoleId
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{

		$ParamHash = @{
			URI     = "$VSA/system/roles"
			Method 	= "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
			Filters = @(
				"substringof('$RoleName',RoleName)"
            )
            SortBy = "RoleName"
		}

        if ($PSCmdlet.ParameterSetName -like "ById") {
			$ParamHash.Filters = $ParamHash.Filters + (($RoleId | Foreach-Object {"RoleId eq $($_)M"}) -join " or ")
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Returns an array of user roletype records.

.PARAMETER RoleTypeId
Only include these role types.

.PARAMETER RoleTypeName
Only include role types with this name.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31717.htm
#>
Function Get-KUserRoleTypes
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$RoleTypeName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$RoleTypeId
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{

		$ParamHash = @{
			URI     = "$VSA/system/roletypes"
			Method 	= "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
			Filters = @(
				"substringof('$RoleTypeName',RoleTypeName)"
            )
            SortBy = "RoleTypeName"
		}

        if ($PSCmdlet.ParameterSetName -like "ById") {
			$ParamHash.Filters = $ParamHash.Filters + (($RoleTypeId | Foreach-Object {"RoleTypeId eq $($_)M"}) -join " or ")
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Creates a user role record.

.PARAMETER RoleName
The name of the role to add.

.PARAMETER RoleTypeId
The ids of the role types for this role.

.EXAMPLE
# Creates a new End User role.
Get-KUserRoleTypes -RoleTypeName "End User" | New-KRole -RoleName "New Test Role"
#>
Function New-KUserRole
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)][String]$RoleName,
		[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName)][Int[]]$RoleTypeId
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{

		$ParamHash = @{
			URI     = "$VSA/system/roles"
			Method 	= "POST"
			Headers = @{"Authorization" = "Bearer $Token"}
            Body = @{
                "RoleName" = $RoleName
                "RoleTypeIds" = $RoleTypeId
            }
            ContentType="application/json"
		}
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Deletes a single user role.

.PARAMETER RoleId
Only delete this role.

.PARAMETER RoleName
Only include roles with this role name. Only allows this to match to one role.

.PARAMETER ReadOnly
Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38535.htm
#>
Function Remove-KUserRole
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][String]$RoleName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String]$RoleId,
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

            $ids = Get-KUserRoles -RoleName $RoleName | Select-Object -Expand RoleId
            if ($Ids.Count -ne 1) {
                throw "$RoleName matches to $($ids.count) user roles!`nFor safety reasons, you can only delete one user role at a time."
            }
            else {
                $RoleId = $ids
            }
        }

		$ParamHash = @{
            URI = "$VSA/system/roles/$RoleId"
			Method 	= "DELETE"
			Headers = @{"Authorization" = "Bearer $Token"}
		}
		
		if ($ReadOnly.IsPresent)
		{
			[PSCustomObject]$ParamHash | Write-Output
		}
		else
		{
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Remove User Role for ($RoleId)?")) {
                    throw "Operation canceled by user."
                }
            }
			Invoke-RestMethod @ParamHash | Write-Output
		}
        
	}
}
