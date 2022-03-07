<#
.SYNOPSIS
Gets all inbox messages from the info center.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40780.htm
#>
Function Get-KInboxMessages
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/infocenter/messages"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
    }
}

<#
.SYNOPSIS
Sets the IsRead field on messages.
Not implemented.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40781.htm
#>
Function Set-KInboxMessageAsRead
{
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName)][string[]]$ID
    )
    
	Begin
	{
        Ensure-Connected
        throw "NOT IMPLEMENTED"
	}

	Process
	{
        $ParamHash = @{
            URI          =  "$VSA/infocenter/messages/true"
            Method 	     =  "PUT"
            Headers      =  @{ "Authorization" = "Bearer $Token" }
            Body         =  $MessageIds | ConvertTo-Json
            ContentType  =  "application/json"
        }

        Invoke-RestMethod @ParamHash | Write-Output
	}
}