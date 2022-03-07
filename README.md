# PsKaseya
A PowerShell module for simplifying communication with the Kaseya VSA.

## !! Disclaimer !!
This is very much a work in progress. If you choose to use this module, know that there are many features that have not gone through sufficient testing.

## Importing the module
After cloning this repo, you should put a 'vsa' file in the PsKaseya folder that contains your VSA URL. If you don't do this, you will need to pass the URL as an argument to Import-Module:

    Import-Module -Name PsK -ArgumentList "https://helpdesk.somesite.com/api/v1.0"

After importing the module, you need to run Connect-Kaseya to authenticate with your VSA.
Your credentials will be hashed with SHA1 and SHA256, then converted to Base64 before being sent to the VSA for authentication.

## Examples

### Schedule Agent Procedures on Agents in an Agent View
    # You must have created this AgentView and AgentProcedure in the web portal
    # This will schedule the procedure across the span of the next 8 hours on the agents in the view.
    # When SkipIfOffline and PowerUpIfOffline are used together, the VSA will attempt to send a WoL to the device if it is offline.
    #  If it failed to respond to the WoL packet, the procedure will be cancelled for that agent. 
    # If you don't specify Force, you will be prompted for confirmation for each agent.
    >: Get-KAgents -AgentView "Win10 - 2004" | Foreach-Object {
        Start-KAgentProcedure -AgentProcedureName "Upgrade WinX to 21H2" -AgentID $_.AgentID -DistributionInterval Hours -DistributionMagnitude 8 -Force
    }


### Get Agents that have a local admin account that is not the Administrator account
    >: Get-KAgents | % {
        Get-KLocalGroupMembers -ComputerName $_.ComputerName -UserGroupName Administrators -MemberName "$($_.ComputerName)\" 
    } | ? MemberName -notlike "*\Administrator"

    UserGroupName  MemberName               Attributes AgentID
    -------------  ----------               ---------- -------
    Administrators Computer1\SecretAccount             ###############
    Administrators Computer2\Bob                       ###############


### Get a list of all Adobe Acrobat licenses 

    # Most cmdlets will be ran on EVERY agent if you don't pipe a list of agents or specify any filters with ComputerName or AgentID.
    >: Get-KSoftwareLicenses -ProductName "Adobe Acrobat DC"

    Publisher        : Adobe Systems Incorporated
    ProductName      : Adobe Acrobat DC Classic Track 2017 Standard - activated
    ProductKey       : 
    LicenseCode      : ########################
    Version          : 17.0.0.0
    InstallationDate : 10/16/2019 12:00:00 AM
    AgentId          : ###############

    ...

