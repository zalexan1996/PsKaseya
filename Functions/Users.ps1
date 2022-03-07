<#
.SYNOPSIS
Returns an array of user account records.

.PARAMETER UserId
Get the user account record for this user id.

.PARAMETER AdminName
Get user account records with this AdminName.

.PARAMETER FirstName
Get user account records with this FirstName.

.PARAMETER LastName
Get user account records with this LastName.

.PARAMETER Email
Get user account records with this Email.

.PARAMETER SortBy
Sorts the results by this property. It gets a list of sortable properties by looking
for all properties in [KUser] with the [Sortable] attribute

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31747.htm
#>
Function Get-KUsers
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $False)][Int]$UserId = -1,
		[Parameter(Mandatory = $False)][String]$AdminName = "",
		[Parameter(Mandatory = $False)][String]$FirstName = "",
		[Parameter(Mandatory = $False)][String]$LastName = "",
		[Parameter(Mandatory = $False)][String]$Email = "",
		[Parameter(Mandatory = $False)]
		[ArgumentCompleter(
			{
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				[KUser]::GetSortableParameters([KUser]).Name
			}
		)]
		[ValidateScript(
			{
				$_ -in [KUser]::GetSortableParameters([KUser]).Name
			}
		)]
		[String]$SortBy = "Email"
	)
	Begin
	{
		Ensure-Connected
	}

	Process
	{
        $ParamHash = @{
            URI 	= "$VSA/system/users"
            Method 	= "GET"
            Headers = @{"Authorization" = "Bearer $Token"}
            Filters = @(
                "substringof('$AdminName',AdminName)",
                "substringof('$FirstName',FirstName)",
                "substringof('$LastName',LastName)",
                "substringof('$Email',Email)"
            )
			SortBy 	= $SortBy
        }
        if ($UserId -ne -1) {
            $ParamHash.Filters = $ParamHash.Filters + "UserId eq $UserId"
        }

        Invoke-AdvancedRestMethod @ParamHash
	}
}


<#
.SYNOPSIS
Adds a user to a scope.

.PARAMETER ScopeId
The Id of the scope to add the user to.

.PARAMETER ScopeName
The name of the scope to add the user to.

.PARAMETER MachineGroupName
The name of the user to remove.

.PARAMETER UserId
The id of the user to remove.

.PARAMETER ReadOnly
Only return the properties that will be used.

.PARAMETER Force
Bypasses the confirmation prompts.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#38541.htm
#>
Function Set-KUserScope
{
	[CmdletBinding(DefaultParameterSetName = "ScopeId")]
	Param (
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, ParameterSetName = "ScopeId")]
		[String]$ScopeId,

		[Parameter(Mandatory = $True, ParameterSetName = "ScopeName")]
		[String]$ScopeName,

		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName)][String]$UserId,
    
        [Parameter(Mandatory = $False)][Switch]$ReadOnly,
        [Parameter(Mandatory = $False)][Switch]$Force
	)
	Begin
	{
		Ensure-Connected
	}

	Process
	{

        if ($ScopeName) {
            $ids = Get-KScopes -ScopeName "$ScopeName" | Select-Object -Expand ScopeId
            if ($ids.Count -ne 1) {
                throw "$ids matches to $($ids.Count) scopes!`nFor safety reasons, you can only set one user at a time."
            }
            else {
                $ScopeId = $ids
            }
        }

        $ParamHash = @{
            URI = "$vsa/system/scopes/$ScopeId/users/$UserId"
            Method 	= "PUT"
            Headers = @{"Authorization" = "Bearer $Token"}
            ContentType = "application/json"
        }

        if ($ReadOnly)
        {
            [PSCustomObject]$ParamHash | Write-Output
        }
        else 
        {
            if (!$DisableKConfirmations -and !$Force.IsPresent) {
                if (!(Get-Confirmation -Message "Set user ($UserId) to new scope: ($scopeId)?")) {
                    throw "Operation canceled by user."
                }
            }
            Invoke-AdvancedRestMethod @ParamHash | Write-Output
        }
	}
}