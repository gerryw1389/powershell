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
        [Parameter(Mandatory = $True, Position = 0)]
        [String]$Wuserver,
        
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
        
        

        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "SusClientId" -Force | Out-Null
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "SusClientIdValidation" -Force | Out-Null

        Log "Setting Windows Update Server to: $Wuserver"
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        $Name = "WUServer"
        $value = "$Wuserver"
        IF (!(Test-Path $registryPath))
        {
            New-Item -Path $registryPath -Force | Out-Null
        }
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null

        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        $Name = "WUStatusServer"
        $value = "$Wuserver"
        IF (!(Test-Path $registryPath))
        {
            New-Item -Path $registryPath -Force | Out-Null
        }
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null

        Log "Disabling driver updates from WU"
        $registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\DriverSearching"
        $Name = "SearchOrderConfig"
        $value = "0"
        IF (!(Test-Path $registryPath))
        {
            New-Item -Path $registryPath -Force | Out-Null
        }
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

        $registryPath = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
        $Name = "ExcludeWUdriversInQualityUpdate"
        $value = "1"
        IF (!(Test-Path $registryPath))
        {
            New-Item -Path $registryPath -Force | Out-Null
        }
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
        
        Log "Updating Policies"
        cmd /c "gpupdate"

        Log "Stopping update services, removing download folders, and re-registering DLLs.."
        Stop-Service -Name "wuauserv", "bits" -Force
        Remove-Item -Path "$env:windir\SoftwareDistribution" -Recurse -Force
        Remove-Item -Path "$env:windir\windowsupdate.log" -Recurse -Force
        cmd /c "regsvr32 WUAPI.DLL /s"
        cmd /c "regsvr32 WUAUENG.DLL /s"
        cmd /c "regsvr32 WUAUENG1.DLL /s"
        cmd /c "regsvr32 ATL.DLL /s"
        cmd /c "regsvr32 WUCLTUI.DLL /s"
        cmd /c "regsvr32 WUPS.DLL /s"
        cmd /c "regsvr32 WUPS2.DLL /s"
        cmd /c "regsvr32 WUWEB.DLL /s"
        cmd /c "regsvr32 msxml3.DLL /s"
        
        Log "Starting services and requesting updates from the WSUS Server"
        Start-Service -Name "wuauserv"
        
        Log "Moving WU into it's own svchost.exe process"
        cmd /c "sc.exe config wuauserv type= own"
        
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