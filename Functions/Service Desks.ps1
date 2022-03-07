<#
.SYNOPSIS
Returns an array of priorities for a specified service desk.

.PARAMETER ServiceDeskId
The Id of the Service Desk to get the priorities for.

.PARAMETER ServiceDeskName
The Name of the Service Desk to get the priorities for.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37939.htm
#>
Function Get-KServiceDeskPriorities
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
        [Parameter(Mandatory=$True,ParameterSetName="ById", ValueFromPipelineByPropertyName)][String[]]$ServiceDeskId,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")][String]$ServiceDeskName = ""
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $ServiceDeskId = Get-KServiceDesks -ServiceDeskName $ServiceDeskName | Select-Object -Expand ServiceDeskId
        }

        foreach ($Id in $ServiceDeskId) {
            $ParamHash = @{
                URI = "$VSA/automation/servicedesks/$Id/priorities"
                Method 	= "GET"
                Headers = @{"Authorization" = "Bearer $Token"}
            }
    
            Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="ServiceDeskId";E={$Id}} | Write-Output
        }
	}
}

<#
.SYNOPSIS
Returns an array of service desk definitions.

.PARAMETER ServiceDeskId
Gets Service Desks with these Ids.

.PARAMETER ServiceDeskName
Gets Service Desks with this name.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KServiceDesk] with the [Sortable] attribute

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37933.htm
#>
Function Get-KServiceDesks
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
        [Parameter(Mandatory=$True,ParameterSetName="ById", ValueFromPipelineByPropertyName)][String[]]$ServiceDeskId,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")][String]$ServiceDeskName = "",
		[Parameter(Mandatory = $False)]
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KServiceDesk]::GetSortableParameters([KServiceDesk]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KServiceDesk]::GetSortableParameters([KServiceDesk]).Name
			}
		)]
		[String]$SortBy = "ServiceDeskName"
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/automation/servicedesks"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
            Filters = @(
                "substringof('$ServiceDeskName', ServiceDeskName)"
            )
        }

        if ($PSCmdlet.ParameterSetName -like "ById") {
			$ParamHash.Filters = $ParamHash.Filters + (($ServiceDeskId | Foreach-Object {"ServiceDeskId eq $($_)M"}) -join " or ")
		}
		
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Returns an array of ticket categories for a specified service desk.

.PARAMETER ServiceDeskId
Gets Ticket Categories from these Service Desks

.PARAMETER ServiceDeskName
Gets Ticket Categories from Service Desks with this value in the name.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37934.htm
#>
Function Get-KTicketCategories
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
        [Parameter(Mandatory=$True,ParameterSetName="ById", ValueFromPipelineByPropertyName)][String[]]$ServiceDeskId,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")][String]$ServiceDeskName = ""
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        
        $Ids = $ServiceDeskId
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $Ids = Get-KServiceDesks -ServiceDeskName $ServiceDeskName | Select-Object -Expand ServiceDeskId
        }

        foreach ($Id in $Ids) {
            $ParamHash = @{
                URI = "$VSA/automation/servicedesks/$Id/categories"
                Method 	= "GET"
                Headers = @{"Authorization" = "Bearer $Token"}
            }
    
            Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="ServiceDeskId";E={$Id}} | Write-Output
        }
	}
}

<#
.SYNOPSIS
Returns an array of notes for a specified service desk ticket.

.PARAMETER ServiceDeskTicketId
Gets the Ticket Notes from this ticket.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37950.htm
#>
Function Get-KTicketNotes
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName)][Alias("TicketId")][String]$ServiceDeskTicketId
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{

        $ParamHash = @{
            URI = "$VSA/automation/servicedesktickets/$ServiceDeskTicketId/notes"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
        
	}
}

<#
.SYNOPSIS
Returns an array of tickets for a specified service desk.

.PARAMETER ServiceDeskId
Get tickets from this Service Desk.

.PARAMETER ServiceDeskName
Get tickets from Service Desks with this value in the Service Desk Name.

.PARAMETER SubmitterEmail
Get tickets created by this user email address.

.PARAMETER SubmitterName
Get tickets created from this person.

.PARAMETER TicketStatus
Only get tickets in this status. Acceptable values are generated by calling Get-KTicketStatuses

.PARAMETER Priority
Only get tickets of this priority. Acceptable values are generated by calling Get-KServiceDeskPriorities

.PARAMETER Category
Only get tickets in this category. Acceptable values are generated by calling Get-KTicketCategories

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KTicket] with the [Sortable] attribute

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33692.htm
#>
Function Get-KTickets
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
        [Parameter(Mandatory=$True,ParameterSetName="ById", ValueFromPipelineByPropertyName)][String]$ServiceDeskId,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")][String]$ServiceDeskName = "",
		[Parameter(Mandatory = $False)][String]$SubmitterEmail = "",
		[Parameter(Mandatory = $False)][String]$SubmitterName = "",

		[Parameter(Mandatory = $False)]
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KTicket]::GetSortableParameters([KTicket]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KTicket]::GetSortableParameters([KTicket]).Name
			}
		)]
		[String]$SortBy = "Summary"
	)
	
	
	DynamicParam {
		$RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		if ($PSCmdlet.ParameterSetName -like "ById")
		{
			$RuntimeParameterDictionary.Add("TicketStatus", (New-DynamicParameter -Name "TicketStatus" -Type ([string]) `
				-ValidateSet (Get-KTicketStatuses -ServiceDeskId $PSBoundParameters.ServiceDeskId | Select-Object -Expand StatusName)))
	
			$RuntimeParameterDictionary.Add("Priority", (New-DynamicParameter -Name "Priority" -Type ([string]) `
				-ValidateSet (Get-KServiceDeskPriorities -ServiceDeskId $PSBoundParameters.ServiceDeskId | Select-Object -Expand PriorityName)))
	
			$RuntimeParameterDictionary.Add("Category", (New-DynamicParameter -Name "Category" -Type ([string]) `
				-ValidateSet (Get-KTicketCategories -ServiceDeskId $PSBoundParameters.ServiceDeskId | Select-Object -Expand CategoryName)))

		}
		elseif ($PSCmdlet.ParameterSetName -like "ByName")
		{
			$RuntimeParameterDictionary.Add("TicketStatus", (New-DynamicParameter -Name "TicketStatus" -Type ([string]) `
				-ValidateSet (Get-KTicketStatuses -ServiceDeskName $PSBoundParameters.ServiceDeskName | Select-Object -Expand StatusName)))
	
			$RuntimeParameterDictionary.Add("Priority", (New-DynamicParameter -Name "Priority" -Type ([string]) `
				-ValidateSet (Get-KServiceDeskPriorities -ServiceDeskName $PSBoundParameters.ServiceDeskName | Select-Object -Expand PriorityName)))
	
			$RuntimeParameterDictionary.Add("Category", (New-DynamicParameter -Name "Category" -Type ([string]) `
				-ValidateSet (Get-KTicketCategories -ServiceDeskName $PSBoundParameters.ServiceDeskName | Select-Object -Expand CategoryName)))

		}


		return $RuntimeParameterDictionary
	}
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $Ids = $ServiceDeskId
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $Ids = Get-KServiceDesks -ServiceDeskName $ServiceDeskName | Select-Object -Expand ServiceDeskId
        }

        foreach ($Id in $Ids) {
            $ParamHash = @{
                URI = "$($VSA)/automation/servicedesks/$Id/tickets"
                Method 	= "GET"
                Headers = @{"Authorization" = "Bearer $Token"}
                Filters = @(
					"substringof('$SubmitterEmail', SubmitterEmail)",
					"substringof('$SubmitterName', Submitter)"
				)
			}

			if ($PSBoundParameters.TicketStatus) {
				$ParamHash.Filters = $ParamHash.Filters + "substringof('$($PSBoundParameters.TicketStatus -replace ' ', '')', TicketStatus)"
			}
			if ($PSBoundParameters.Priority) {
				$ParamHash.Filters = $ParamHash.Filters + "substringof('$($PSBoundParameters.Priority -replace ' ', '')', Priority)"
			}
			if ($PSBoundParameters.Category) {
				$ParamHash.Filters = $ParamHash.Filters + "substringof('$($PSBoundParameters.Category -replace ' ', '')', Category)"
			}
    
            Invoke-AdvancedRestMethod @ParamHash | Write-Output
        }
	}
}

<#
.SYNOPSIS
Returns an array of ticket statuses for a specified service desk.

.PARAMETER ServiceDeskId
Get statuses from this Service Desk.

.PARAMETER ServiceDeskName
Get statuses from Service Desks with this value in the Service Desk Name.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33694.htm
#>
Function Get-KTicketStatuses
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
        [Parameter(Mandatory=$True,ParameterSetName="ById", ValueFromPipelineByPropertyName)][String]$ServiceDeskId,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")][String]$ServiceDeskName = ""
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $Ids = $ServiceDeskId
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $Ids = Get-KServiceDesks -ServiceDeskName $ServiceDeskName | Select-Object -Expand ServiceDeskId
        }

        foreach ($Id in $Ids) {
            $ParamHash = @{
                URI = "$VSA/automation/servicedesks/$Id/status"
                Method 	= "GET"
                Headers = @{"Authorization" = "Bearer $Token"}
            }
    
            Invoke-AdvancedRestMethod @ParamHash | Select-Object *, @{N="ServiceDeskId";E={$Id}} | Write-Output
        }
	}
}