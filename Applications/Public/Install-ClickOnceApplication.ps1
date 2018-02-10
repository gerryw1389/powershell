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
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
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
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    }
    
    Process
    {   
        
        
        
        Log "Uninstalling App..." 
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
        Log "Uninstalling App... Completed" -Color Darkred 
    
        Log "Renaming Localappdata-Apps-2.0 Folder..." 
        Set-Location "C:\Users\$Env:Username\Appdata\Local\Apps"
        Rename-Item -Path .\2.0 -Newname 2.0.Old -Force
        If (Test-Path "C:\Users\$Env:Username\Appdata\Local\Apps\2.0.Old") 
        {
       
            Log "Renaming Localappdata-Apps-2.0 Folder...Completed" 
        }
        Else 
        { 

            Log "Renaming Localappdata-Apps-2.0 Folder...Failed!" -Color Darkred 
        }

        Log "Reinstalling Application..." 
  
        Open-Internetexplorer -Url Http://Example.Com/Install.Application -Fullscreen -Inforeground

        $Wshell = New-Object -Com Wscript.Shell
        Start-Sleep -Seconds 5
        $Wshell.Sendkeys("{Left}")
        $Wshell.Sendkeys("{Enter}")	
            
    }

    End
    {
        Stop-Log  
    }

}

# Install-ClickOnceApplication


<#######</Body>#######>
<#######</Script>#######>