<#
.SYNOPSIS
Adds a single notification record.

.PARAMETER Title
The title of the notification

.PARAMETER Body
The body of the notification.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31678.htm

#>
Function Add-KNotification
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][String]$Title,
        [Parameter(Mandatory=$True)][String]$Body
    )
    $ParamHash = @{
        URI = "$VSA/notification"
        Method 	= "POST"
        Headers = @{ "Authorization" = "Bearer $Token" }
        Body = @{
            Title = $Title
            Body = $Body
        }
        ContentType = "application/json"
    }
    Invoke-AdvancedRestMethod @ParamHash | Write-Output
}

Function Connect-Kaseya
{
<#
.SYNOPSIS
 Generates a token for authentication with the Kaseya REST web API. 

.DESCRIPTION
 This command needs to be run before running any other
 Kaseya related commands. The token will also expire after 30 minutes.
 

.PARAMETER KeepAlive
 !CURRENTLY DOESN'T WORK!
 An optional parameter for specifing how many times the token should be
 regenerated. This should only be used sparingly in cases where a script
 might run for a VERY long time unattended. 

 The token will be regenerated every 30 minutes. So to determine how many
 seconds your session will stay active, multiply the KeepAlive value by 30.
 <CURRENTLY_UNSUPPORTED>

.PARAMETER Credential
 An optional parameter specifying a credential object to use. If no 
 value is provided, Connect-Kaseya will call Get-Credential to prompt for
 creds. This would be best used in conjunction with KeepAlive. That way,
 the credential object containing the username and password can persist
 across all regenerations. Otherwise, it would prompt every time.

.OUTPUTS
 Returns the token generated. Probably useless. 
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $False, Position = 0)][Switch]$KeepAlive,
		[Parameter(Mandatory = $False, Position = 1)]
		[System.Management.Automation.PSCredential]$Credential = (Get-Credential -Message "Please enter your Kaseya credentials")
	)

    
    # Reset our authentication creds
    $script:AuthenticationCredentials = $Credential

	$GenHash = {
		Param ($Algorithm, $Text)
		$Data = [System.Text.Encoding]::UTF8.GetBytes($Text)
		[String]$Hash = -join ([Security.Cryptography.HashAlgorithm]::Create($Algorithm).ComputeHash($Data) | Foreach-Object { "{0:x2}" -f $_ })
		Return $Hash
	}
	
	$user = $script:AuthenticationCredentials.UserName
	$PW = $script:AuthenticationCredentials.GetNetworkCredential().Password


	$Rand = Get-Random
	$SHA1Hash = $GenHash.Invoke("SHA1", "$PW$User")
	$SHA256Hash = $GenHash.Invoke("SHA256", "$PW$User")
	$SHA1Hash = $GenHash.Invoke("SHA1", "$SHA1Hash$Rand")
	$SHA256Hash = $GenHash.Invoke("SHA256", "$SHA256Hash$Rand")
	$Auth = "user=$user,pass2=$SHA256Hash,pass1=$SHA1Hash,rand2=$rand,rpass2=$SHA256Hash,rpass1=$SHA1Hash,twofapass=:undefined"
	$encodedauth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Auth))
	$request = Invoke-RestMethod -Method Get -URI "$Global:VSA/auth" -Headers @{ 'Authorization' = "Basic $Encodedauth" }
	$Script:Token = $request.Result.Token
   

	if ($Script:Token -eq "") {
		throw "Connect-Kaseya | Invalid Credential"
	}


	if ($Script:Token) {
		
		if ($KeepAlive) {
			Add-Type -AssemblyName "WindowsBase"
			$Script:TokenTimer = New-Object System.Windows.Threading.DispatcherTimer
			
			$Script:TokenTimer.Interval = [TimeSpan]::FromMinutes(1)
			$Script:TokenTimer.add_tick({Connect-Kaseya -Credential $script:AuthenticationCredentials -Verbose})
			$Script:TokenTimer.Start()
			Write-Verbose "Reauthenticating with Kaseya every minute..."
		}
		return $True
	}
	else {
		return $False
	}
}

Function Ensure-Connected
{
    # If we aren't authenticated, authenticate.
    if (!(Test-KConnection -TestAuthentication))   {
        Connect-Kaseya -Credential $script:AuthenticationCredentials

        # If we still aren't connected even after re-authenticating, throw an error
        if (!(Test-KConnection -TestAuthentication)) {
            throw "Failed to re-authenticate with Kaseya."
        }
    }
}

<#
.SYNOPSIS
Used to convert a DateTime object to a string that Kaseya supports.

.PARAMETER LongFormat
Long format will be in the form of:
yyyy-MM-ddTHH:mm:ss.fffZ

.PARAMETER ShortTimeFormat
Short time format will be in the form of:
THHmm
#>
Function Format-Time
{
	Param(
		[DateTime]$Time,
		[Switch]$LongFormat,
		[Switch]$ShortTimeFormat
	)

	if ($LongFormat) {
		return "$($Time.ToString("yyyy-MM-ddTHH:mm:ss.fff"))Z"
	}
	if ($ShortTimeFormat) {
		return "T$($Time.ToString("HH"))$($Time.ToString("mm"))"
	}
}

<#
.SYNOPSIS
Returns system-wide properties of the VSA.

.OUTPUTS
string   SystemVersion
string   PatchLevel
string   CustomerID
int      TimeZoneOffset
string   AgentVersion

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37596.htm
#>
Function Get-KEnvironment
{
    
    $ParamHash = @{
        URI = "$VSA/environment"
        Method 	= "GET"
        Headers = @{"Authorization" = "Bearer $Token"}
    }
    Ensure-Connected
    Invoke-AdvancedRestMethod @ParamHash | Write-Output
}

<#
.SYNOPSIS
Returns an array of all function IDs.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#33704.htm
#>
Function Get-KFunctions
{
    $ParamHash = @{
        URI = "$VSA/functions"
        Method 	= "GET"
        Headers = @{"Authorization" = "Bearer $Token"}
    }
    Ensure-Connected
    if ($ModuleId) {
        $ParamHash.URI += "/$ModuleId"
    }

    Invoke-AdvancedRestMethod @ParamHash | Write-Output
}

<#
.SYNOPSIS
Returns true or false based on whether the specified module ID is installed.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37306.htm
#>
Function Get-KIsModuleInstalled
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][int]$ModuleId
    )
    Ensure-Connected
    $ParamHash = @{
        URI = "$VSA/ismoduleinstalled/$ModuleId"
        Method 	= "GET"
        Headers = @{"Authorization" = "Bearer $Token"}
    }
    [Bool](Invoke-AdvancedRestMethod @ParamHash) | Write-Output
}

<#
.SYNOPSIS
Returns properties for the tenant partition your API authentication provides access to in the VSA.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31675.htm
#>
Function Get-KTenant
{
    Ensure-Connected
    $ParamHash = @{
        URI = "$VSA/tenant"
        Method 	= "GET"
        Headers = @{"Authorization" = "Bearer $Token"}
    }
    Invoke-AdvancedRestMethod @ParamHash | Write-Output
}


<#
.SYNOPSIS 
A method to give you more advanced control over communicating with a RestAPI

.DESCRIPTION 
A wrapper for Invoke-RestMethod that handles pagination and converting a filter array into a query string
that is appended to the URL endpoint.

.PARAMETER URI
The URI that will be sent to the Endpoint. Don't include any pagination or filter parameters. Pagination is
handled automatically and filtering is handled by the Filters parameter.

.PARAMETER Method
The HTTP method to use. This value is passed directly to Invoke-RestMethod. Acceptable values are:
    - GET
    - POST
    - PUT
    - DELETE

.PARAMETER Headers
The headers to use. This value is passed directly to the Headers property of Invoke-RestMethod. 
No headers are added automatically. If using this function for the Kaseya API, you need to pass in:
@{"Authorization" = "Bearer $Token"}

.PARAMETER Body
The body to use for the HTTP request. This value is only used if you are using an HTTP method that uses a body.
Only accepts a dictionary. If the endpoint you are communicating with requires JSON, specify "application/json"
for the -ContentType and Invoke-AdvancedRestMethod will convert the Body to JSON.

.PARAMETER Filters
An array of strings that will be concatenated to form the filterstring. You don't need to work about ?'s or &'s.
Each element in the array is it's own contained filter property. Each element is AND'd together. If you wish to
use ORs, you need to include them in one array element. Examples:

        $FilterStrings = @(
            "substringof('SomeTitle',Title)",
            "AccountType eq 'Sales' or CreditLimit gt '1000000'"
        )
        _Invoke-RESTWithPagination -URI $URL -Headers $Global:Headers -Method Get -Filters $FilterStrings

For more information on Kaseya's filtering:
    http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31622.htm

.PARAMETER OrderBy
Sorts the resulting objects by a specific property. When used in conjunction with Top, you can get the top objects
sorted by a specific property.

.PARAMETER Top
Only specifies the top X number of entries. If not used in conjunction with OrderBy, it just retrieves the first x
objects that it encounters.

.PARAMETER ReadOnly
Returns a PSCustomObject of all the parameters it would have passed into Invoke-RestMethod. This is a good sanity
check to make sure it's not screwing something up in the parameter query.

.PARAMETER ContentType
The content type of the request. When using application/json, the Body will be converted to JSON.
#>


Function Invoke-AdvancedRestMethod
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $True)][String]$URI,
        [Parameter(Mandatory = $False)][ValidateSet("GET", "POST", "PUT", "DELETE")][String]$Method="GET",
		[Parameter(Mandatory = $False)][System.Collections.IDictionary]$Headers,
		[Parameter(Mandatory = $False)][System.Collections.IDictionary]$Body,
		[Parameter(Mandatory = $False)][String[]]$Filters,
        [Parameter(Mandatory = $False)][String]$SortBy,
        [Parameter(Mandatory = $False)][String]$Top,
        [Parameter(Mandatory = $False)][Switch]$ReadOnly,
        [Parameter(Mandatory = $False)][String]$ContentType
	)

	Begin {
		$Times = 0
		$TotalReceived = 100
	}

	Process {
		$Output = @()
        $ParamHash = @{}
        $Filters = $Filters | Where-Object { $_ -ne "" }
		while ($TotalReceived -eq 100) {
            $DelimChar = "?"
            $Filter = ""


            if ($Filters) {
                $Filter = "$($DelimChar)`$filter=$($Filters -join ' and ')"
                $DelimChar = "&"
            }
            if ($SortBy) {
                $Filter += "$($DelimChar)`$orderby=$SortBy"
                $DelimChar = "&"
            }
			if ($Times -gt 0) {
				$Filter += "$($DelimChar)`$skip=$($Times * 100)"
                $DelimChar = "&"
			}
            if ($Top) {
                $Filter += "$($DelimChar)`$top=$Top"
                $DelimChar = "&"
            }



            $ParamHash.URI = "$URI$Filter"
            $ParamHash.Headers = $Headers
            $ParamHash.Method = $Method
            if ($ContentType) {
                $ParamHash.ContentType = $ContentType
            }

            if ($Body -and $Method -notlike "*get*") { 
                if ($ContentType -like "application/json") {
                    $ParamHash.Body = $Body | ConvertTo-JSON
                }
                else {
                    $ParamHash.Body = $Body 
                }
            }
            if ($ReadOnly) { return [PSCustomObject]$ParamHash }
            else { $ThisGo = [PSCustomObject](Invoke-RestMethod @ParamHash) }

			$Output += $ThisGo.Result
            $TotalReceived = $ThisGo.result.Count
            Write-Verbose "Received $($ThisGo.Result.Count) records"
			$Times++
		}
		return $Output
	}
}


<#
.SYNOPSIS
Provides an easy, reusable way to create a dynamic parameter.

.PARAMETER Name
The name of the dynamic parameter

.PARAMETER Type
The type of the parameter

.PARAMETER DefaultValue
The default value of the parameter. It takes an [Object] to allow all sorts of values.

.PARAMETER Mandatory
Whether this is going to be a mandatory parameter.

.PARAMETER Position
The position of this parameter.

.PARAMETER ValueFromPipeline
Whether this parameter accepts its value by pipeline

.PARAMETER ValueFromPipelineByPropertyName
Whether this parameter accepts its value from the pipeline by property name.

.PARAMETER HelpMessage
The help message for the parameter.

.PARAMETER ParameterSetName
The parameter set name associated with this parameter

.PARAMETER ValidateSet
An array of acceptable values for this parameter.

.PARAMETER ValidateScript
A script that validates acceptable values.

.PARAMETER Aliases
An array of aliases for this parameter.
#>
Function New-DynamicParameter
{
    [CmdletBinding()]
    Param(

        # Core Properties
        [Parameter(Mandatory=$True)][String]$Name,
        [Parameter(Mandatory=$True)][Type]$Type,
        [Parameter(Mandatory=$False)][Object]$DefaultValue,
        [Parameter(Mandatory=$False)][Switch]$Mandatory,
        [Parameter(Mandatory=$False)][Int]$Position,
        [Parameter(Mandatory=$False)][Switch]$ValueFromPipeline,
        [Parameter(Mandatory=$False)][Switch]$ValueFromPipelineByPropertyName,
        [Parameter(Mandatory=$False)][String]$HelpMessage = "",
        [Parameter(Mandatory=$False)][String]$ParameterSetName = "",


        # Attributes
        [Parameter(Mandatory=$False)][String[]]$ValidateSet,
        [Parameter(Mandatory=$False)][ScriptBlock]$ValidateScript,
        [Parameter(Mandatory=$False)][String[]]$Aliases
    )

	$AttCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute

    if ($Mandatory) {
        $ParameterAttribute.Mandatory = $True
    }
    if ($Position) {
        $ParameterAttribute.Position = $Position
    }
	
    if ($HelpMessage.Length -gt 0) {
        $ParameterAttribute.HelpMessage = $HelpMessage
    }
    if ($ValueFromPipeline) {
        $ParameterAttribute.ValueFromPipeline = $True
    }
    if ($ValueFromPipelineByPropertyName) {
        $ParameterAttribute.ValueFromPipelineByPropertyName = $True
    }

    $ParameterAttribute.ParameterSetName = $ParameterSetName
    $AttCollection.Add($ParameterAttribute)


    if ($ValidateSet.Count -gt 0) {
        $AttCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)))
    }

    if ($ValidateScript) {
        $AttCollection.Add((New-Object System.Management.Automation.ValidateScriptAttribute($ValidateScript)))
    }

    if ($Aliases.Count -gt 0) {
        $AttCollection.Add((New-Object System.Management.Automation.AliasAttribute($Aliases)))
    }
    
    return (New-Object System.Management.Automation.RuntimeDefinedParameter($Name, $Type, $AttCollection))
}


<#
.SYNOPSIS
A helper function for cmdlets that do potentially dangerous things. It prompts to make sure that you want to do whatever you're doing.

.PARAMETER Message
A description of the operation that will be performed.

#>
Function Get-Confirmation
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][String]$Message
    )

    $No = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Aborts the operation'
    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Performs the operation'
    $Choice = $Host.UI.PromptForChoice("Are you sure you want to perform this action?", "$Message", @($No, $Yes), 0)
    return [Bool]$Choice
}

<#
.SYNOPSIS
Sends an email.

.PARAMETER FromAddress
The address to send from.

.PARAMETER ToAddress
The address to send an email to.

.PARAMETER Subject
The subject of the email.

.PARAMETER Body
The body of the email.

.PARAMETER BodyAsHtml
Whether the body should be treated as HTML.

.PARAMETER Priority
Priority for queueing the email.

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#37653.htm
#>
Function Send-KEmail
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][String]$FromAddress,
        [Parameter(Mandatory=$True)][String]$ToAddress,
        [Parameter(Mandatory=$True)][String]$Subject,
        [Parameter(Mandatory=$True)][String]$Body,
        [Parameter(Mandatory=$False)][Switch]$BodyAsHTML,
        [Parameter(Mandatory=$False)][int]$Priority = 0
    )
    Ensure-Connected
    $ParamHash = @{
        URI = "$VSA/email"
        Method 	= "POST"
        Headers = @{ 
            "Authorization" = "Bearer $Token" 
        }
        Body = @{
            FromAddress = $FromAddress
            ToAddress = $ToAddress
            Subject = $Subject
            Body = $Body
            IsBodyHtml = $(if ($BodyAsHTML) {"true"} else {"false"})
            UniqueTag = (-join (Get-Random -InputObject ([char[]]"abcdefghijklmnopqrstuvwxyz1234567890") -Count 20))
        } | ConvertTo-Json
        ContentType = "application/json"
    }
    Invoke-RestMethod @ParamHash | Write-Output
}

<#
.SYNOPSIS
Tests for connectivity with an API website. By default, it doesn't use authentication.

.PARAMETER TestAuthentication
Tests connectivity and use the authentication token created by Connect-Kaseya

.LINK
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31768.htm
http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/#31770.htm
#>
Function Test-KConnection
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)][Switch]$TestAuthentication
    )
    $ParamHash = @{
        Method 	= "GET"
        Headers = @{"Authorization" = "Bearer $Token"}
    }

    $Output = $true

    $Output = $Output -and [Bool](Invoke-AdvancedRestMethod @ParamHash -URI "$VSA/echo")

    if ($TestAuthentication) {
        try {
            $Output = $Output -and [Bool](Invoke-AdvancedRestMethod @ParamHash -URI "$VSA/echoauth" -ErrorAction Stop)
        }
        catch {
            $Output = $False
        }
    }

    $Output | Write-Output
}