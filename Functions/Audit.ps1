<#
.SYNOPSIS
Gets all programs as seen in the Add/Remove Programs section of the control panel.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds

.PARAMETER DisplayName
The name of a program or selection of programs to search for. 

.EXAMPLE
# Uninstalls all Adobe products maybe? The Invoke-Command call is untested.

Get-KAddRemovePrograms -ComputerName IT-01 -DisplayName "Adobe" | % { 
	Invoke-Command -ComputerName IT-01 -ScriptBlock { . $_ } -RunAsAdministrator
}

.LINK
Get-KInstalledApplications
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32451.htm
#>
Function Get-KAddRemovePrograms
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

		[Parameter(Mandatory = $False)][String]$DisplayName = ""
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
			Filters = @(
				"substringof('$DisplayName',DisplayName)"
			)
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}
		Foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/software/addremoveprograms"
			Invoke-AdvancedRestMethod @ParamHash| Write-Output
		}
	}
}

<#
.SYNOPSIS
Gets audit information on selected agents.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds

.PARAMETER SortBy
Sorts the audit info by this property. This sorting is done by the RestAPI.

.PARAMETER CurrentUser
Get audit info for agents that this user is logged into.

.PARAMETER LastUser
Get audit info for agents where this user was the last user to log in.

.PARAMETER Domain
Get audit info for agents on this domain.

.EXAMPLE
# Gets basic audit information on devices.
Get-KAuditSummary | Select-Object ComputerName, GroupName, OsInfo, Manufacturer, ProductName, `
	SystemSerialNumber, SysPurchaseDate, SysWarrantyExpireDate | Export-CSV C:\temp\Assets
.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31658.htm
#>
Function Get-KAuditSummary
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[ArgumentCompleter({
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KAuditSummary]::GetSortableParameters([KAuditSummary]).Name
		})]
		[ValidateScript({
				$_ -in [KAuditSummary]::GetSortableParameters([KAuditSummary]).Name
		})]
		[Parameter(Mandatory=$False)][String]$SortBy = "ComputerName"

	)
	
    DynamicParam{
        # Create a new dynamic parameter dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        # Get a list of all filterable parameters as defined in VorexDefinitions.cs
        $Filterables = [KAuditSummary]::GetFilterableParameters([KAuditSummary])

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
			URI = "$VSA/assetmgmt/audit"
			Method = "GET"
			Headers = @{ "Authorization" = "Bearer $Token" }
			Filters = @()
			SortBy 	= $SortBy
		}
		
		Foreach ($Key in $PSBoundParameters.Keys)
		{
			$CurVal = $PSBoundParameters[$Key]
			$Type = $CurVal.GetType()

			Switch ($Type)
			{
				([Int32])   { $ParamHash.Filters = $ParamHash.Filters + "$Key eq $($CurVal)M"           }
				([String])  { $ParamHash.Filters = $ParamHash.Filters + "substringof('$CurVal', $Key)"  }
				([Double])  { $ParamHash.Filters = $ParamHash.Filters + "$Key eq $($CurVal)M"           }
				([Bool])    { $ParamHash.Filters = $ParamHash.Filters + "$Key eq $($CurVal)"            }
			}
		}

		(Invoke-AdvancedRestMethod @ParamHash) | Write-Output
	}
}

<#
.SYNOPSIS
Gets a list of Kaseya credentials for an agent.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32439.htm
#>
Function Get-KCredentials
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][Alias("AgentGuid", "Id")][String[]]$AgentID
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
		$AgentID | Foreach-Object {
			$ParamHash.URI = "$VSA/assetmgmt/audit/$_/credentials"
			Invoke-AdvancedRestMethod @ParamHash
		} | Write-Output

	}
}

<#
.SYNOPSIS
Gets a list of disk volumes on an agent's machine.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER DriveLetter
Filter by drive letter.

.PARAMETER Format
Filter by the drive's format.

.PARAMETER DriveName
Filter by the drive's name.

.PARAMETER SortBy
Sort by this property.

.LINK
Get-KPCIAndDisks
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32443.htm
#>
Function Get-KDiskVolumes
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
		[Parameter(Mandatory = $False)][String]$DriveLetter = "",
		[Parameter(Mandatory = $False)][String]$DriveFormat = "",
		[Parameter(Mandatory = $False)][String]$DriveName = "",

		
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KDiskVolume]::GetSortableParameters([KDiskVolume]).Name
			}
		)][ValidateScript(
			{
				$_ -in [KDiskVolume]::GetSortableParameters([KDiskVolume]).Name
			}
		)][Parameter(Mandatory=$False)][String]$SortBy = "Drive"
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
			SortBy = $SortBy
			Filters = @(
				"substringof('$DriveLetter',Drive)",
				"substringof('$DriveName',Label)",
				"substringof('$DriveFormat',Format)"
			)
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		$AgentID | Foreach-Object {
			$ParamHash.URI = "$VSA/assetmgmt/audit/$_/hardware/diskvolumes"
			Invoke-AdvancedRestMethod @ParamHash
		} | Write-Output
	}
}

<#
.SYNOPSIS
Gets a list of installed applications on the agent's machine.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER ApplicationName
Filter by the applications name.

.PARAMETER Manufacturer
Filter by the Manufacturer's name.

.PARAMETER ProductName
Filter by the product name.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KApplication] with the [Sortable] attribute

.LINK
Get-KAddRemovePrograms
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32453.htm
#>
Function Get-KInstalledApplications
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
		[Parameter(Mandatory = $False)][String]$ApplicationName = "",
		[Parameter(Mandatory = $False)][String]$Manufacturer = "",
		[Parameter(Mandatory = $False)][String]$ProductName = "",

		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KApplication]::GetSortableParameters([KApplication]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KApplication]::GetSortableParameters([KApplication]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "ApplicationName"
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
			Filters = @(
				"substringof('$ApplicationName',ApplicationName)",
				"substringof('$Manufacturer',Manufacturer)",
				"substringof('$ProductName',ProductName)"
			)
			SortBy = $SortBy
		}


		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		Foreach ($Id in $AgentID)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/software/installedapplications"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="AgentId";E={$Id}} | Write-Output
		}
	}
}

<#
.SYNOPSIS
Returns a list of local users in each local group on the agent.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER UserGroupName
The name of the local group

.PARAMETER MemberName
A user to sort. Will return all groups that this user is a member of.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KLocalGroupMember] with the [Sortable] attribute

.EXAMPLE
# Get a list of agents where the last logged in user has the ability to RDP into their system.
$Agents = Get-KAgents | Select-Object AgentId, ComputerName, LastLoggedInUser
Foreach ($Agent in $Agents) {
	$Agent | Get-KLocalGroupMembers | ? {$_.UsergroupName -like "Remote Desktop Users" -and $_.MemberName -like "*$($Agent.LastLoggedInUser)*"}
}

.LINK
Get-KLocalUserAccounts
Get-KLocalGroups
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32449.htm
#>
Function Get-KLocalGroupMembers
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
		[Parameter(Mandatory = $False)][String]$UserGroupName = "",
		[Parameter(Mandatory = $False)][String]$MemberName = "",

		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KLocalGroupMember]::GetSortableParameters([KLocalGroupMember]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KLocalGroupMember]::GetSortableParameters([KLocalGroupMember]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "UserGroupName"
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
			Filters = @(
				"substringof('$UserGroupName',UserGroupName)",
				"substringof('$MemberName',MemberName)"
			)
		}


		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		Foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/members"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N = "AgentID"; E = { $Id }} | Write-Output
		}
	}
}



<#
.SYNOPSIS
Get local user accounts on an agent.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER LogonName
Filter by user name.

.PARAMETER FullName
Filter by the user's full name.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KLocalUserAccount] with the [Sortable] attribute

.EXAMPLE
# Run Disable-GuestAccount on all agents that have the Guest account enabled.
Get-KLocalUserAccounts | ? { $_.LogonName -like "Guest" -and $_.IsDisabled -eq $False} | `
	Start-KAgentProcedure -AgentProcedureName "Disable-GuestAccount" -DistributionInterval Hours -DistributionMagnitude 2

.LINK
Get-KLocalGroupMembers
Get-KLocalUserGroups
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33629.htm
#>
Function Get-KLocalUserAccounts
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
		[Parameter(Mandatory = $False)][String]$LogonName = "",
		[Parameter(Mandatory = $False)][String]$FullName = "",
		
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KLocalUserAccount]::GetSortableParameters([KLocalUserAccount]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KLocalUserAccount]::GetSortableParameters([KLocalUserAccount]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "LogonName"
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
			Filters = @(
				"substringof('$LogonName',LogonName)",
				"substringof('$FullName',FullName)"
			)
			SortBy = $SortBy
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}
		
		Foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/useraccounts"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="AgentId";E={$Id}} | Write-Output
		}
	}
}


<#
.SYNOPSIS
Gets a list of local groups on an agent.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.EXAMPLE
# Gets the local groups on IT-01
Get-KLocalUserGroups -ComputerName IT-01

.EXAMPLE
# Gets the local groups on all IT computers.
Get-KAgents IT- | Get-KLocalUserGroups

.LINK
Get-KLocalUserAccounts
Get-KLocalGroupMembers
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32441.htm
#>
Function Get-KLocalUserGroups
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
			URI = "$VSA/assetmgmt/audit"
			Method = "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		Foreach ($Id in $AgentId) {
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/groups"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="AgentId";E={$Id}} | Write-Output
		}

	}
}



<#
.SYNOPSIS
Returns an array of disk drives and pci devices on the agent.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER Vendor
Filter the results to only include objects for this vendor.

.PARAMETER Product
Filter the results to only include products with this string in them.

.PARAMETER TypeId
Filter the results to only include products with this type id.

.PARAMETER TypeName
Filter the results to only include products with this type name.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KPciandDisk] with the [Sortable] attribute

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32445.htm
#>
Function Get-KPCIandDisks
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

		[Parameter(Mandatory = $False)][String]$Vendor = "",

		[Parameter(Mandatory = $False)][String]$Product = "",

		[Parameter(Mandatory = $False)][Int]$TypeID,
		
		[Parameter(Mandatory = $False)][String]$TypeName = "",

		
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KPciandDisk]::GetSortableParameters([KPciandDisk]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KPciandDisk]::GetSortableParameters([KPciandDisk]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "Product"
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
			SortBy = $SortBy
			Filters = @(
				"substringof('$Product',Product)",
				"substringof('$Vendor',Vendor)",
				"substringof('$TypeName',TypeName)"
			)
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		if ($TypeID) {
			$ParamHash.Filters = $ParamHash.Filters + "TypeId eq $TypeID"
		}

		foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/hardware/pcianddisk"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="AgentId";E={$Id}} | Write-Output
		}
	}
}

<#
.SYNOPSIS
returns an array of printers and ports configured on an agent machine.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER PrinterName
Filter results to only include printers with this string in the printer's name.

.PARAMETER Port
Filter results to only include printers with this string in the port field.

.PARAMETER Model
Filter results to only include printers with this string in the model field.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KPrinter] with the [Sortable] attribute

.EXAMPLE
# Get a list of printers on the current computer.
Get-KPrinters -ComputerName $ENV:COMPUTERNAME -Port "10.0.0" | Select PrinterName, Port

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32447.htm
#>
Function Get-KPrinters
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

		[Parameter(Mandatory=$False)][String]$PrinterName,
		[Parameter(Mandatory=$False)][String]$Port,
		[Parameter(Mandatory=$False)][String]$Model,

		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KPrinter]::GetSortableParameters([KPrinter]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KPrinter]::GetSortableParameters([KPrinter]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "PrinterName"
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
			SortBy = $SortBy
			Filters = @(
				"substringof('$PrinterName',PrinterName)",
				"substringof('$Port',Port)",
				"substringof('$Model',Model)"
			)
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/hardware/printers"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="AgentId";E={$Id}} | Write-Output
		}
	}
}


<#
.SYNOPSIS
Returns an array of security products installed on the agent machine.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER ProductType
Filter the results to only include products of this type.

.PARAMETER ProductName
Filter the results to only include products with this string in the product name.

.PARAMETER Manufacturer
Filter the results to only include products by this manufacturer

.PARAMETER IsActive
Only include active products

.PARAMETER IsUpToDate
Only include up-to-date results.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KSecurityProduct] with the [Sortable] attribute

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32457.htm
#>
Function Get-KSecurityProducts
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

		[Parameter(Mandatory = $False)][String]$ProductType = "",
		[Parameter(Mandatory = $False)][String]$ProductName = "",
		[Parameter(Mandatory = $False)][String]$Manufacturer = "",
		[Parameter(Mandatory = $False)][Switch]$IsActive,
		[Parameter(Mandatory = $False)][Switch]$IsUpToDate,

		
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KSecurityProduct]::GetSortableParameters([KSecurityProduct]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KSecurityProduct]::GetSortableParameters([KSecurityProduct]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "ProductName"
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
			Filters = @(
				"substringof('$ProductType',ProductType)",
				"substringof('$ProductName',ProductName)",
				"substringof('$Manufacturer',Manufacturer)"
				
			)
			SortBy = $SortBy
		}


		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}
		
		if ($IsActive) {
			$ParamHash.Filters = $ParmaHash.Filters + "IsActive eq true"
		}

		if ($IsUpToDate) {
			$ParamHash.Filters = $ParmaHash.Filters + "IsUpToDate eq true"
		}
		
		foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/software/securityproducts"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="AgentId";E={$Id}} | Write-Output
		}
	}
}


<#
.SYNOPSIS
Returns an array of licenses used by the agent machine.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER Publisher
Filter by the software publisher.

.PARAMETER ProductName
Filter by the product name.

.PARAMETER ProductKey
Filter by the product key. Many entries won't list their product key.

.PARAMETER LicenseCode
Filter by the license code.

.PARAMETER Version
Filter by the product version.

.PARAMETER InstalledBefore
Only include software installed before a certain date.

.PARAMETER InstalledAfter
Only include software installed after a certain date.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KLicense] with the [Sortable] attribute

.EXAMPLE
# Get a list of all Windows 10 licenses assigned to each agent.
Get-KSoftwareLicenses | Where-Object {$_.ProductName -like "Windows 10*"} | Select AgentId, ProductKey

.EXAMPLE
# Forces an update on all Office applications that are on an old version.
# Update-O365 just calls:
#		OfficeC2RClient.exe" /update USER displaylevel=False
Get-KSoftwareLicenses | ? {$_.ProductName -like "*Office*" -and $_.Version -like "16.0.6366.2062"} | `
	Start-KAgentProcedure -AgentProcedureName "Update-O365"

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#32455.htm

#>
Function Get-KSoftwareLicenses
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

		[Parameter(Mandatory = $False)][String]$Publisher = "",
		[Parameter(Mandatory = $False)][String]$ProductName = "",
		[Parameter(Mandatory = $False)][String]$ProductKey = "",
		[Parameter(Mandatory = $False)][String]$LicenseCode = "",
		[Parameter(Mandatory = $False)][String]$Version = "",
		[Parameter(Mandatory = $False)][DateTime]$InstalledBefore,
		[Parameter(Mandatory = $False)][DateTime]$InstalledAfter,

		
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KLicense]::GetSortableParameters([KLicense]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KLicense]::GetSortableParameters([KLicense]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "ProductName"
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
			Filters = @(
				"substringof('$Publisher',Publisher)",
				"substringof('$ProductName',ProductName)",
				"substringof('$ProductKey',ProductKey)",
				"substringof('$LicenseCode',LicenseCode)",
				"substringof('$Version',Version)"
			)
			SortBy = $SortBy
		}


		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		if ($InstalledBefore) {
			$ParamHash.Filters = $ParamHash.Filters + "InstallationDate le DATETIME'$(Format-Time -Time $InstalledBefore -LongFormat)'"
		}

		if ($InstalledAfter) {
			$ParamHash.Filters = $ParamHash.Filters + "InstallationDate ge DATETIME'$(Format-Time -Time $InstalledAfter -LongFormat)'"
		}

		
		foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/software/licenses"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="AgentId";E={$Id}} | Write-Output
		}
	}
}



<#
.SYNOPSIS
Returns an array of startup apps on the agent machine.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER AppName
Filter results by the application name.

.PARAMETER AppCommand
Filter results by the application command (file path with arguments).

.PARAMETER UserName
Filter results by the user that this application will start automatically for.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KStartupApp] with the [Sortable] attribute

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33625.htm
#>
Function Get-KStartupApps
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

		[Parameter(Mandatory = $False)][String]$AppName = "",
		[Parameter(Mandatory = $False)][String]$AppCommand = "",
		[Parameter(Mandatory = $False)][String]$UserName = "",
		
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KStartupApp]::GetSortableParameters([KStartupApp]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KStartupApp]::GetSortableParameters([KStartupApp]).Name
			}
		)]
		[Parameter(Mandatory=$False)][String]$SortBy = "AppName"
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
			Filters = @(
				"substringof('$AppName',AppName)",
				"substringof('$AppCommand',AppCommand)",
				"substringof('$UserName',UserName)"
			)
			SortBy = $SortBy
		}


		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}
		
		foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/software/startupapps"
			Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="AgentId";E={$Id}} | Write-Output
		}
	}
}



<#
.SYNOPSIS
Returns the purchase date and warranty expiration date for a single agent.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38514.htm
#>
Function Get-KWarrantyExpirationDates
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
			URI = "$VSA/assetmgmt/audit"
			Method = "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}
		
		foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/hardware/purchaseandwarrantyexpire"
			Invoke-RestMethod @ParamHash | Select-Object *, @{N="AgentId";E={$Id}} | Write-Output
		}
	}
}


<#
.SYNOPSIS
Updates the purchase date and warranty expiration date for an agent.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER PurchaseDate
Set when the device was purchased.

.PARAMETER WarrantyExpirationDate
Set when the warranty for the device expires.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38516.htm

#>
Function Set-KWarrantyExpirationDates
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

		[Parameter(Mandatory = $False)][DateTime]$PurchaseDate,
		[Parameter(Mandatory = $False)][DateTime]$WarrantyExpirationDate
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{
		$ParamHash = @{
			URI = "$VSA/assetmgmt/audit"
			Method = "PUT"
			Headers = @{ "Authorization" = "Bearer $Token" }
			Body = @{ }
			ContentType = "application/json"
		}

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
		}

		if ($PurchaseDate) {
			$ParamHash.Body["PurchaseDate"] = Format-Time -Time $PurchaseDate -LongFormat
		}

		if ($WarrantyExpirationDate) {
			$ParamHash.Body["WarrantyExpireDate"] = Format-Time -Time $WarrantyExpirationDate -LongFormat
		}

		#$ParamHash.Body = $ParamHash.Body | ConvertTo-JSON -Depth 5
		foreach ($Id in $AgentId)
		{
			$ParamHash.URI = "$VSA/assetmgmt/audit/$Id/hardware/purchaseandwarrantyexpire"
			Invoke-AdvancedRestMethod @ParamHash | Write-Output
		}
	
	}
}


<#
.SYNOPSIS
Runs a baseline audit immediately for an agent.

Warning:	This command will remove any previously scheduled, recurring audit scans.
			If your audit scans are applied in a policy, the recurring audit scan that you set 
			in the browser will be re-applied during the next compliance check in Policy Management->Configure->Settings.

.DESCRIPTION
A baseline audit shows the configuration of the system in its original state. Typically a baseline audit is performed when a system is first set up.
The latest audit shows the configuration of the system as of the last audit.
The sysinfo audit shows all DMI / SMBIOS data of the system as of the last system info audit. This data seldom changes and typically only needs to be run once.

.PARAMETER ComputerName
Look for agents that include this in their computer name.

.PARAMETER AgentID
Look for agents of these AgentIds.

.PARAMETER AuditType
The type of audit to start. Latest is the default and most common.

.PARAMETER Scheduled
Specifies that you want to use the dynamic parameters for scheduling.

.PARAMETER Recurrence
Specifies that you want to use the dynamic parameter for recurrence.

.PARAMETER DistributionInterval
The units of time to distribute this audit. Useful when running on a large batch of computers.

.PARAMETER DistributionMagnitude
The amount of units to distribute this audit.

.PARAMETER StartOn
The date to start the audit.

.PARAMETER ExcludeFrom
Exclude audits starting at this time. Only the hours, minutes, and seconds are used.

.PARAMETER ExcludeTo
Exclude audits until this time. Only the hours, minutes, and seconds are used.

.PARAMETER RepeatInterval
The unit of time to repeat this audit.

.PARAMETER RepeatMagnitude
The amount of units to repeat this audit.

.PARAMETER EndOn
Stop the recurrence on this date.

.LINK
Get-KAuditSummary
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31663.htm
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31765.htm
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31670.htm
#>
Function Start-KAudit
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

		
		[Parameter(Mandatory = $False)][ValidateSet("Baseline", "Latest", "SysInfo")][String]$AuditType = "Latest",

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

		return $RuntimeParameterDictionary
	}

	Begin
	{
		Ensure-Connected
	}
	
	Process
	{
		$Body  =  @{
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

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$AgentID = Get-KAgents -ComputerName $AgentName | Select-Object -Expand AgentID
		}

		Foreach ($Id in $AgentId) {

			$ParamHash = @{
				URI = "$VSA/assetmgmt/audit/$AuditType/$Id/schedule"
				Method = "PUT"
				Body = $Body
				Headers = @{'Authorization' = "Bearer $Token"}
				ContentType = "application/json"
			}
			Invoke-AdvancedRestMethod @ParamHash | Write-Output
		}
		
	}
}
