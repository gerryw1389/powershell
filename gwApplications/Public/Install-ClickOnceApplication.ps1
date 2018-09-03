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
    .Example
    Install-ClickOnceApplication
    This Function Uninstalls A Clickonce Application And Then Re-Downloads And Installs It For You. 
    You Will Need To Provide The Application Name And Download Path.
    #>

    [Cmdletbinding()]

    Param
    (
        
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
        
    }
    
    Process
    {   
        Write-Output "Uninstalling App"
        $Installedapplicationnotmsi = Get-Childitem "Hkcu:\Software\Microsoft\Windows\Currentversion\Uninstall" | 
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
        Write-Output "Uninstalling App... Completed"
    
        Write-Output "Renaming Localappdata-Apps-2.0 Folder..."
        Set-Location "C:\Users\$Env:Username\Appdata\Local\Apps"
        Rename-Item -Path .\2.0 -Newname 2.0.Old -Force
        If (Test-Path "C:\Users\$Env:Username\Appdata\Local\Apps\2.0.Old") 
        {
   
            Write-Output "Renaming Localappdata-Apps-2.0 Folder...Completed"
        }
        Else 
        { 

            Write-Output "Renaming Localappdata-Apps-2.0 Folder...Failed!"
        }

        Write-Output "Reinstalling Application..."
  
        Open-Internetexplorer -Url Http://Example.Com/Install.Application -Fullscreen -Inforeground

        $Wshell = New-Object -Com Wscript.Shell
        Start-Sleep -Seconds 5
        $Wshell.Sendkeys("{Left}")
        $Wshell.Sendkeys("{Enter}")	
    
    }

    End
    {
        
    }
}

<#######</Body>#######>
<#######</Script>#######>