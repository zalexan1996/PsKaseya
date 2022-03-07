<#
.SYNOPSIS
Uploads a file from your local computer or network to an agent's documents.
Not implemented.
#>
Function Add-KDocument
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AgentID,
        [Parameter(Mandatory = $True)][ValidateScript({Test-Path -Path $_})][String]$FilePath,
        [Parameter(Mandatory = $False)][String]$DestinationPath = ""
    )
    
	Begin
	{
        Ensure-Connected
        throw "NOT IMPLEMENTED"
		
	}

	Process
	{
        $ParamHash = @{
            Method 	= "PUT"
            Headers = @{"Authorization" = "Bearer $Token"}
            ContentType = "multipart/form-data"
            Body = @{
                key = [IO.File]::ReadAllText("$FilePath")
            }
        }
        
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
        }

        $AgentID | Foreach-Object { Invoke-RestMethod @ParamHash -URI "$VSA/assetmgmt/documents/$_/file/$DestinationPath"} | Write-Output
	}
}

<#
.SYNOPSIS
Returns an array of uploaded documents from an agent.

.PARAMETER ComputerName
Get agents that include this in their computer name.

.PARAMETER AgentID
A list of agent IDs to get agent objects for.

.PARAMETER Path
The path to a file.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33637.htm
#>
Function Get-KDocuments
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AgentID,
        [Parameter(Mandatory = $False)][String]$Path = "/"
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
        }

        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
        }

        $AgentID | Foreach-Object { Invoke-AdvancedRestMethod @ParamHash -URI "$VSA/assetmgmt/documents/$_/folder/$Path"} | Write-Output
	}
}

<#
.SYNOPSIS
Removes a document from an agent.

.PARAMETER ComputerName
Get agents that include this in their computer name.

.PARAMETER AgentID
A list of agent IDs to get agent objects for.

.PARAMETER Path
The path to a file.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33639.htm

#>
Function Remove-KDocument
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AgentID,
        [Parameter(Mandatory = $True)][String]$Path
    )
    
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            Method 	= "DELETE"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
        }

        $AgentID | Foreach-Object { Invoke-AdvancedRestMethod @ParamHash -URI "$VSA/assetmgmt/documents/$_/$Path"} | Write-Output
	}
}

<#
.SYNOPSIS
Returns the content of a document.

.PARAMETER ComputerName
Get agents that include this in their computer name.

.PARAMETER AgentID
A list of agent IDs to get agent objects for.

.PARAMETER FilePath
The path to a file.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33637.htm
#>
Function Show-KDocument
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ComputerName = "",
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AgentID,
        [Parameter(Mandatory = $True)][String]$FilePath
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
        }

        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -Expand AgentID
        }

        $AgentID | Foreach-Object { Invoke-RestMethod @ParamHash -URI "$VSA/assetmgmt/documents/$_/file/$FilePath"} | Write-Output
	}
}
