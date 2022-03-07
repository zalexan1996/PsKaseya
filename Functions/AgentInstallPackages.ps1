<#
.SYNOPSIS
Gets a list of all install packages. Currently not supported.
#>
Function Get-KAgentInstallPackages
{
	Begin
	{
		Ensure-Connected
        throw "Not implemented due to inconsistencies in the help pages.`nhttp://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38503.htm"
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/assetmgmt/assets/packages"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}