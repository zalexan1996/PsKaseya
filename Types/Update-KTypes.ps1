<#
.SYNOPSIS
Fetches the latest class definitions from the Kaseya documentations.

.DESCRIPTION
Uses Selenium to scrape the latest class definitions from Kaseya docs. These class definitions are
used for casting objects to and from the various API functions. In this way, I can use helpful
class names in describing the inputs and outputs of functions instead of just "takes a PSCustomObject with 
these properties".

Scaping directly from the helpdocs also means that when they update their API endpoints to return more data,
I can very quickly update the class definitions to reflect the new endpoints (so long as they're explained in
the documentation).

The final benefit of scraping from the help docs is that I can pool information about which properties are
sortable and filterable. Using that information, I can create a dynamic parameters for filtering and sorting.

Takes no parameters and only updates the CS file, it doesn't import the new definition to the session or update
any other existing sessions.

#>
Function Update-KTypes
{
	[CmdletBinding()]Param()

	Write-Verbose "Beginning Update-KTypes"
	try {
		Import-Module Selenium
	}
	catch {
		Write-Error "You must have the Selenium PowerShell module installed in order to run Update-KTypes."
		return;
	}

	
	$AllClasses = New-Object System.Collections.ArrayList

	# Known class names.
	$Script:ClassNames = @("float", "int", "double", "DateTime", "bool", "string", "object", "char")
	
	$AttributeCode = @"
	using System;
	using System.Linq;
	using System.Reflection;
	
	public class FilterableAttribute : Attribute {}

	public class SortableAttribute : Attribute {}

	
	public class KaseyaObject
	{
		public static PropertyInfo[] GetFilterableParameters(Type t)
		{
			return t.GetProperties().Where(prop => prop.GetCustomAttribute<FilterableAttribute>() != null).ToArray();
		}
		public static PropertyInfo[] GetSortableParameters(Type t)
		{
			return t.GetProperties().Where(prop => prop.GetCustomAttribute<SortableAttribute>() != null).ToArray();
		}
	}
	
"@
	
	Import-Module Selenium
	
	# Import our class definition table. This table defines information on how to convert the Help docs into
	# C# class definitions.
	Write-Verbose "Importing Class Definition Table"
	$HelpTable = Import-CSV "$(Split-Path $PSCommandPath)\ClassDefinitionTable.csv"
	
	

	# Given a DataType in question and a list of known datatypes,
	# 	get return the datatype from KnownTypes that is closest to DataType.
	# This is helpful because K's helpdocs are inconsistent in their naming whenever Arrays are concerned.
	Function Get-ClosestMatch
	{
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$True)][String]$DataType,
			[Parameter(Mandatory=$True)][String[]]$KnownTypes
		)
	
		$ClosestCount = 0
		$ReturnType = ""
	
		foreach ($Type in $KnownTypes) {
			$Difference = Compare-Object ($Type -split "") ($DataType -split "") -IncludeEqual | `
				Where-Object {$_.SideIndicator -like "=="} | Measure-Object | Select-Object -Expand Count
	
			if ($Difference -gt $ClosestCount) {
				$ClosestCount = $Difference
				$ReturnType = $Type
			}
		}

		Write-Verbose "`t$DataType converted to $ReturnType"
		return $ReturnType
	}
	
	
	
	Function ParseTable
	{
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$True)][String]$ClassName,
			[Parameter(Mandatory=$True)][OpenQA.Selenium.IWebElement]$Table
		)
		Write-Verbose "`tParsing table for $ClassName"
		$Classes = @()
	
	
		if ($ClassName.Contains(".")) {
			$ClassName = $ClassName.Substring($ClassName.LastIndexOf(".") + 1)
		}
		$Script:ClassNames = $Script:ClassNames + $ClassName
	
	
		$ClassObj = [PSCustomObject]@{
			ClassName = $ClassName
			Properties = New-Object System.Collections.ArrayList
			Code = ""
		}
	
		$Cells = $Table.FindElementsByTagName("p")
	
		$NewProp = $NULL
	


		# Parse the table for its Properties
		$Index = 0;
		Foreach ($Cell in $Cells)
		{
			if ($Cell.GetAttribute("class") -like "tableheading")
			{
				# If the cell is a header for another object.
				if ("Field", "Datatype", "Filterable", "Sortable" -notcontains $Cell.Text)
				{
					$Classes = $Classes + $ClassObj
	
					$CName = $Cell.Text
					if ($CName.Contains(".")) {
						$CName = $CName.Substring($CName.LastIndexOf(".") + 1)
					}
					$ClassObj = [PSCustomObject]@{
						ClassName = $CName
						Properties = New-Object System.Collections.ArrayList
						Code = ""
					}
					$Script:ClassNames = $Script:ClassNames + $CName
					Write-Verbose ""
					Write-Verbose "`tNew class discovered: $CName"
				}
			}
			else 
			{
				try {
					
					switch ($Index % 4)
					{
						0 # Field
						{
							if ($Cell.Text -notlike "")
							{
								$NewProp = [PSCustomObject]@{
									Name=$Cell.Text.Trim()
									DataType=""
									Filterable=$False
									Sortable=$False
									IsArray=$False
								}
								Write-Verbose "`tNew Property: $($NewProp.Name)"
							}
							else {
								$NewProp = $NULL
							}
						}
			
						1 # DataType
						{
							if ($NewProp)
							{
								# If the datatype is defined in the same page, the FieldName is likely very similar to the datatype name,
								# so we use that for now. After we are done parsing all classes, we will send everything through Get-ClosestMatch
								if ($Cell.Text -like "*see below*") {
									$NewProp.DataType = $NewProp.Name
								}
								else {
									$NewDatatype = ""
									# If the datatype is an array, capture whatever is in between the brackets and set the IsArray flag to true
									if ($Cell.Text.Contains("[") -or $Cell.Text.Contains("<")) {
										# Capture whatever is between the square brackets.
										$NewDatatype = [Regex]::Match("$($Cell.Text)", "(?<=(\[|\<))(.*?)(?=(\]|\>))").Value
										$NewProp.IsArray = $True
									}
									# Not an array
									else {
										$NewDatatype = $Cell.Text
									}
									if ($NewDatatype.Contains(".")) {
										$NewDatatype = $NewDatatype.Substring($NewDatatype.LastIndexOf(".") + 1)
									}
									$NewProp.DataType = $NewDatatype
									Write-Verbose "`t$($NewProp.Name) dataype: $NewDataType"
	
								}
							}
						}
			
						2 # Filterable
						{
							if ($NewProp)
							{
								if ($Cell.FindElementByTagName("img")) {
									$NewProp.Filterable = $True
									Write-Verbose "`t$($NewProp.Name) filterable"
								}
							}
						}
			
						3 # Sortable
						{
							if ($NewProp)
							{
								if ($Cell.FindElementByTagName("img")) {
									$NewProp.Sortable = $True
									Write-Verbose "`t$($NewProp.Name) sortable"
								}
							}
						}
					}
				}
				catch { }
			}
	
	
			if ($Index % 4 -eq 3 -and $NewProp.Name -and $NewProp.Name.Length -gt 1 -and $NewProp.Name -notlike "field") {
				$ClassObj.Properties.Add($NewProp) | Out-Null
			}
	
			$Index++
		}
	
		$Classes = $Classes + $ClassObj
		return $Classes
	}
	
	try {
		Write-Verbose "Starting chrome driver..."
		$Driver = Start-SeChrome -Quiet -Arguments "headless"
	}
	catch {
		Write-Error "Chrome driver failed to start:`n$_"
		return;
	}
	
	# Iterate through every help doc.
	Foreach ($HelpPage in $HelpTable)
	{
		Write-Verbose "Starting HelpPage: $($HelpPage.ClassName)"
	
		# Navigate to the current page.
		Enter-SeURL -Driver $Driver -URL $HelpPage.URL
	
		# Select the table as specified by the current help doc info.
		$Table = $Driver.FindElementsByClassName("tableintopic") | Select-Object -Index $HelpPage.NthTable
	
		# Make the timeout 0 so that we don't have to spend forever parsing the table
		$Driver.Manage().Timeouts().ImplicitWait = [TimeSpan]::FromMilliseconds(0)
		$Classes = ParseTable -ClassName "$($HelpPage.ClassName)" -Table $Table
	
	
		# Add each class we discovered on this doc page to our total collection. We'll convert this to C# code later.
		# We can't do the conversion now because some of the classes in this doc might reference classes in other docs.
		$ClassesAdded = @()
		$Classes | Foreach-Object {
			if (!$ClassesAdded.Contains($_.ClassName)) {
				$ClassesAdded = $ClassesAdded + $_.ClassName
				$AllClasses.Add($_) | Out-Null
			}
		}
	
		# This navigation in between pages is required.
		$Driver.Manage().Timeouts().ImplicitWait = [TimeSpan]::FromSeconds(3)
		Enter-SeURL -Url "http://help.kaseya.com" -Driver $Driver
	}
	
	Write-Verbose "Parsing complete!`nBeginning code generation..."
	# Generate the C# code for every class we encountered
	Foreach ($Class in $AllClasses) {

		# TODO: Have an optional parent class property in the CSV so all logs can inherit from a
		#        shared class.
		Write-Verbose "Generating class code for $($Class.ClassName)"
		$ClassCode = "public class $($Class.ClassName) : KaseyaObject `n{`n"
	
		# Generate the current properties C#.
		foreach ($Prop in $Class.Properties) {
			if ($Prop.Filterable) {
				$ClassCode += "`t[Filterable()]`n"
			}
			if ($Prop.Sortable) {
				$ClassCode += "`t[Sortable()]`n"
			}
	
			# Convert the current datatype to a known type if it's not in our list.
			# If it's an unknown type, it's probably either a typo or a case of plurality (for arrays).
			$DataType = $Prop.DataType -replace "decimal", "double" -replace "boolean", "bool" -replace "datetime", "DateTime"
			if ($ClassNames -notcontains $DataType) {
				$DataType = Get-ClosestMatch -DataType $DataType -KnownTypes $ClassNames
			}
			if ($Prop.IsArray) {
				$DataType += "[]"
			}
			$ClassCode += "`tpublic $($DataType) $($Prop.Name) {get; set;}`n`n"
		}
		$ClassCode += "}`n"
		$Class.Code = $ClassCode
	}
	
	$TypeDefinition = $AttributeCode
	$TypeDefinition += ($AllClasses.Code | Out-string)

	Write-Verbose "Exporting TypeDefinition to: $(split-Path $PSCommandPath)\KaseyaDefinitions.cs"
	$TypeDefinition | Out-File -FilePath "$(split-Path $PSCommandPath)\KaseyaDefinitions_new.cs" -Force


	Write-Host "Type definition has been exported to: $(split-Path $PSCommandPath)\KaseyaDefinitions_new.cs"
	
}


# SIG # Begin signature block
# MIIIXQYJKoZIhvcNAQcCoIIITjCCCEoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUACPI4cOETSkIBf2MeudEPXtj
# 61OgggW7MIIFtzCCBJ+gAwIBAgITIAAAAtaXwewHS8gOOgAAAAAC1jANBgkqhkiG
# 9w0BAQwFADBUMRMwEQYKCZImiZPyLGQBGRYDbmV0MRowGAYKCZImiZPyLGQBGRYK
# c2ZnbmV0d29yazEhMB8GA1UEAxMYc2ZnbmV0d29yay1TRkdORVRXT1JLLUNBMB4X
# DTIyMDEyNzE2NDUwNloXDTIzMDEyNzE2NDUwNlowWjETMBEGCgmSJomT8ixkARkW
# A25ldDEaMBgGCgmSJomT8ixkARkWCnNmZ25ldHdvcmsxDjAMBgNVBAsTBTUxLUlU
# MRcwFQYDVQQDEw5aYWNoIEFsZXhhbmRlcjCCASIwDQYJKoZIhvcNAQEBBQADggEP
# ADCCAQoCggEBAOz2G9QI8tH2sBLTPjy9ggA8H0gWIYEwhItffWhC//YjInZvoQSX
# 0OROfXQPzsKIrGm8Ry+ULYwQLVNTY1JM4Gw8Q9apUj2Lj7gFS0fJ+cuLIreUs6GK
# WX+t0eB0md30e7ocGmxb50CVdyrs+/3mCqHXdqnYFybuJpqLR3msQi/j739fRs80
# ti1qzRAvdt6OpjfSYbhOL8BMeeKGyjxPMGVhUHambQjPjH/iimZYfan3qtKBOIww
# HpV/oCjMwnuMkB5DOn7/mejs1+/P82gXjlJZZWFFM/+dYpuE2q9OtHhpM1FzRVMp
# /cEku1iV4wK/zd8FdxmfbOULvaLe40/FyxUCAwEAAaOCAnowggJ2MCUGCSsGAQQB
# gjcUAgQYHhYAQwBvAGQAZQBTAGkAZwBuAGkAbgBnMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMA4GA1UdDwEB/wQEAwIHgDAdBgNVHQ4EFgQU8dgE5AlWVG3M3fG54E9xetYb
# CCMwHwYDVR0jBBgwFoAUfpD6YhkIAsVEQoUE0d128tYMrREwgd0GA1UdHwSB1TCB
# 0jCBz6CBzKCByYaBxmxkYXA6Ly8vQ049c2ZnbmV0d29yay1TRkdORVRXT1JLLUNB
# LENOPVNGRy1TUlYtQ0FTLENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNl
# cyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPXNmZ25ldHdvcmssREM9
# bmV0P2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1j
# UkxEaXN0cmlidXRpb25Qb2ludDCBzQYIKwYBBQUHAQEEgcAwgb0wgboGCCsGAQUF
# BzAChoGtbGRhcDovLy9DTj1zZmduZXR3b3JrLVNGR05FVFdPUkstQ0EsQ049QUlB
# LENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZp
# Z3VyYXRpb24sREM9c2ZnbmV0d29yayxEQz1uZXQ/Y0FDZXJ0aWZpY2F0ZT9iYXNl
# P29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwOAYDVR0RBDEwL6At
# BgorBgEEAYI3FAIDoB8MHVphY2hfQWxleGFuZGVyQHNmZ25ldHdvcmsuY29tMA0G
# CSqGSIb3DQEBDAUAA4IBAQBAd4ZQ5xJcaI8s9nXTrCLAr/p3yPbNjvduBmhAdmHR
# gs+VTN9QEHDcMK49WNsTZ4QYQ3brZk+/lQgxZ3habIX9P6k+JrSV1vY0V3xOy+6I
# t4ybmq+vgvdC1qB9+ADt5Dm8fQYwrCz72RaJGjli9Lt6siPRo7Y7Bu2bNezwFBQg
# 497Sh0NtXYG5vQdyXQEbu/XCjE++5wqs0zp3S99N4u2cYw3bNHb7gw+XJoozVDgG
# U3vB6uqqX4LKZDpZGlZKXOa6ONIjValac+R373omIls5DlKqrI6ORqkn955WYXB2
# nPMJk3Hx3hWiNY1ljyIgOzG+VNGdUNYUO7yjPP5B44ltMYICDDCCAggCAQEwazBU
# MRMwEQYKCZImiZPyLGQBGRYDbmV0MRowGAYKCZImiZPyLGQBGRYKc2ZnbmV0d29y
# azEhMB8GA1UEAxMYc2ZnbmV0d29yay1TRkdORVRXT1JLLUNBAhMgAAAC1pfB7AdL
# yA46AAAAAALWMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAA
# MBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
# BgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSN/5SBSgO5KYR1kBLbuyVnTrQ+fzAN
# BgkqhkiG9w0BAQEFAASCAQCK5OP8UQJSz3Nfl8WQ560THLaFmvbA4UtxLQ1xP7E+
# lWGUK0/M6kc8uNJrPCpGtOl+TAbQdu9oamuliT1GwajYmmElXR5at+euCN4dssSa
# MOF1M0SBgaj/7pk3TqHfYp5lmg7O9/af79Zw54WqO2B9Sy4tcWhlwWbmcAnxZx0D
# Sj2aE4O4qOszK4RFmrKZ+LpTGldx0HQemFhmDugXaBIfZDzUIK+Y6leQ8yfBDU/k
# mrplqIoR4HK823Ib3COIFeZqsc7tOaBe580maQel0IW/LIlufoMoNXXYpYzISeS4
# NdPZQDPt7NuQtEvEQE/kRg4q5rZI6m0zKtWc/KnlEwyA
# SIG # End signature block
