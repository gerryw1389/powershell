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
    .Example
    Set-HomePC
    W10 config script.
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
        Write-Output "Creating a lockscreen task. This will lock the screen every 5 minutes of inactivity"
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
        $rootFolder.RegisterTaskDefinition($TaskName, $taskdef, 6, $user, $null, 3) | Out-Null

        Write-Output "Adding OpenPSHere to right click menu"
        $menu = 'OpenPSHere'
        $command = "$PSHOME\powershell.exe -NoExit -NoProfile -Command ""Set-Location '%V'"""

        'directory', 'directory\background', 'drive' | ForEach-Object {
            New-Item -Path "Registry::HKEY_CLASSES_ROOT\$_\shell" -Name runas\command -Force |
                Set-ItemProperty -Name '(default)' -Value $command -PassThru |
                Set-ItemProperty -Path {$_.PSParentPath} -Name '(default)' -Value $menu -PassThru |
                Set-ItemProperty -Name HasLUAShield -Value ''
        }

        Write-Output "Enabling SMB 1.0 protocol for connections to legacy NAS devices"
        Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force

        Write-Output "Adjusting visual effects for appearance..."
        SetReg -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -PropertyType "String" -Value "1"
        SetReg -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -PropertyType "String" -Value "400"
        SetReg -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -PropertyType "Binary" -Value "9e,7e,06,80,12,00,00,00"
        SetReg -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -PropertyType "String" -Value "1"
        SetReg -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "1"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value "1"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value "1"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value "1"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value "3"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value "1"
    
        Write-Output "Disabling Windows Update automatic restart"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value "1"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Value "0"

        Write-Output "Stopping and disabling Home Groups services"
        Stop-Service "HomeGroupListener" -WarningAction SilentlyContinue
        Set-Service "HomeGroupListener" -StartupType Disabled
        Stop-Service "HomeGroupProvider" -WarningAction SilentlyContinue
        Set-Service "HomeGroupProvider" -StartupType Disabled

        Write-Output "Starting and enabling Windows Search indexing service"
        Set-Service "WSearch" -StartupType Automatic
        SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch" -Name "DelayedAutoStart" -Value "1"
        Start-Service "WSearch" -WarningAction SilentlyContinue

        Write-Output "Enabling Fast Startup"
        SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value "1"

        Write-Output "Disabling Action Center"
        If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"))
        {
            New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
        }
        SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value "1"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value "0"

        Write-Output "Disabling Sticky keys prompt"
        SetReg -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -PropertyType "String" -Value "506"

        Write-Output "Disabling file delete confirmation dialog"
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ConfirmFileDelete" -ErrorAction SilentlyContinue
    
        Write-Output "Showing Task Manager details"
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
    
        Write-Output "Showing file operations details"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Value "1"
    
        Write-Output "Disabling and Uninstalling OneDrive"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value "1"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSync" -Value "1"
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
    
        Write-Output "Removing Onedrive From Explorer"
        SetReg -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value "0"
        SetReg -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value "0"

        Write-Output "Removing OneDrive Startup Entry"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "OneDrive" -PropertyType "Binary" -Value "03,00,00,00,cd,9a,36,38,64,0b,d2,01"
  
        Write-Output "Installing Linux Subsystem"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value "1"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Value "1"
        Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
    
        <#
        # I used to disable features, but I honestly don't think it's worth the hassle anymore.

        Write-Output "Removing system bloat"
        $Features = Get-WindowsOptionalFeature -Online | Where-Object `
        {
        $_.FeatureName -notlike '*Net*FX*' `
        -and $_.FeatureName -notlike '*Internet-Explorer*' `
        -and $_.FeatureName -notlike '*SMB1*' `
        -and $_.FeatureName -notlike '*Powershell*' `
        -and $_.FeatureName -notlike '*Printing*' `
        -and $_.FeatureName -notlike '*Linux*' `
        -and $_.FeatureName -notlike '*WCF*' `
        -and $_.FeatureName -notlike '*Defender*' `
        } | Sort-Object -Property { $_.FeatureName.Length }

        ForEach ($Feature in $Features)
        {
        If ($Feature.State -eq 'Enabled')
        {
        $Feature | Disable-WindowsOptionalFeature -Online -Remove -NoRestart > $null 3> $null
        Write-Output "Disabling Feature: $($Feature.FeatureName)"
        }    
        }
        #> 
    }

    End
    {
    }

}

<#######</Body>#######>
<#######</Script>#######>