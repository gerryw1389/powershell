<#######<Script>#######>
<#######<Header>#######>
# Name: Install-ClickOnceApplication
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Install-ClickOnceApplication
{

    <#
.Synopsis
This function uninstalls a clickonce application and then re-downloads and installs it for you. 
You will need to provide the application name and download path.
.Description
This function uninstalls a clickonce application and then re-downloads and installs it for you. 
You will need to provide the application name and download path.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Install-ClickOnceApplication
This Function Uninstalls A Clickonce Application And Then Re-Downloads And Installs It For You. 
You Will Need To Provide The Application Name And Download Path.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>

    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Install-ClickOnceApplication.Log"
    )

    Begin
    {
    
        Function Open-Internetexplorer
        {
            Param
            (
                [Parameter(Mandatory = $True)]
                [String] $Url,
                [Switch] $Inforeground,
                [Switch] $Fullscreen
            )
            If ($Inforeground)
            {
                Add-Nativehelpertype
            }

            $Internetexplorer = New-Object -Com "Internetexplorer.Application"
            $Internetexplorer.Navigate($Url)
            $Internetexplorer.Visible = $True
            $Internetexplorer.Fullscreen = $Fullscreen
            If ($Inforeground)
            {
                [Nativehelper]::Setforeground($Internetexplorer.Hwnd)
            }
            Return $Internetexplorer
        }

        Function Add-Nativehelpertype
        {
            $Nativehelpertypedefinition = 
            @"
    Using System;
    Using System.Runtime.Interopservices;

    Public Static Class Nativehelper
    {
    [Dllimport("User32.Dll")]
    [Return: Marshalas(Unmanagedtype.Bool)]
    Private Static Extern Bool Setforegroundwindow(Intptr Hwnd);

    Public Static Bool Setforeground(Intptr Windowhandle)
    {
   Return Nativehelper.Setforegroundwindow(Windowhandle);
    }

    }
"@
            If (-Not ([System.Management.Automation.Pstypename] "Nativehelper").Type)
            {
                Add-Type -Typedefinition $Nativehelpertypedefinition
            }
        }

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
        Write-Output "Uninstalling App..." | TimeStamp
        $Installedapplicationnotmsi = Get-Childitem Hkcu:\Software\Microsoft\Windows\Currentversion\Uninstall | 
            Foreach-Object {Get-Itemproperty $_.Pspath}
        $Uninstallstring = $Installedapplicationnotmsi | 
            Where-Object { $_.Displayname -Match "App" } | 
            Select-Object Uninstallstring 
        $Wshell = New-Object -Com Wscript.Shell
        $Selecteduninstallstring = $Uninstallstring.Uninstallstring
        $Wshell.Run("Cmd /C $Selecteduninstallstring")
        Start-Sleep -Seconds 5
        $Wshell.Sendkeys("Ok")
        $Wshell.Sendkeys("{Enter}")
        Write-Output "Uninstalling App... Completed" | TimeStamp
    
        Write-Output "Renaming Localappdata-Apps-2.0 Folder..." | TimeStamp
        Set-Location "C:\Users\$Env:Username\Appdata\Local\Apps"
        Rename-Item -Path .\2.0 -Newname 2.0.Old -Force
        If (Test-Path "C:\Users\$Env:Username\Appdata\Local\Apps\2.0.Old") 
        {
   
            Write-Output "Renaming Localappdata-Apps-2.0 Folder...Completed" | TimeStamp
        }
        Else 
        { 

            Write-Output "Renaming Localappdata-Apps-2.0 Folder...Failed!" | TimeStamp
        }

        Write-Output "Reinstalling Application..." | TimeStamp
  
        Open-Internetexplorer -Url Http://Example.Com/Install.Application -Fullscreen -Inforeground

        $Wshell = New-Object -Com Wscript.Shell
        Start-Sleep -Seconds 5
        $Wshell.Sendkeys("{Left}")
        $Wshell.Sendkeys("{Enter}")	
    
    }

    End
    {
        If ($EnableLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>