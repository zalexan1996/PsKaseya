<#	
	===========================================================================
	 Created on:   	5/8/2019 11:02 AM
	 Created by:   	Zach Alexander
	 Filename:     	PSk.psm1
	-------------------------------------------------------------------------
	 Module Name: PSk
	 Description:
		PSk (PowerShell Kaseya) is a powershell module to leverge the Kaseya API
		to manage remote systems from the command line.
	===========================================================================
#>
<#TO-DO->
    * Certificates
        - Get a list of certificates. Sort by expiration
        - Remove a certificate
    * Tasks
        - Create a remote task
        - Get a list of tasks
        - Remove a remote task
        - Create custom Event Listener
        - Remove custom Event Listener
        - Assign code to Event Listener
    * Devices
        - Eject removable media
    * Users
        - Remove / Add local users & groups
        - Lock screen
        - Set users able to login to computer
        - Set allowable RDP users
<-TO-DO#>



# Pass in your VSA URL.
# - Import-Module -Name PsK -ArgumentList "https://helpdesk.somesite.com/api/v1.0"
# Alternatively, make a file in this folder called 'vsa' and put your VSA URL in it.
Param ( 
    [Parameter(Position = 0, Mandatory = $False)][String]$VSAURL,
    [Parameter(Mandatory = $False)][Switch]$DisableConfirmations
)

# Set the VSA URL
if ($VSAURL -like "")
{ 
    $Global:VSA = Get-Content "$(Split-Path $PSCommandPath)/vsa" 
}
else 
{
    $GLOBAL:VSA = $VSAURL
}

# Global confirmation override
$Global:DisableKConfirmations = $DisableConfirmations.IsPresent


# Do not set credentials here. This variable is not exposed outside of this module.
# This is used for internal purposes and is set inside of Connect-Kaseya
$script:AuthenticationCredentials = $NULL

# Import the type definitions. Used to determine Sortable/Filterable properties via reflection.
Add-Type -TypeDefinition (Get-Content "$PSScriptRoot/Types/KaseyaDefinitions.cs" | Out-String) -ErrorAction SilentlyContinue -IgnoreWarnings

# Import all module functions
Get-ChildItem "$PSScriptRoot/Functions" -Recurse -Filter "*.ps1" | Import-Module


# SIG # Begin signature block
# MIIIXQYJKoZIhvcNAQcCoIIITjCCCEoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpeXoVZR/Cz0aWIlnt2gRN83y
# hlmgggW7MIIFtzCCBJ+gAwIBAgITIAAAAtaXwewHS8gOOgAAAAAC1jANBgkqhkiG
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
# BgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBR5eaTj6J0Tly6fC7XmbzaTLkCeSTAN
# BgkqhkiG9w0BAQEFAASCAQDrq1GuUV4/5RDJc4fUu6d+BV7pFBvnDb9N5zvcef7c
# d+ORebqmpBKcHHVj5+tHCZylMI2CUIk5gRlZL11yUjp6UNsvCv+VfP7RRp3zi8/3
# zFar5M0ei3pnkr4WNqTVYLtdevdyIU/hxjN5d/bEpQndjLyNHo0hKdjPJioubA9i
# 816ruHPCk41shd/XkAXOg3SnUFNYFgE6oXN3Rbj7Gpz4QyRzaa8ajdLw1jJec2EC
# BvaD2HWt08On2bAljxpjV8nRyF8eLajtq0rRVKo2Cec1eGstA70A8oxPJqchZ6R5
# 59i9lu5d0IS5eTpq3jYDSYJQzwOx8TTMl//jaCgTRlEC
# SIG # End signature block
