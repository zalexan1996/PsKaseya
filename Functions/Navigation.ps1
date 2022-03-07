<#
.SYNOPSIS
Gets information about recent admin activity.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40759.htm

#>
Function Get-KAdminActivity
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$($VSA -replace "v1.0", "v1.5")/navigation/header/onlineadmins"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
    }
}
<#
.SYNOPSIS
Gets an online/offline status for several types of agents.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40758.htm
#>
Function Get-KAgentStatus
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$($VSA -replace "v1.0", "v1.5")/navigation/header/agentsstatus"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
    }
}

<#
.SYNOPSIS
Gets alerts for a user.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40760.htm
#>
Function Get-KAlerts
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$($VSA -replace "v1.0", "v1.5")/navigation/header/alerts"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
    }
}

<#
.SYNOPSIS
Gets whether the classic UI is enabled or not for the current user.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40762.htm

#>
Function Get-ClassicUIEnabled
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$($VSA -replace "v1.0", "v1.5")/navigation/classicenabled"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
    }
}

<#
.SYNOPSIS
Gets a title and icon foro the VSA partition associated with the current user.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40757.htm
#>
Function Get-KHeader
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$($VSA -replace "v1.0", "v1.5")/navigation/header"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
    }
}

<#
.SYNOPSIS
Gets all notifications including server notifications if the user's role is Master.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40761.htm
#>
Function Get-KNotifications
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$($VSA -replace "v1.0", "v1.5")/navigation/header/notifications"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
    }
}