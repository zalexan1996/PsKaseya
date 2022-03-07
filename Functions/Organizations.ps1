<#
.SYNOPSIS
Returns an array of organization location records.

.PARAMETER OrgName
Look for locations that include this in their organization name.

.PARAMETER OrgIds
Look for locations in these organizations.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38530.htm
#>
Function Get-KOrganizationLocations
{    
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$OrgName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$OrgId
    )

	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$vsa/system/orgs/locations"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        if ($PSCmdlet.ParameterSetName -like "ByName")
        {
            Invoke-AdvancedRestMethod @ParamHash | Where-Object {$_.OrgName -like "*$OrgName*"} | Write-Output
        }
        else {
            Invoke-AdvancedRestMethod @ParamHash | Where-Object {$_.OrgId -in $OrgId} | Write-Output
        }
	}
}
<#
.SYNOPSIS
Returns an array of organizational records.

.PARAMETER OrgName
Look for departments that include this in their organization name.

.PARAMETER OrgIds
Look for departments in these organizations.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31704.htm
#>
Function Get-KOrganizations
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$OrgName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$OrgId
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$vsa/system/orgs"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
            Filters = @("substringof('$OrgName',OrgName)")
			SortBy 	= "OrgName"
        }

        if ($PSCmdlet.ParameterSetName -like "ByID") {
			$ParamHash.Filters = $ParamHash.Filters + (($OrgId | Foreach-Object {"OrgId eq $($_)M"}) -join " or ")
        }

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Returns an array of organization type records.

.PARAMETER OrgTypeName
Look for types that include this in their name.

.PARAMETER OrgTypeId
Look for these types.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38532.htm
#>
Function Get-KOrganizationTypes
{    
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$OrgTypeRef = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$OrgTypeId
    )

	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$vsa/system/orgs/types"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        if ($PSCmdlet.ParameterSetName -like "ByName")
        {
            Invoke-AdvancedRestMethod @ParamHash | Where-Object {$_.OrgTypeRef -like "*$OrgTypeRef*"} | Write-Output
        }
        else {
            Invoke-AdvancedRestMethod @ParamHash | Where-Object {$_.OrgTypeId -in $OrgTypeId -and $_.OrgTypeRef -like "*$OrgTypeRef*"} | Write-Output
        }
	}
}
