<#
.SYNOPSIS
Returns an array of department records for a specific organization.

.PARAMETER OrgName
Look for departments that include this in their organization name.

.PARAMETER OrgIds
Look for departments in these organizations.

.PARAMETER DepartmentName
Look for departments that include this in the department name.

.PARAMETER DepartmentId
Look for these departments.

.LINK
New-KDepartment
Remove-KDepartment
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31684.htm
#>
Function Get-KDepartments
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$OrgName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$OrgId,
		[Parameter(Mandatory = $False)][String]$DepartmentName = "",
		[Parameter(Mandatory = $False, ValueFromPipelineByPropertyName)][String[]]$DepartmentID
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
            Filters = @("substringof('$DepartmentName', DepartmentName)")
			SortBy 	= "DepartmentName"
        }


        if ($DepartmentID) {
			$ParamHash.Filters = $ParamHash.Filters + (($DepartmentID | Foreach-Object {"DepartmentId eq $($_)M"}) -join " or ")
        }

        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $OrgId = Get-KOrganizations -OrgName $OrgName | Select-Object -Expand OrgId
        }

        Foreach ($Id in $OrgId)
        {
            Write-Verbose ($ParamHash | ConvertTo-JSON)
            Invoke-AdvancedRestMethod @ParamHash -URI "$vsa/system/orgs/$Id/departments" | Write-Output
        }
	}
}

<#
.SYNOPSIS
Adds a single department record to a specified organizations.

.PARAMETER OrgName
Look for departments that include this in their organization name.

.PARAMETER OrgIds
Look for departments in these organizations.

.PARAMETER DepartmentName
The name for the new department.

.PARAMETER ReadOnly
Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
Get-KDepartment
Remove-KDepartment
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31683.htm
#>
Function New-KDepartment
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$OrgName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$OrgId,
        [Parameter(Mandatory = $True)][String]$DepartmentName = "",
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
            $ids = Get-KOrganizations -OrgName $OrgName | Select-Object -Expand OrgId
            if ($ids.Count -ne 1) {
                throw "$OrgName matches to $($Ids.Count) organizations. This is not allowed."
            }
            else {
                $OrgId = $ids
            }
        }

        $ParamHash = @{
            URI = "$VSA/system/orgs/$OrgId/departments"
            Method 	= "POST"
            Headers = @{"Authorization" = "Bearer $Token"}
            ContentType = "application/json"
            Body = @{
                DepartmentName = "$DepartmentName"
            }
        }

        if ($ReadOnly) {
            [PSCustomObject]$ParamHash | Write-Output
        }
        else {
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Add new department $DepartmentName in Org: $OrgId")) {
                    throw "Operation canceled by user."
                }
            }

            Invoke-AdvancedRestMethod @ParamHash | Write-Output
        }
	}
}

<#
.SYNOPSIS
Deletes a single department.

.PARAMETER DepartmentName
The name of the department to remove.

.PARAMETER DepartmentId
The id of the department to remove.

.PARAMETER ReadOnly
Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
Get-KDepartments
New-KDepartment
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31685.htm
#>
Function Remove-KDepartment
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName")][String]$DepartmentName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String]$DepartmentId,
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
            $ids = Get-KDepartments -DepartmentName "$DepartmentName" | Select-Object -Expand DepartmentId

            if ($ids.Count -ne 1) {
                throw "$DepartmentName matches to $ids departments!`nFor safety reasons, you can only delete one department at a time."
            }
            else {
                $DepartmentId = $ids
            }
        }

        $ParamHash = @{
            URI = "$vsa/system/departments/$DepartmentId"
            Method 	= "DELETE"
            Headers = @{"Authorization" = "Bearer $Token"}
            ContentType = "application/json"
        }

        if ($ReadOnly.IsPresent) {
            [PSCustomObject]$ParamHash | Write-Output
        }
        else {
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Remove department for ($DepartmentId)?")) {
                    throw "Operation canceled by user."
                }
            }
            Invoke-RestMethod @ParamHash | Write-Output
        }
	}
}