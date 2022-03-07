<#
.SYNOPSIS
	Gets the Custom Field values for a specific agent. Appends the AgentID onto every custom field.

.PARAMETER ComputerName
	The ComputerName to get custom field data from. This field is automatically a wildcard; you do not need to supply *s. 
	It is not recommended to supply the ComputerName to Get-KAgentCustomFields through the pipeline. This is because everytime this function
	is called with ComputerName, it makes another call to Get-KAgents. It is much more efficient to use AgentID for pipeline input.
	But there is little difference in performance between:
		Get-KAgents -ComputerName IT- | Get-KAgentCustomFields
				-and-
		Get-KAgentCustomFields -ComputerName IT-

	This is because Get-KAgents is called once in both cases. But in this case, Get-KAgents is called once at the beginning and once for every KAgent that passes through the pipeline:
		Get-KAgents -ComputerName IT- | Select-Object ComputerName | Get-KAgentCustomFields

.PARAMETER AgentID
	An array of AgentIDs. This is the default parameter that will be used when piping input from KAgent. I made it the default for pipeline input
	because it is significantly faster to use the AgentID when piping from KAgent than when using ComputerName. 

.PARAMETER FieldName
	Optionally, specify the field name substring that you want to filter with. The filter is done after the data has been received from the API,
	so there is no performance benefit from using this.

.EXAMPLE
	# A good way to get all IT custom field values
	Get-KAgents -ComputerName IT- | Get-KAgentCustomFields

.EXAMPLE
	# Another good way to get all IT custom field values
	Get-KAgentCustomFields -ComputerName IT-

.EXAMPLE
	# This way is bad because it removes the AgentID property before piping, forcing it to use ComputerName.
	# This causes MANY redundant API queries.
	Get-KAgents -ComputerName IT- | Select-Object ComputerName, CurrentUser, OSInfo | Get-KAgentCustomFields 

.EXAMPLE
	# Gets all agents that have SMB1 enabled and runs an agent procedure to disable it. 
	Get-KAgentCustomFields -FieldName "SMB1 Status" | Where-Object {$_.FieldValue -like "Enabled"} | Foreach-Object {
		Start-KAgentProcedure -ProcedureName "Disable SMB1" -AgentID $_.AgentID
	}

.LINK
	New-KAgentCustomField
	Remove-KAgentCustomField
	Rename-KAgentCustomField
	Set-KAgentCustomField
	http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37928.htm

#>
Function Get-KAgentCustomFields
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,
        [Parameter(Mandatory = $False)][String]$FieldName
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
            $AgentID = Get-KAgents -ComputerName $ComputerName | Select-Object -ExpandProperty AgentId
		}
		
		foreach ($Id in $AgentId)
		{
			Invoke-AdvancedRestMethod @ParamHash -URI "$VSA/assetmgmt/assets/$Id/customfields" | `
				Where-Object {$_.FieldName -like "*$FieldName*"} | Select-Object *, @{N="AgentID";E={$Id}} | Write-Output
		}
	}
}

<#
.SYNOPSIS
Creates a new Custom Field. Use this when the field doesn't exist globally yet.
If you want to set an existing custom field on an agent, use Set-KAgentCustomField.

.PARAMETER FieldName
The name of the field that you will add. Must be a new field and can contain spaces.

.PARAMETER FieldType
The datatype of the field that you will add. Must be one of the following:
"string", "int", "decimal", "datetime", "object", "boolean"

.EXAMPLE
# Creates a field to pair an Agent with a DeskNumber.
New-KAgentCustomField -FieldName "DeskNumber" -FieldType int

.EXAMPLE
Import-CSV "C:\temp\NewFields.csv" | % { New-KAgentCustomField -FieldName $_.FieldName -FieldType $_.FieldType }
.LINK
    Get-KAgentCustomFields
    Remove-KAgentCustomField
    Rename-KAgentCustomField
    Set-KAgentCustomField
    http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37947.htm
#>
Function New-KAgentCustomField
{
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True)][String]$FieldName,
        [Parameter(Mandatory=$True)][ValidateSet("string", "int", "decimal", "datetime", "object", "boolean")][String]$FieldType
	)
	Begin
	{
		Ensure-Connected
	}
	Process
	{
        $ParamHash = @{
            URI = "$VSA/assetmgmt/assets/customfields"
            Method = "POST"
            ContentType = "application/json"
            Headers = @{ "Authorization" = "Bearer $Token" }
            Body = @(
                @{ key = "FieldName"; value = "$FieldName" },
                @{ key = "FieldType"; value = "$FieldType" }
            ) | ConvertTo-JSON
        }
        Invoke-RestMethod @ParamHash | Write-Output
	}
}


<#
.SYNOPSIS
Removes a Custom Field. This removes it globally, not just on one device. For this reason, you can not use
wildcards, and it will prompt you for confirmation before it removes the field.

.PARAMETER FieldName
The name of the field you want to remove. Wildcards do not work here, you MUST specify the full name.

.PARAMETER Force
Ignores the DisableConfirmations value and removes the field without prompting.

.EXAMPLE
# Good!
Remove-KAgentCustomField -FieldName "Some Stupid Field"

# Not good! Someone might get very upset about this if I allowed it.
Remove-KAgentCustomField -FieldName ""

.LINK
	New-KAgentCustomField
	Get-KAgentCustomFields
    Rename-KAgentCustomField
	Set-KAgentCustomField
	http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37931.htm
#>
Function Remove-KAgentCustomField
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)][String]$FieldName,
		[Parameter(Mandatory=$False)][Switch]$Force
	)
	Begin
	{
		Ensure-Connected
	}
	Process
	{
        $ParamHash = @{
            URI = "$VSA/assetmgmt/assets/customfields/$FieldName"
            Method = "DELETE"
            Headers = @{ "Authorization" = "Bearer $Token" }
		}
		# If confirm is enabled and we don't specify to force it.
		if (!$DisableKConfirmations -and !$Force.IsPresent) {
			if (!(Get-Confirmation -Message "Remove KCustomField: $FieldName`nURL: $($ParamHash.URI)")) {
				throw "Operation canceled by user."
			}
		}
        Invoke-RestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Renames an existing custom field. You must specify the full field name, no wildcards are used.

.PARAMETER FieldName
The field that will be renamed.

.PARMAETER NewName
The new name of the field.

.EXAMPLE
# Rename a field to fix a typo.
Rename-KAgentCustomField -FieldName "Security Profile" -NewName "Security Profile"

.LINK
	New-KAgentCustomField
    Get-KAgentCustomFields
    Remove-KAgentCustomField
	Set-KAgentCustomField
	http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37932.htm
#>
Function Rename-KAgentCustomField
{
	[CmdletBinding()]
	Param (

        [Parameter(Mandatory=$True)][String]$FieldName,
        [Parameter(Mandatory=$True)][String]$NewName
	)
	Begin
	{
		Ensure-Connected
	}
	Process
	{
        $ParamHash = @{
            URI = "$VSA\assetmgmt\assets\customfields\$FieldName"
            Method = "PUT"
            ContentType = "application/json"
            Headers = @{ 
                "Authorization" = "Bearer $Token" 
            }
            Body = "[
                {
                `"key`": `"NewFieldName`",
                `"value`": `"$NewName`"
                }
            ]"
        }

        Invoke-RestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Sets the value of a custom field on an agent. Specify Force to create a new custom field if one does not yet exist.

.PARAMETER ComputerName
The computer name of the agent. It's a substring by default, no need to use *'s.

.PARAMETER AgentIDs
An array of agent IDs. This is what is used when passing a KAgent through the pipeline.

.PARAMETER FieldName
The name of the field to set. If this field doesn't exist, it won't create a field 

.PARAMETER NewValue
The new value that the field will have. It's an object so that we can supply many different types of values.

.PARAMETER FieldType
The type of the field. This is used to cast the NewValue to what Kaseya is expecting.


.PARAMETER Force
If the field doesn't exist, force will create it and try setting the value again.

.EXAMPLE
# Assign a random number to every computer.
Get-KAgents | Foreach-Object { Set-KAgentCustomField -AgentID $_.AgentID -FieldName "Random Number" -NewValue (Get-Random) }


# Assign a random number to every computer and create the field if it doesn't exist yet.
Get-KAgents | Foreach-Object { Set-KAgentCustomField -AgentID $_.AgentID -FieldName "Random Number" -NewValue (Get-Random) -Force }

.LINK
	New-KAgentCustomField
    Remove-KAgentCustomField
    Rename-KAgentCustomField
    Get-KAgentCustomFields
	http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37930.htm

#>
Function Set-KAgentCustomField
{
	[CmdletBinding(DefaultParameterSetName="ByID")]
	Param (
		[Parameter(Mandatory = $True, ParameterSetName = "ByName", ValueFromPipelineByPropertyName)][String]$ComputerName,
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$AgentID,

        [Parameter(Mandatory=$True)][String]$FieldName,
        [Parameter(Mandatory=$True)][String]$NewValue,
        [Parameter(Mandatory=$True)][ValidateSet("string", "int", "decimal", "datetime", "object", "boolean")][String]$FieldType,
        [Parameter(Mandatory=$False)][Switch]$Force
	)
	Begin
	{
		Ensure-Connected
	}
	Process
	{
        $ParamHash = @{
            Method = "PUT"
            ContentType = "application/json"
            Headers = @{ 
                "Authorization" = "Bearer $Token" 
            }
            Body = "[
                {
                `"key`": `"FieldValue`",
                `"value`": `"$NewValue`"
                }
            ]"
        }

        if ($PSCmdlet.ParameterSetName -like "ByName") {
            $AgentIDs = Get-KAgents -ComputerName $ComputerName | Select-Object -ExpandProperty AgentID
        }

        try {
            $AgentIDs | Foreach-Object { Invoke-RestMethod @ParamHash -URI "$VSA\assetmgmt\assets\$_\customfields\$FieldName" } | Write-Output
        }
        catch {

            # If the field doesn't exist and we specified force, create the field and retry without Force (that prevents an infinite loop)
            if ($_.ErrorDetails -like "*No custom field found with specified name*" -and $Force.IsPresent) {
                New-KAgentCustomField -FieldName $FieldName -FieldType $FieldType
                Set-KAgentCustomField -AgentID $AgentIDs -FieldName $FieldName -FieldType $FieldType -NewValue $NewValue
            }
            else {
                throw $_
            }
        }
        
	}
}