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
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
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
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log  
        
    }
    
    Process
    {    
        
        
           
        If (Test-Path $profile)
        {
            Log "Powershell CurrentUser,CurrentHost Profile Already exists" 
        }
        Else
        {
            New-Item $profile -ItemType file -Force
            Log "Created Powershell CurrentUser,CurrentHost Profile" 
        }

        If (Test-Path $profile.CurrentUserAllHosts)
        {
            Log "Powershell CurrentUser,AllHost Profile already exists" 
        }
        Else
        {
            New-Item $profile.CurrentUserAllHosts -ItemType file -Force
            Log "Created Powershell CurrentUser,AllHost profile" 
        }

        If (Test-Path $profile.AllUsersCurrentHost)
        {
            Log "Powershell AllUsers,CurrentHost profile already exists" 
        }
        Else
        {
            New-Item $profile.AllUsersCurrentHost -ItemType file -Force
            Log "Created Powershell AllUsers,CurrentHost profile" 
        }

        If (Test-Path $profile.AllUsersAllHosts)
        {
            Log "Powershell AllUsers,AllHosts profile already exists" 
        }
        Else
        {
            New-Item $profile.AllUsersAllHosts -ItemType file -Force
            Log "Created Powershell AllUsers,AllHosts profile" 
        }

        # This is for Powershell ISE

        $isePath = "$env:userprofile\Documents\WindowsPowershell\Microsoft.PowerShellISE_profile.ps1"
        If (Test-Path $isePath)
        {
            Log "Powershell ISE CurrentUser, CurrentHost profile already exists" 
        }
        Else
        {
            New-Item -path $isePath -ItemType file -Force
            Log "Created Powershell ISE CurrentUser, CurrentHost profile" 
        }

        $iseAllUsersPath = "$env:userprofile\Documents\Microsoft.PowerShellISE_profile.ps1"
        If (Test-Path $iseAllUsersPath)
        {
            Log "Powershell ISE AllUsers, CurrentHost profile already exists" 
        }
        Else
        {
            New-Item -path $iseAllUsersPath -ItemType file -Force
            Log "Created Powershell ISE AllUsers, CurrentHost profile" 
        }
    }

    End
    {
        Stop-Log  
    }

}

# Test-PSProfiles

<#######</Body>#######>
<#######</Script>#######>