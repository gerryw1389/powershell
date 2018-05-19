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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
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

        # Load the required module(s) 
        If (-not(Get-module helpers)) 
        {
            Import-Module "$Psscriptroot\..\Private\helpers.psm1"
        }
        Else
        {
            Write-Output "Module was not found, please make sure the module exists! Exiting function." | Timestamp
            Exit 1
        }
  
    }
    
    Process
    {   
        Write-Output "Disabling driver updates from WU" | TimeStamp
        Set-Regentry -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value "0"
        Set-Regentry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUdriversInQualityUpdate" -Value "1"
    
        Write-Output "Updating Policies" | TimeStamp | TimeStamp
        cmd /c "gpupdate"

        Write-Output "Resetting WSUS server client settings" | TimeStamp
        cmd /c "wuauclt.exe /resetauthorization /detectnow"
        cmd /c "wuauclt.exe /reportnow"
        (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()  
    
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