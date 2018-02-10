<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-WSUSCleanup
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Invoke-WSUSCleanup
{
    <#
.Synopsis
Cleans Up The Wsus Server.
.Description
Cleans Up The Wsus Server.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Invoke-WSUSCleanup
Cleans Up The Wsus Server.
.Example
"Dc4", "Dc5" | Invoke-WSUSCleanup
Cleans Up The Wsus Server.
.Notes
Requires The Updateservices Module.
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>  
    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Invoke-WSUSCleanup.Log"
    )
    
    
   Begin
    {

        Import-Module Updateservices

        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    }
    
     Process
    {    
        
        

        $Params = @{
            Cleanupobsoleteupdates      = $True;
            Cleanupunneededcontentfiles = $True;
            Declineexpiredupdates       = $True;
            Declinesupersededupdates    = $True
        }
        Get-Wsusserver | Invoke-Wsusservercleanup @Params
        Log "Wsus Server Has Been Cleaned" 
        
    }

    End
    {
        Stop-Log  
    }

}

# Invoke-WSUSCleanup

<#######</Body>#######>
<#######</Script>#######>