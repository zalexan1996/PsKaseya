<#
.SYNOPSIS
Returns all possible admin tasks that can be created for WorkTypeId
.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40786.htm
#>
Function Get-KAdminTask
{    
	Begin
	{
		Ensure-Connected
        throw "Not implemented due to inconsistencies in the help pages.`nhttp://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40786.htm"
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/system/sessiontimers/admintasks"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        Invoke-RestMethod @ParamHash -Verbose | Write-Output
        
	}
}
<#
.SYNOPSIS
Returns all customers in scopse of the sessionId.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40788.htm
#>
Function Get-KCustomers
{    
	Begin
	{
		Ensure-Connected
        throw "Not implemented due to inconsistencies in the help pages.`nhttp://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40788.htm"
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/system/customers"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
        
	}
}
<#
.SYNOPSIS
Returns all of the session timers associated with the sessionId.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40796.htm
#>
Function Get-KSessionTimers
{    
	Begin
	{
		Ensure-Connected
        throw "Not implemented due to inconsistencies in the help pages.`nhttp://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40796.htm"
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/system/sessiontimers"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
        
	}
}