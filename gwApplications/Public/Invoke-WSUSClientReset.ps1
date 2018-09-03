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
    .Example
    Invoke-WSUSClientReset -WUServer "http://myserver:8530"
    Ran from any computer that uses the "myserver" for WSUS, this function will reset its Windows Update components and re-register it with the WSUS Server.
    #>

    [Cmdletbinding()]
    
    Param
    (
    )
    
    Begin
    {   
        # Load the required module(s)
        Try
        {
            Import-Module "$Psscriptroot\..\Private\helpers.psm1" -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'Helpers' was not found, stopping script"
            Exit 1
        }
    }
    
    Process
    {   
        Write-Output "Disabling driver updates from WU"
        Set-Regentry -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value "0"
        Set-Regentry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUdriversInQualityUpdate" -Value "1"
    
        Write-Output "Updating Policies"
        cmd /c "gpupdate"

        Write-Output "Resetting WSUS server client settings"
        cmd /c "wuauclt.exe /resetauthorization /detectnow"
        cmd /c "wuauclt.exe /reportnow"
        (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()  
    
    }

    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>