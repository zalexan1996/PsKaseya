<#
.SYNOPSIS
Returns an array of scope records.

.PARAMETER ScopeId
Get scopes with these ids.

.PARAMETER ScopeName
Only get scopes that have this value in the ScopeName.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31722.htm

#>
Function Get-KScopes
{
	[CmdletBinding(DefaultParameterSetName="ByName")]
	Param (
		[Parameter(Mandatory = $False, Position = 1, ParameterSetName = "ByName")][AllowEmptyString()][String]$ScopeName = "",
        [Parameter(Mandatory = $True, ParameterSetName = "ByID", ValueFromPipelineByPropertyName)][String[]]$ScopeId
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{

		$ParamHash = @{
			URI     = "$VSA/system/scopes"
			Method 	= "GET"
			Headers = @{"Authorization" = "Bearer $Token"}
			Filters = @(
				"substringof('$ScopeName',ScopeName)"
            )
            SortBy = "ScopeName"
		}

        if ($PSCmdlet.ParameterSetName -like "ByID")
        {
			$ParamHash.Filters = $ParamHash.Filters + (($ScopeId | Foreach-Object {"ScopeId eq $($_)M"}) -join " or ")
        }
        Invoke-AdvancedRestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38537.htm

.PARAMETER ScopeName
The name of the scope to add.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38537.htm
#>
Function New-KScope
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)][String]$ScopeName
	)

	Begin
	{
		Ensure-Connected
	}
	Process
	{
		$ParamHash = @{
			URI     = "$VSA/system/scopes"
			Method 	= "POST"
			Headers = @{"Authorization" = "Bearer $Token"}
            Body = @{
                "ScopeName" = $ScopeName
            } | ConvertTo-Json
            ContentType="application/json"
		}
        Invoke-RestMethod @ParamHash | Write-Output
	}
}

<#
.SYNOPSIS
Deletes a single scope record.

.PARAMETER ScopeId
Delete the scope with this id.

.PARAMETER ScopeName
Delete the scope with this name.

.PARAMETER ReadOnly
Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38538.htm
#>
Function Remove-KScope
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True, ParameterSetName="ByID", ValueFromPipelineByPropertyName)][string]$ScopeId,
		[Parameter(Mandatory=$True, ParameterSetName="ByName")][String]$ScopeName,
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

            $ids = (Get-KScopes -ScopeName $ScopeName | Select-Object -Expand ScopeId)
            if ($Ids.Count -ne 1) {
                throw "$ScopeName matches to multiple scopes!`nFor safety reasons, you can only delete one scope at a time."
            }
            else {
                $ScopeId = $ids
            }
        }


		$ParamHash = @{
            URI = "$VSA/system/scopes/$ScopeId"
			Method 	= "DELETE"
			Headers = @{"Authorization" = "Bearer $Token"}
		}
		
		if ($ReadOnly.IsPresent)
		{
			[PSCustomObject]$ParamHash | Write-Output
		}
		else 
		{
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Remove Scope for ($ScopeId)?")) {
                    throw "Operation canceled by user."
                }
            }
			Invoke-RestMethod @ParamHash | Write-Output
		}
        
	}
}
