<#######<Script>#######>
<#######<Header>#######>
# Name: Test-PSProfiles
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Test-PSProfiles
{
    <#
.Synopsis
This function tests your system to see if you have Powershell profiles loaded. If not, it creates blank ones for you.
.Description
This function tests your system to see if you have Powershell profiles loaded. If not, it creates blank ones for you.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Test-PSProfiles
This function tests your system to see if you have Powershell profiles loaded. If not, it creates blank ones for you.
.Example
"Pc2", "Pc1" | Test-PSProfiles
This function tests your system to see if you have Powershell profiles loaded. If not, it creates blank ones for you.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>   
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Test-PSProfiles.Log"
    )

    Begin
    {
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        If ($($Logfile.Length) -gt 1)
        {
            $EnabledLogging = $True
        }
        Else
        {
            $EnabledLogging = $False
        }
    
    
        Filter Timestamp
        {
            "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $_"
        }

        If ($EnabledLogging)
        {
            # Create parent path and logfile if it doesn't exist
            $Regex = '([^\\]*)$'
            $Logparent = $Logfile -Replace $Regex
            If (!(Test-Path $Logparent))
            {
                New-Item -Itemtype Directory -Path $Logparent -Force | Out-Null
            }
            If (!(Test-Path $Logfile))
            {
                New-Item -Itemtype File -Path $Logfile -Force | Out-Null
            }
    
            # Clear it if it is over 10 MB
            $Sizemax = 10
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            $Sizemb = "{0:N2}" -F ($Size.Sum / 1mb) + "Mb"
            If ($Sizemb -Ge $Sizemax)
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            # Start writing to logfile
            Start-Transcript -Path $Logfile -Append 
            Write-Output "####################<Script>####################"
            Write-Output "Script Started on $env:COMPUTERNAME" | TimeStamp
        }  
    
    }
    
    Process
    {    
        If (Test-Path $profile)
        {
            Write-Output "Powershell CurrentUser,CurrentHost Profile Already exists" | TimeStamp
        }
        Else
        {
            New-Item $profile -ItemType file -Force
            Write-Output "Created Powershell CurrentUser,CurrentHost Profile" | TimeStamp
        }

        If (Test-Path $profile.CurrentUserAllHosts)
        {
            Write-Output "Powershell CurrentUser,AllHost Profile already exists" | TimeStamp
        }
        Else
        {
            New-Item $profile.CurrentUserAllHosts -ItemType file -Force
            Write-Output "Created Powershell CurrentUser,AllHost profile" | TimeStamp
        }

        If (Test-Path $profile.AllUsersCurrentHost)
        {
            Write-Output "Powershell AllUsers,CurrentHost profile already exists" | TimeStamp
        }
        Else
        {
            New-Item $profile.AllUsersCurrentHost -ItemType file -Force
            Write-Output "Created Powershell AllUsers,CurrentHost profile" | TimeStamp
        }

        If (Test-Path $profile.AllUsersAllHosts)
        {
            Write-Output "Powershell AllUsers,AllHosts profile already exists" | TimeStamp
        }
        Else
        {
            New-Item $profile.AllUsersAllHosts -ItemType file -Force
            Write-Output "Created Powershell AllUsers,AllHosts profile" | TimeStamp
        }

        # This is for Powershell ISE

        $isePath = "$env:userprofile\Documents\WindowsPowershell\Microsoft.PowerShellISE_profile.ps1"
        If (Test-Path $isePath)
        {
            Write-Output "Powershell ISE CurrentUser, CurrentHost profile already exists" | TimeStamp
        }
        Else
        {
            New-Item -path $isePath -ItemType file -Force
            Write-Output "Created Powershell ISE CurrentUser, CurrentHost profile" | TimeStamp
        }

        $iseAllUsersPath = "$env:userprofile\Documents\Microsoft.PowerShellISE_profile.ps1"
        If (Test-Path $iseAllUsersPath)
        {
            Write-Output "Powershell ISE AllUsers, CurrentHost profile already exists" | TimeStamp
        }
        Else
        {
            New-Item -path $iseAllUsersPath -ItemType file -Force
            Write-Output "Created Powershell ISE AllUsers, CurrentHost profile" | TimeStamp
        }
    }

    End
    {
        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>