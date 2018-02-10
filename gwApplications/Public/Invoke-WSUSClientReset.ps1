<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-WSUSClientReset
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Invoke-WSUSClientReset
{
    <#
.Synopsis
WSUS Client Windows Update Reset Script.
.Description
WSUS Client Windows Update Reset Script. This script will reset the WSUS Server config on the client as well as the standard Windows Update services.
.Parameter WUServer
Mandatory parameter for you to input the "http://servername:8530" for your organization's WSUS Server. 
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Invoke-WSUSClientReset -WUServer "http://myserver:8530"
Ran from any computer that uses the "myserver" for WSUS, this function will reset its Windows Update components and re-register it with the WSUS Server.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Invoke-WSUSClientReset.log"
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
        
        Log "Disabling driver updates from WU"
        Set-Regentry -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value "0"
        Set-Regentry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUdriversInQualityUpdate" -Value "1"
        
        Log "Updating Policies"
        cmd /c "gpupdate"

        Log "Resetting WSUS server client settings"
        cmd /c "wuauclt.exe /resetauthorization /detectnow"
        cmd /c "wuauclt.exe /reportnow"
        (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()  
        
    }

    End
    {
        Stop-Log  
    }

}

# Invoke-WSUSClientReset -WUServer "http://myserver:8530"

<#######</Body>#######>
<#######</Script>#######>