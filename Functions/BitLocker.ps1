Function Get-KBitLockerStatus
{
    [CmdletBinding()]
    Param(
		[Parameter(Mandatory = $True, ParameterSetName="ByAgentView")]
		[ArgumentCompleter({
				Param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				Get-KAgentViews -ViewDefName "$WordToComplete" | Select-Object -Expand ViewDefName
		})]
		[ValidateScript({ (Get-KAgentViews -ViewDefName $_ | Select-Object -Expand ViewDefName).Count -eq 1 })]
		[String]$AgentView,

        [Parameter(Mandatory=$True, ValueFromPipeline, ParameterSetName="ByAgents")]
        [PSCustomObject[]]$Agents,

        [Parameter(Mandatory=$False)]
        [Switch]$InitiateTest,

        [Parameter(Mandatory=$False)]
        [Switch]$Force
    )

    
	Begin
	{
		Ensure-Connected
	}

    Process
    {
        
		if ($AgentView) {
            $Agents = Get-KAgents -AgentView $AgentView
		}

        if ($InitiateTest) {
            $Agents | Foreach-Object { 
                Start-KAgentProcedure -AgentProcedureName "Get-BitLockerStatus" -SkipIfOffLine -AgentId $_.AgentId -Force:$Force 
            }

            Write-Host "A BitLocker status scan has been run on all provided devices."
            for ($i = 1; $i -le 15; $i++)
            {
                Write-Host "Sleeping: ($($i) / 15)"
                Start-Sleep -Seconds 1
            }
        }
        
        Foreach ($Agent in $Agents)
        {
            $Splat = @{
                "ComputerName"  =       $Agent.ComputerName
                "LogTypes"      =       "AgentProcedure"
                "Status"        =       "BitLocker Status"
                "ErrorAction"   =       "SilentlyContinue"
            }

            # Return the agent info with the status.
            Get-KLogs @Splat | Select-Object @{Name="ComputerName";Expression={$Agent.ComputerName}}, Status | Write-Output
        }
    }
}


# SIG # Begin signature block
# MIIIXQYJKoZIhvcNAQcCoIIITjCCCEoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0RAeU8E0tST+rYZiuGmizMFB
# vPegggW7MIIFtzCCBJ+gAwIBAgITIAAAAtaXwewHS8gOOgAAAAAC1jANBgkqhkiG
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
# BgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTGqRARlOBRt9GBErg7LRNLi55VGjAN
# BgkqhkiG9w0BAQEFAASCAQBrAgj7kg43qcF25jmRLh5advl2QRJNSTIYCwv8tsTy
# z1khWndZa3Afo+e+woMPRsLhKvEPKEBDDyHbOJCbczHCrvXT+mTC6Q3fjqQMoDAP
# QKfDo3bG5FXuoKDwXni5Ik30L0Sz3maep/OQ2j/DLbk2qprp0ovE3d/OM/f2Cp9O
# VjlzWicAErirFEtiI0oKDuBCI5PZWctR5NyyVOd/v5DWzTPZrit9gqgkve7kGFTD
# mPU0AkfTKg96R5O1eZJcwttiJVRPuDYOXBH+T7L6zBKydFQrUOtX8Ug3zE5HC9Ke
# mcxfXZIQeBtpiCDiWJl6od3/JuD1oLM49lVq7gXlcFC6
# SIG # End signature block
