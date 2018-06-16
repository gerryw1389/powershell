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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
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
        <#######<Default Begin Block>#######>
        # Set logging globally if it has any value in the parameter so helper functions can access it.
        If ($($Logfile.Length) -gt 1)
        {
            $Global:EnabledLogging = $True
            New-Variable -Scope Global -Name Logfile -Value $Logfile
        }
        Else
        {
            $Global:EnabledLogging = $False
        }
        
        # If logging is enabled, create functions to start the log and stop the log.
        If ($Global:EnabledLogging)
        {
            Function Start-Log
            {
                <#
                .Synopsis
                Function to write the opening part of the logfile.
                .Description
                Function to write the opening part of the logfil.
                It creates the directory if it doesn't exists and then the log file automatically.
                It checks the size of the file if it already exists and clears it if it is over 10 MB.
                If it exists, it creates a header. This function is best placed in the "Begin" block of a script.
                .Notes
                NOTE: The function requires the Write-ToString function.
                2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                2017-10-19: v1.0 Initial function
                #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True)]
                    [String]$Logfile
                )
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
                [Double]$Sizemax = 10485760
                $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
                If ($($Size.Sum -ge $SizeMax))
                {
                    Get-Childitem $Logfile | Clear-Content
                    Write-Verbose "Logfile has been cleared due to size"
                }
                Else
                {
                    Write-Verbose "Logfile was less than 10 MB"   
                }
                # Start writing to logfile
                Start-Transcript -Path $Logfile -Append 
                Write-ToString "####################<Script>####################"
                Write-ToString "Script Started on $env:COMPUTERNAME"
            }
            Start-Log

            Function Stop-Log
            {
                <# 
                    .Synopsis
                    Function to write the closing part of the logfile.
                    .Description
                    Function to write the closing part of the logfile.
                    This function is best placed in the "End" block of a script.
                    .Notes
                    NOTE: The function requires the Write-ToString function.
                    2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                    2017-10-19: v1.0 Initial function 
                    #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True)]
                    [String]$Logfile
                )
                Write-ToString "Script Completed on $env:COMPUTERNAME"
                Write-ToString "####################</Script>####################"
                Stop-Transcript
            }
        }

        # Declare a Write-ToString function that doesn't depend if logging is enabled or not.
        Function Write-ToString
        {
            <# 
        .Synopsis
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Description
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Parameter InputObject
        This can be any PSObject that will be converted to string.
        .Parameter Color
        The color in which to display the string on the screen.
        Valid options are: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, 
        Red, White, and Yellow.
        .Example 
        Write-ToString "Hello Hello"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen and the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen in default text colors.
        .Example 
        Write-ToString "Hello Hello" -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow and to the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Example 
        Write-ToString (cmd /c "ipconfig /all") -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow that shows the computer's IP information.
        The same copy will be in the logfile. 
        The whole point of converting to strings is this works best with tables and such that usually distort in logfiles.
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Notes
        2018-06-13: v1.0 Initial function
        #>
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color,

                [Parameter(Mandatory = $False, Position = 2)]
                [String]$Logfile
            )
            
            $ConvertToString = Out-String -InputObject $InputObject -Width 100
            If ($Global:EnabledLogging)
            {
                # If logging is enabled and a color is defined, send to screen and logfile.
                If ($($Color.Length -gt 0))
                {
                    $previousForegroundColor = $Host.PrivateData.VerboseForegroundColor
                    $Host.PrivateData.VerboseForegroundColor = $Color
                    Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                    Write-Output "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString" | Out-File -Encoding ASCII -FilePath $Logfile -Append
                    $Host.PrivateData.VerboseForegroundColor = $previousForegroundColor
                }
                # If not, still send to logfile, but use default colors.
                Else
                {
                    Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                    Write-Output "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString" | Out-File -Encoding ASCII -FilePath $Logfile -Append
                }
            }
            # If logging isn't enabled, just send the string to the screen.
            Else
            {
                If ($($Color.Length -gt 0))
                {
                    $previousForegroundColor = $Host.PrivateData.VerboseForegroundColor
                    $Host.PrivateData.VerboseForegroundColor = $Color
                    Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                    $Host.PrivateData.VerboseForegroundColor = $previousForegroundColor
                }
                Else
                {
                    Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                }
            }
        }
        <#######</Default Begin Block>#######>

        # Load the required module(s) 
        Try
        {
            Import-Module "$Psscriptroot\..\Private\helpers.psm1" -ErrorAction Stop
        }
        Catch
        {
            Write-ToString "Module 'Helpers' was not found, stopping script"
            Exit 1
        }

    }
    
    Process
    {    
        Write-ToString "Creating a lockscreen task. This will lock the screen every 5 minutes of inactivity"
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

        Write-ToString "Adding OpenPSHere to right click menu"
        $menu = 'OpenPSHere'
        $command = "$PSHOME\powershell.exe -NoExit -NoProfile -Command ""Set-Location '%V'"""

        'directory', 'directory\background', 'drive' | ForEach-Object {
            New-Item -Path "Registry::HKEY_CLASSES_ROOT\$_\shell" -Name runas\command -Force |
                Set-ItemProperty -Name '(default)' -Value $command -PassThru |
                Set-ItemProperty -Path {$_.PSParentPath} -Name '(default)' -Value $menu -PassThru |
                Set-ItemProperty -Name HasLUAShield -Value ''
        }

        Write-ToString "Enabling SMB 1.0 protocol for connections to legacy NAS devices"
        Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force

        Write-ToString "Adjusting visual effects for appearance..."
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
    
        Write-ToString "Disabling Windows Update automatic restart"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value "1"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Value "0"

        Write-ToString "Stopping and disabling Home Groups services"
        Stop-Service "HomeGroupListener" -WarningAction SilentlyContinue
        Set-Service "HomeGroupListener" -StartupType Disabled
        Stop-Service "HomeGroupProvider" -WarningAction SilentlyContinue
        Set-Service "HomeGroupProvider" -StartupType Disabled

        Write-ToString "Starting and enabling Windows Search indexing service"
        Set-Service "WSearch" -StartupType Automatic
        SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch" -Name "DelayedAutoStart" -Value "1"
        Start-Service "WSearch" -WarningAction SilentlyContinue

        Write-ToString "Enabling Fast Startup"
        SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value "1"

        Write-ToString "Disabling Action Center"
        If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"))
        {
            New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
        }
        SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value "1"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value "0"

        Write-ToString "Disabling Sticky keys prompt"
        SetReg -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -PropertyType "String" -Value "506"

        Write-ToString "Disabling file delete confirmation dialog"
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ConfirmFileDelete" -ErrorAction SilentlyContinue
    
        Write-ToString "Showing Task Manager details"
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
    
        Write-ToString "Showing file operations details"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Value "1"
    
        Write-ToString "Disabling and Uninstalling OneDrive"
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
    
        Write-ToString "Removing Onedrive From Explorer"
        SetReg -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value "0"
        SetReg -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value "0"

        Write-ToString "Removing OneDrive Startup Entry"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "OneDrive" -PropertyType "Binary" -Value "03,00,00,00,cd,9a,36,38,64,0b,d2,01"
  
        Write-ToString "Installing Linux Subsystem"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value "1"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Value "1"
        Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
    
        <#
    # I used to disable features, but I honestly don't think it's worth the hassle anymore.

Write-ToString "Removing system bloat"
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
Write-ToString "Disabling Feature: $($Feature.FeatureName)"
    }    
    }
    #> 
    }

    End
    {
        If ($EnabledLogging)
        {
            Stop-Log
        }
    }

}   

# Set-HomePC

<#######</Body>#######>
<#######</Script>#######>