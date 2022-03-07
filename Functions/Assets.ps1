<#
.SYNOPSIS
Gets a list of public IP addresses for every agent. It doesn't pair public IP with the specific agent.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40775.htm
#>
Function Get-KAgentConnectionGatewayIP
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI 	= "$VSA/assetmgmt/connectiongatewayips"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}


<#
.SYNOPSIS
Gets a list of all agent notes.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#40774.htm
#>
Function Get-KAgentNotes
{
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI 	= "$VSA/assetmgmt/agent/notes"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}


<#
.SYNOPSIS
Gets a list of all hardware assets. Not the same as agents.

.PARAMETER AssetName
Get all assets that include this in the name.

.PARAMETER AssetID
Get all assets with these AssetIds

.PARAMETER SortBy
Sorts the results by this property.

.PARAMETER AssetTypeName
Only get assets of this type.

.LINK
Get-KAssetTypes
Remove-KAsset
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31620.htm
#>
Function Get-KAssets
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (

		[Parameter(Mandatory = $False)]
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KAsset]::GetSortableParameters([KAsset]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KAsset]::GetSortableParameters([KAsset]).Name
			}
		)]
		[String]$SortBy = "AssetName",

		[Parameter(Mandatory = $False)]
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				Get-KAssetTypes -AssetTypeName $WordToComplete | Select-Object -Expand AssetTypeName
			}
		)]
		[ValidateScript(
			{
				$_ -in (Get-KAssetTypes -AssetTypeName $WordToComplete | Select-Object -Expand AssetTypeName)
			}
		)]
		[String]$AssetTypeName
		
	)

	
    DynamicParam{
        # Create a new dynamic parameter dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        # Get a list of all filterable parameters as defined in VorexDefinitions.cs
        $Filterables = [KAsset]::GetFilterableParameters([KAsset])

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
            URI 	= "$VSA/assetmgmt/assets"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
            Filters = @()
			SortBy 	= $SortBy
        }

		
		if ($AssetTypeName) {
			$Id= Get-KAssetTypes -AssetTypeName $AssetTypeName | Select-Object -First 1 -ExpandProperty AssetTypeId
			$ParamHash.Filters = $ParamHash.Filters + "AssetTypeId eq $($Id)M"
		}
		else {
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
		}

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Gets a list of all asset types.

.PARAMETER AssetTypeId
Gets an asset with this Id

.PARAMETER AssetTypeName
Gets assets with this in their AssetTypeName

.LINK
Get-KAssets
Remove-KAsset
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31646.htm
#>
Function Get-KAssetTypes
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $False)][String]$AssetTypeId = "",
		[Parameter(Mandatory = $False)][String]$AssetTypeName = ""
	)
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI = "$VSA/assetmgmt/assettypes"
            Method = "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
            Filters = @(
                "substringof('$AssetTypeName',AssetTypeName)"
            )
			SortBy = "AssetTypeName"
        }

        if ($AssetTypeId) {
            $ParamHash.Filters = $ParamHash.Filters + "AssetTypeId eq $($AssetTypeId)M"
        }

        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Removes an asset.

.PARAMETER AssetName
The name of the asset to remove. Does not support multiple assets.

.PARAMETER AssetId
The assetId for the asset to remove.

.PARAMETER ReadOnly
Don't remove the asset. Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.EXAMPLE
# Remove all assets that haven't been seen in more than 3 months
Get-KAssets | ? {$_.LastSeenDate -as [DateTime] -lt (Get-Date).AddMonths(-3)} | Foreach-Object { Remove-KAsset -AssetId $_.AssetId -Force }
#>
Function Remove-KAsset
{
	[CmdletBinding(DefaultParameterSetName="ById")]
	Param (
		[Parameter(Mandatory = $True, Position = 1, ParameterSetName = "ByName")][String]$AssetName,
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ByID")][String[]]$AssetID,
        [Parameter(Mandatory = $False)][Switch]$ReadOnly,
        [Parameter(Mandatory = $False)][Switch]$Force
	)
	Begin
	{
		Ensure-Connected
	}

	Process
	{

		if ($PSCmdlet.ParameterSetName -like "ByName") {
			$Ids = Get-KAssets -AssetName $AssetName | Select-Object -ExpandProperty AssetId
			if ($Ids.Count -eq 1) {
				$AssetId = $Ids
			}
			else {
				throw "$AssetName matches to $($Ids.Count) assets. This is not allowed for safety reasons."
			}
		}

        $ParamHash = @{
            URI 	= "$VSA/assetmgmt/assets/$AssetID"
            Method 	= "DELETE"
            Headers = @{"Authorization" = "Bearer $Token"}
		}

		if ($ReadOnly) {
			[PSCustomObject]$ParamHash | Write-Output
		}
		else {
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Remove asset for ($AssetId)?")) {
                    throw "Operation canceled by user."
                }
            }
			Invoke-AdvancedRestMethod @ParamHash | Write-Output
		}
	}
}
