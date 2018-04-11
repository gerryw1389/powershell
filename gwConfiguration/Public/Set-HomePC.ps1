<#######<Script>#######>
<#######<Header>#######>
# Name: Set-HomePC
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-HomePC
{
    <#
.Synopsis
W10 config script.
.Description
W10 config script that I run on on my home PC after Set-Template. It has further customizations that I wouldn't want just any PC.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Set-HomePC
Usually same as synopsis.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>   
    
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-HomePC.Log"
    )

   
    Begin
    {

        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
        New-Alias -Name "SetReg" -Value Set-RegEntry

        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
        
    }
    
    
    Process
    {    
        Log "Creating a lockscreen task"
        $TaskName = "LockScreen"
        $service = New-Object -ComObject("Schedule.Service")
        $service.Connect()
        $rootFolder = $service.GetFolder("")
        $taskdef = $service.NewTask(0)
        $sets = $taskdef.Settings
        $sets.AllowDemandStart = $true
        $sets.Compatibility = 2
        $sets.Enabled = $true
        $sets.RunOnlyIfIdle = $true
        $sets.IdleSettings.IdleDuration = "PT05M"
        $sets.IdleSettings.WaitTimeout = "PT60M"
        $sets.IdleSettings.StopOnIdleEnd = $true
        $trg = $taskdef.Triggers.Create(6)
        $act = $taskdef.Actions.Create(0)
        $act.Path = "C:\Windows\system32\rundll32.exe"
        $act.Arguments = "user32.dll,LockWorkStation"
        $username = "$env:userdomain" + "\" + "$env:username"
        $user = "$username"
        $rootFolder.RegisterTaskDefinition($TaskName, $taskdef, 6, $user, $null, 3)
        
        Log "Showing Task Manager details"
        If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager"))
        {
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Force | Out-Null
        }
        $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
        If (!($preferences))
        {
            $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
            While (!($preferences))
            {
                Start-Sleep -m 250
                $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
            }
            Stop-Process $taskmgr
        }
        $preferences.Preferences[28] = 0
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -Type Binary -Value $preferences.Preferences
        
        Log "Showing file operations details"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Value "1"
        
        Log "Disabling and Uninstalling OneDrive"
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) 
        {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSync" -Type Dword -Value 1
        Stop-Process -Name OneDrive -ErrorAction SilentlyContinue
        Start-Sleep -s 3
        $onedrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
        If (!(Test-Path $onedrive)) 
        {
            $onedrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
        }
        Start-Process $onedrive "/uninstall" -NoNewWindow -Wait
        Start-Sleep -s 3
        Stop-Process -Name explorer -ErrorAction SilentlyContinue
        Start-Sleep -s 3
        Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
        
        Log "Removing Onedrive From Explorer"
        SetReg -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value "0"
        SetReg -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value "0"

        Log "Removing OneDrive Startup Entry"
        $Bin = "03,00,00,00,cd,9a,36,38,64,0b,d2,01"
        $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
        $AttrName = "OneDrive"
        $hexified = $Bin.Split(',') | ForEach-Object -Process { "0x$_"}
        New-ItemProperty -Path $RegPath -Name $AttrName -PropertyType Binary -Value ([byte[]]$hexified) -Force

        Log "Adding OpenPSHere to right click menu"
        $menu = 'OpenPSHere'
        $command = "$PSHOME\powershell.exe -NoExit -NoProfile -Command ""Set-Location '%V'"""

        'directory', 'directory\background', 'drive' | ForEach-Object {
            New-Item -Path "Registry::HKEY_CLASSES_ROOT\$_\shell" -Name runas\command -Force |
                Set-ItemProperty -Name '(default)' -Value $command -PassThru |
                Set-ItemProperty -Path {$_.PSParentPath} -Name '(default)' -Value $menu -PassThru |
                Set-ItemProperty -Name HasLUAShield -Value ''
        }

        # Applications

        Log "Installing Linux Subsystem"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value "1"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Value "1"

        Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
        
        Log "Removing system bloat"
        $Features = Get-WindowsOptionalFeature -Online | Where-Object `
        {
            $_.FeatureName -notlike '*Net*FX*' `
                -and $_.FeatureName -notlike '*Internet-Explorer*' `
                -and $_.FeatureName -notlike '*Powershell*' `
                -and $_.FeatureName -notlike '*Printing*' `
                -and $_.FeatureName -notlike '*Linux*' `
        } | Sort-Object -Property { $_.FeatureName.Length }
        
        ForEach ($Feature in $Features)
        {
            If ($Feature.State -eq 'Enabled')
            {
                $Feature | Disable-WindowsOptionalFeature -Online -Remove -NoRestart > $null 3> $null
                Log "Disabling Feature: $($Feature.FeatureName)"
            }    
        }    
    }

    End
    {
        Stop-Log
    }

}   

# Set-HomePC

<#######</Body>#######>
<#######</Script>#######>