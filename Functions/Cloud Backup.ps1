Function Get-KCloudBackupServers
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/kcb/servers"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

Function Get-KCloudBackupVirtualMachines
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/kcb/virtualmachines"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

Function Get-KCloudBackupWorkstations
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/kcb/workstations"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}