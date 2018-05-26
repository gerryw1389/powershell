<#######<Script>#######>
<#######<Header>#######>
# Name: Set-Template
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-Template
{
    <#
.Synopsis
W10 config script.
.Description
W10 config script that I run on any generic W10 install. It sets settings that I use often and makes a generic "clean image".
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
.Example
Set-Template
W10 config script.
.Notes
2018-05-05: Updated for W10v1803.
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>   
    
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-Template.Log"
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
        Try
        {
            Import-Module "$Psscriptroot\..\Private\helpers.psm1" -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'Helpers' was not found, stopping script" | Timestamp
            Exit 1
        }
    }
    
    Process
    {    
        Write-Output "Setting User Privacy Settings" | TimeStamp

        Write-Output "Removing App Telemetry Settings for..." | TimeStamp
        Write-Output "Location" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "Value" -Value "Deny" -PropertyType "String"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E6AD100E-5F4E-44CD-BE0F-2265D88D14F5}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "Camera" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E5323777-F976-4f5b-9B55-B94699C46E44}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "Calendar" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{D89823BA-7180-4B81-B50C-7E471E6121A3}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "Contacts" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{7D7E8402-7C54-4821-A34E-AEEFD62DED93}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "Notifications" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{52079E78-A92B-413F-B213-E8FE35712E72}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "Microphone" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2EEF81BE-33FA-4800-9670-1CD474972C3F}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "Account Info" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "Call history" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{8BC668CF-7728-45BD-93F8-CF2B3B41D7AB}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "Email, may break the Mail app?" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{9231CB4C-BF57-4AF3-8C55-FDA7BFCC04C5}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "TXT/MMS" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{992AFA70-6F47-4148-B3E9-3003349C1548}" -Name "Value" -Value "Deny" -PropertyType "String"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{21157C1F-2651-4CC1-90CA-1F28B02263F6}" -Name "Value" -Value "Deny" -PropertyType "String"
        Write-Output "Radios" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}" -Name "Value" -Value "Deny" -PropertyType "String"

        Write-Output "Disabling Notifications for lockscreen" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" -Value "0"
		
        Write-Output "Disabling Notifications" | TimeStamp
        $RegPaths = Get-ChildItem -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" 
        ForEach ($RegPath in $RegPaths) 
        {
            SetReg -Path $RegPath.PsPath -Name "Enabled" -Value "0"
        }
    
        Write-Output "Lockscreen suggestions, rotating pictures" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value "0"  
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value "0"
    
        Write-Output "Disabling Welcome Experience Notification" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Value "0"

        Write-Output "Preinstalled apps, Minecraft Twitter etc all that - Enterprise only it seems" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OEMPreInstalledAppsEnabled" -Value "0"
    
        Write-Output "Stop MS shoehorning apps quietly into your profile" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Value "0"

        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContentEnabled" -Value "0"
    
        Write-Output "Ads in File Explorer" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ShowSyncProviderNotifications" -Value "0"
    
        Write-Output "Disabling auto update and download of Windows Store Apps - enable if you are not using the store" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value "2"
    
        Write-Output "Let websites provide local content by accessing language list" | TimeStamp
        SetReg -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Value "1"
    
        Write-Output "Let apps share and sync non-explicitly paired wireless devices over uPnP" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled" -Name "Value" -Value "Deny" -PropertyType "String"
    
        Write-Output "Don't ask for feedback" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -Value "0" 
    
        Write-Output "Stopping Cortana/Microsoft from getting to know you" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Name "Enabled" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value "1" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value "1" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Input\TIPC" -Name "Enabled" -Value "0" 
    
        Write-Output "Disabling Cortana and Bing search user settings" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaEnabled" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "DeviceHistoryEnabled" -Value "0"

        $Build = (Get-CimInstance -ClassName CIM_OperatingSystem).Buildnumber
        If ($Build -like "17*")
        {
            Write-Output "New Build detected: Blocking Internet Search via Windows Search" | TimeStamp
            SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value "0"
            SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "AllowSearchToUseLocation" -Value "0"
            SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value "0"
        }
    
        Write-Output "Below takes search bar off the taskbar, personal preference" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value "0"
    
        Write-Output "Stop Cortana from remembering history" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "HistoryViewEnabled" -Value "0"

        Write-Output "Disabling Shared Experiences" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" -Name "RomeSdkChannelUserAuthzPolicy" -Value "0"
    
        Write-Output "Disabling Bing In Start Menu and Cortana In Search" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value "0"
    
        Function Remove-AutoLogger
        {
            Write-Output "Removing Autologger File And Restricting Directory" | TimeStamp
    
            $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
            If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl")
            {
                Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
            }
            cmd /c "icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F" | Out-Null
        } 
        Remove-AutoLogger

        Write-Output "Setting Global User Settings" | TimeStamp
    
        Write-Output "Setting Visual Style to best visual" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value "1"

        Write-Output "Disabling Autoplay" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Value "1"

        Write-Output "Disabling Auto Update And Download Of Windows Store Apps" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value "2"

        Write-Output "Setting Explorer Default To This PC" | TimeStamp
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value "1"

        Write-Output "Setting Explorer Default To Show File Extensions" | TimeStamp
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value "0"

        Write-Output "Setting Checkboxes in Explorer" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AutoCheckSelect" -Value "1"
		
        Write-Output "Setting Windows to not track app launches" | TimeStamp
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value "0"

        Write-Output "Setting Windows Powershell to default on Win X Menu" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DontUsePowerShellOnWinX" -Value "0"
    
        Write-Output "Unchecking Show Recently Used Files In Quick Access" | TimeStamp
        SetReg -Path "HKCU:\Software\Microsoft\Windows\Currentversion\Explorer" -Name "ShowRecent" -Value "0"

        Write-Output "Unchecking Show Frequently Used Folders In Quick Access" | TimeStamp
        SetReg -Path "HKCU:\Software\Microsoft\Windows\Currentversion\Explorer" -Name "ShowFrequent" -Value "0"

        Write-Output "Disabling AeroShake" | TimeStamp
        SetReg -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "NoWindowMinimizingShortcuts" -Value "1"

        Write-Output "Hiding Cortana" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value "0"

        Write-Output "Disabling Sticky keys prompt" | TimeStamp
        SetReg -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -PropertyType "String"

        Write-Output "Disabling TaskBar People Icon" | TimeStamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Value "0"
		
        Write-Output "Disabling Taskview on Taskbar" | Timestamp
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value "0"

        Function Set-DesktopIcons
        {
            Write-Output "Setting Desktop Icons: My PC, User Files, and Recycle Bin on Desktop / Remove OneDrive" | TimeStamp
    
            # Make Sure Hide Desktop Icons Is Off
            SetReg -Path "HKCU:\Software\Microsoft\Windows\Currentversion\Explorer\Advanced" -Name "Hideicons" -Value "0"
            # My PC
            SetReg -Path "HKCU:\Software\Microsoft\Windows\Currentversion\Explorer\Hidedesktopicons\Newstartpanel" -Name "{20d04fe0-3aea-1069-A2d8-08002b30309d}" -Value "0"
            # User Files
            SetReg -Path "HKCU:\Software\Microsoft\Windows\Currentversion\Explorer\Hidedesktopicons\Newstartpanel" -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value "0"
            # Recycle Bin
            SetReg -Path "HKCU:\Software\Microsoft\Windows\Currentversion\Explorer\Hidedesktopicons\Newstartpanel" -Name "{645ff040-5081-101b-9f08-00aa002f954e}" -Value "0"
            # Remove One Drive
            SetReg -Path "HKCU:\Software\Microsoft\Windows\Currentversion\Explorer\Hidedesktopicons\Newstartpanel" -Name "{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Value "1"
        }
        Set-DesktopIcons

        Function Remove-UserFoldersFromExplorer
        {
            Write-Output "Removing User Folders From This PC" | TimeStamp
            # Documents
            $Params = @{}
            $Params.Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag"
            $Params.Name = "ThisPCPolicy"
            $Params.Value = "Hide"
            $Params.PropertyType = "String"
            SetReg @Params
            $Params = $null
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            # Pictures
            $Params = @{}
            $Params.Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{0ddd015d-b06c-45d5-8c4c-f59713854639}\PropertyBag"
            $Params.Name = "ThisPCPolicy"
            $Params.Value = "Hide"
            $Params.PropertyType = "String"
            SetReg @Params
            $Params = $null
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            # Videos
            $Params = @{}
            $Params.Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag"
            $Params.Name = "ThisPCPolicy"
            $Params.Value = "Hide"
            $Params.PropertyType = "String"
            SetReg @Params
            $Params = $null
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            # Downloads
            $Params = @{}
            $Params.Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag"
            $Params.Name = "ThisPCPolicy"
            $Params.Value = "Hide"
            $Params.PropertyType = "String"
            SetReg @Params
            $Params = $null
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            # Music
            $Params = @{}
            $Params.Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{a0c69a99-21c8-4671-8703-7934162fcf1d}\PropertyBag"
            $Params.Name = "ThisPCPolicy"
            $Params.Value = "Hide"
            $Params.PropertyType = "String"
            SetReg @Params
            $Params = $null
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            # Desktop
            $Params = @{}
            $Params.Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag"
            $Params.Name = "ThisPCPolicy"
            $Params.Value = "Hide"
            $Params.PropertyType = "String"
            SetReg @Params
            $Params = $null
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            #3D Objects
            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
            $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
            IF (Test-Path $Path)
            {
                Remove-Item $Path | Out-Null
            }
        }
        Remove-UserFoldersFromExplorer

    
        Write-Output "Setting System Privacy Settings" | TimeStamp
    
        # Local Group Policy Settings - Can be adjusted in GPedit.msc in Pro+ editions. Local Policy/Computer Config/Admin Templates/Windows Components			
        Write-Output "Removing App Telemetry Settings for..." | TimeStamp
        Write-Output "Account Info" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessAccountInfo" -Value "2" 
        Write-Output "Calendar" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessCalendar" -Value "2" 
        Write-Output "Call History" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessCallHistory" -Value "2" 
        Write-Output "Contacts" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessContacts" -Value "2" 
        Write-Output "Email" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessEmail" -Value "2" 
        Write-Output "Location" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessLocation" -Value "2" 
        Write-Output "Messaging" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessMessaging" -Value "2" 
        Write-Output "Microphone - This one, let the user choose" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessMicrophone" -Value "0" 
        Write-Output "Motion" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessMotion" -Value "2" 
        Write-Output "Notifications" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessNotifications" -Value "2" 
        Write-Output "Make Phone Calls" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessPhone" -Value "2" 
        Write-Output "Radios" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessRadios" -Value "2" 
        Write-Output "Access trusted devices" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessTrustedDevices" -Value "2" 
        Write-Output "Sync with devices" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsSyncWithDevices" -Value "2"
        Write-Output "Tasks" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessTasks" -Value "2"

        Write-Output "Application Compatibility Settings..." | TimeStamp
        Write-Output "Turn off Application Telemetry" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Value "0" 			
        Write-Output "Turn off inventory collector" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableInventory" -Value "1" 
        Write-Output "Turn off steps recorder" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableUAR" -Value "1" 

        Write-Output "Cloud Content Settings..." | TimeStamp
        Write-Output "Do not show Windows Tips" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding" -Value "1" 
        Write-Output "Turn off Consumer Experiences" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value "1" 
  
        Write-Output "Data Collection Settings..." | TimeStamp
        Write-Output "Set Telemetry to Basic" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value "0" 
        SetReg -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value "0"  
        Write-Output "Disable pre-release features and settings" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Name "EnableConfigFlighting" -Value "0" 
        Write-Output "Do not show feedback notifications" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value "1" 

        Write-Output "Delivery Optimization Settings..." | TimeStamp
        # Disable DO; set to "1" to allow DO over LAN only			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value "0" 
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DownloadMode" -Value "0" 
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value "0" 
    
        Write-Output "Location and Sensors" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value "1" 
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableSensors" -Value "1" 

        Write-Output "Microsoft Edge - Always send do not track" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Name "DoNotTrack" -Value "1" 

        Write-Output "Disabling Cortana..." | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value "0"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "BingSearchEnabled" -Value "0" 
        Write-Output "Disallow Cortana on lock screen" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock" -Value "0" 
        Write-Output "Disallow web search from desktop search" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value "1"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCloudSearch" -Value "0"
        Write-Output "Don't search the web or display web results in search" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value "0" 

        Write-Output "Windows Store..." | TimeStamp
        Write-Output "Turn off Automatic download/install of app updates" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value "2" 		
        
        Write-Output "Sync Settings..." | TimeStamp
        Write-Output "Do not syncanything" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSync" -Value "2" 
        Write-Output "Disallow users to override this" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSyncUserOverride" -Value "1" 

        Write-Output "Windows Update Settings..." | TimeStamp
        Write-Output "Turn off featured software notifications through WU (basically ads)" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "EnableFeaturedSoftware" -Value "0" 

        Write-Output "Disabling Wifi Sense" | TimeStamp
        SetReg -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Value "0"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Value "0"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "WiFISenseAllowed" -Value "0"

        Write-Output "Disabling Location Tracking" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Value "0"
        SetReg -Path "HKLM:\System\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value "0"

        Write-Output "Disabling Map tracking" | TimeStamp
        SetReg -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Value "0"

        Write-Output "Disable Error Reporting" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value "1"

        Write-Output "Disabling advertising info and device metadata collection for this machine" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value "0" 
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Value "1" 
    
        Write-Output "Prevent apps on other devices from opening apps on this PC" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SmartGlass" -Name "UserAuthPolicy " -Value "0"

        Write-Output "Allowing SmartScreen Filter for Windows, Edge, and Store apps" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -PropertyType "String" -Value "Warn"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter" -Name "EnabledV9" -Value "1"
        SetReg -Path "HKCU:\\Software\Microsoft\Windows\CurrentVersion\AppHost" -Name "EnableWebContentEvaluation" -Value "1" 
    
        Write-Output "Prevent using sign-in info to automatically finish setting up after an update" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "ARSOUserConsent" -Value "2"   
    
        Write-Output "Disable Malicious Software Removal Tool through WU, and CEIP" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\MRT" -Name "DontOfferThroughWUAU" -Value "1" 
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value "0"

        Write-Output "Setting System Settings" | TimeStamp

        Write-Output "Disabling The Built-In Admin Account" | TimeStamp
        Cmd /c "Net User Administrator /Active:No"
     
        Write-Output "Setting Power Settings To Never Sleep" | TimeStamp
        cmd /c "powercfg -change -monitor-timeout-ac 0"
        cmd /c "powercfg -change -monitor-timeout-dc 0"
        cmd /c "powercfg -change -standby-timeout-ac 0"
        cmd /c "powercfg -change -standby-timeout-dc 0"
        cmd /c "powercfg -change -disk-timeout-ac 0"
        cmd /c "powercfg -change -disk-timeout-dc 0"
        cmd /c "powercfg -change -hibernate-timeout-ac 0"
        cmd /c "powercfg -change -hibernate-timeout-dc 0"

        Write-Output "Disabling display and sleep mode timeouts..." | TimeStamp
        cmd /c "powercfg /X monitor-timeout-ac 0"
        cmd /c "powercfg /X monitor-timeout-dc 0"
        cmd /c "powercfg /X standby-timeout-ac 0"
        cmd /c "powercfg /X standby-timeout-dc 0"

        

        Write-Output "Enable F8 boot menu options" | TimeStamp
        cmd /c "bcdedit /set `{current`} bootmenupolicy Legacy" | Out-Null
 
        Write-Output "Setting time zone to Central Standard" | TimeStamp
        $TimeZone = 'Central Standard Time'
        If ( (Get-TimeZone).StandardName -eq $TimeZone)
        {
            Write-Output "The time zone is already set to $TimeZone." | TimeStamp
        }
        Else
        {
            Set-TimeZone -Name $TimeZone
            Write-Output "The time zone set to $TimeZone." | TimeStamp
        }

        Write-Output "Configuring To Allow Pings, RDP, WMI, and File and Printer Sharing Through Firewall" | TimeStamp
        Try
        {
            Import-Module NetSecurity -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'NetSecurity' was not found, stopping script" | Timestamp
            Exit 1
        }

        Write-Output "Setting RDP to allow inbound connections" | TimeStamp
        $Params = @{}
        $Params.DisplayName = "AllowRDP"
        $Params.Description = "Allow Remote Desktop"
        $Params.Profile = "Any"
        $Params.Direction = "Inbound"
        $Params.LocalPort = "3389"
        $Params.Protocol = "TCP"
        $Params.Action = "Allow"
        $Params.Enabled = "True"
        New-NetFirewallRule @Params | Out-Null
        $Params = $null

        Write-Output "Setting Ping firewall rule (in/out)" | TimeStamp
        $Params = @{}
        $Params.DisplayName = "AllowPingsOut"
        $Params.Description = "Allow Pings"
        $Params.Profile = "Any"
        $Params.Direction = "Outbound"
        $Params.Protocol = "ICMPv4"
        $Params.IcmpType = "Any"
        $Params.Action = "Allow"
        $Params.Enabled = "True"
        New-NetFirewallRule @Params| Out-Null
        $Params = $null

        $Params = @{}
        $Params.DisplayName = "AllowPingsIn"
        $Params.Description = "Allow Pings"
        $Params.Profile = "Any"
        $Params.Direction = "Inbound"
        $Params.Protocol = "ICMPv4"
        $Params.IcmpType = "Any"
        $Params.Action = "Allow"
        $Params.Enabled = "True"
        New-NetFirewallRule @Params| Out-Null
        $Params = $null
    
        # Some of these may be redundant, but wanted to include just in case
        # Network Discovery: netsh advfirewall firewall set rule group=”network discovery” new enable=yes
        # File and Printer Sharing: netsh firewall set service type=fileandprint mode=enable profile=all
        Write-Output "Setting Remote Desktop firewall rule" | TimeStamp
        Set-NetFirewallRule -DisplayGroup "Remote Desktop" -Profile Any -Enabled True | Out-Null    
        Write-Output "Setting Windows Management Instrumentation (WMI) firewall rule" | TimeStamp
        Set-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)" -Profile Any -Enabled True | Out-Null
        Write-Output "Setting Network Discovery firewall rule" | TimeStamp
        Set-NetFirewallRule -DisplayGroup "Network Discovery" -Profile Any -Enabled True | Out-Null
        Write-Output "Setting File and Printer Sharing firewall rule" | TimeStamp
        Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Profile Any -Enabled True | Out-Null
        Write-Output "Setting Windows Remote Management firewall rule" | TimeStamp
        Set-NetFirewallRule -DisplayGroup "Windows Remote Management" -Profile Any -Enabled True | Out-Null
        Write-Output "Setting Core Networking firewall rule" | TimeStamp
        Set-NetFirewallRule -DisplayGroup "Core Networking" -Profile Any -Enabled True | Out-Null

        Write-Output "Setting UAC Setting To Third Bar Down (Notify When Apps Make Changes… Don't Dim)" | TimeStamp
        SetReg -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value "0"
        SetReg -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableInstallerDetection" -Value "0"
        SetReg -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value "0"
        SetReg -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "FilterAdministratorToken" -Value "0"
    
        Write-Output "Removing memory dumping, event logging, and automatic restarts on operating system crashes" | TimeStamp
        SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value "0"
        
        Write-Output "Disabling Windows Update automatic restart" | TimeStamp
        SetReg -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name "NoAutoRebootWithLoggedOnUsers" -Value "1"
        SetReg -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Value "1"
    
        Write-Output "Disabling search for app in store for unknown extensions" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoUseStoreOpenWith" -Value "1"
    
        Write-Output "Disabling Autorun for all drives" | TimeStamp
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value "255"
    
        Write-Output "Enabling Remote Desktop With Network Level Authentication" | TimeStamp
        SetReg -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value "0"
        SetReg -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value "0"
    
        Write-Output "Disabling Remote Assistance" | TimeStamp
        SetReg -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value "0"

        Write-Output "Setting Control Panel view to small icons..." | TimeStamp
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" -Name "AllItemsIconView" -Value "1"

        Function EnableNumlock
        {
            Write-Output "Enabling NumLock after startup..." | TimeStamp
            If (!(Test-Path "HKU:"))
            {
                New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
            }
            New-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -PropertyType DWord -Value 2147483650 -Force | Out-Null
            Add-Type -AssemblyName System.Windows.Forms
            If (!([System.Windows.Forms.Control]::IsKeyLocked('NumLock')))
            {
                $wsh = New-Object -ComObject WScript.Shell
                $wsh.SendKeys('{NUMLOCK}')
            }
        }
        EnableNumlock
	
        Function Set-StartMenu
        {
            Write-Output "Setting a default start menu for all users" | TimeStamp
            $startlayoutstr = @"
<LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
  <defaultlayout:StartLayout GroupCellWidth="6" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout">
    <start:Group Name="" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout">
  <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
  <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Accessories\Snipping Tool.lnk" />
		  <start:DesktopApplicationTile Size="2x2" Column="0" Row="2" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Control Panel.lnk" />
    </start:Group>
  </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@
            Add-Content $Env:Temp\Startlayout.Xml $Startlayoutstr
            Import-Startlayout -Layoutpath $Env:Temp\Startlayout.Xml -Mountpath $Env:Systemdrive\
            Remove-Item $Env:Temp\Startlayout.Xml
        }
        Set-StartMenu

        Function Set-PhotoViewer
        {
            Write-Output "Setting up Windows Photo Viewer" | TimeStamp
            If (!(Test-Path "HKCR:")) 
            {
                New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
            }
            ForEach ($type in @("Paint.Picture", "giffile", "jpegfile", "pngfile")) 
            {
                New-Item -Path $("HKCR:\$type\shell\open") -Force | Out-Null
                New-Item -Path $("HKCR:\$type\shell\open\command") | Out-Null
                New-ItemProperty -Path $("HKCR:\$type\shell\open") -Name "MuiVerb" -PropertyType ExpandString `
                    -Value "@%ProgramFiles%\Windows Photo Viewer\photoviewer.dll,-3043" -Force | Out-Null
                New-ItemProperty -Path $("HKCR:\$type\shell\open\command") -Name "(Default)" -PropertyType ExpandString `
                    -Value "%SystemRoot%\System32\rundll32.exe `"%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll`", ImageView_Fullscreen %1" -Force | Out-Null
            }
            New-Item -Path "HKCR:\Applications\photoviewer.dll\shell\open\command" -Force | Out-Null
            New-Item -Path "HKCR:\Applications\photoviewer.dll\shell\open\DropTarget" -Force | Out-Null
            New-ItemProperty -Path "HKCR:\Applications\photoviewer.dll\shell\open" -Name "MuiVerb" -PropertyType String -Value "@photoviewer.dll,-3043" -Force | Out-Null
            New-ItemProperty -Path "HKCR:\Applications\photoviewer.dll\shell\open\command" -Name "(Default)" -PropertyType ExpandString `
                -Value "%SystemRoot%\System32\rundll32.exe `"%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll`", ImageView_Fullscreen %1" -Force | Out-Null
            New-ItemProperty -Path "HKCR:\Applications\photoviewer.dll\shell\open\DropTarget" -Name "Clsid" -PropertyType String `
                -Value "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" -Force | Out-Null
        } 
        Set-PhotoViewer

    
        Write-Output "Stopping and Disabling Diagnostics Tracking Service, WAP Push Service, Home Groups service, Xbox Services, and Other Unncessary Services" | TimeStamp
        $Services = @()
        $Services += "Diagtrack"
        $Services += "Xblauthmanager"
        $Services += "Xblgamesave"
        $Services += "Xboxnetapisvc"
        $Services += "Trkwks"
        $Services += "dmwappushservice"
        Foreach ($Service In $Services) 
        {
            Write-Output "Stopping Service $Service and setting startup to disabled" | TimeStamp
            Get-Service $Service | Stop-Service -Passthru | Set-Service -Startuptype Disabled | Out-Null
        }
    
        $Tasks = @()
        $Tasks += "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
        $Tasks += "Microsoft\Windows\Application Experience\ProgramDataUpdater"
        $Tasks += "Microsoft\Windows\Autochk\Proxy"
        $Tasks += "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
        $Tasks += "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
        $Tasks += "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
        $Tasks += "Microsoft\Windows\NetTrace\GatherNetworkInfo"  
        $Tasks += "Microsoft\Windows\Windows Error Reporting\QueueReporting"
        $Tasks += "Microsoft\Windows\Feedback\Siuf\DmClient"
        $Tasks += "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" 
        ForEach ($Task in $Tasks)
        {
            Write-Output "Disabing $Task" | TimeStamp
            Disable-ScheduledTask -TaskName $Task | Out-Null
        }

        Write-Output "Disabling Xbox features..." | TimeStamp
        Get-AppxPackage "Microsoft.XboxApp" | Remove-AppxPackage | Out-Null
        Get-AppxPackage "Microsoft.XboxIdentityProvider" | Remove-AppxPackage | Out-Null
        Get-AppxPackage "Microsoft.XboxSpeechToTextOverlay" | Remove-AppxPackage | Out-Null
        Get-AppxPackage "Microsoft.XboxGameOverlay" | Remove-AppxPackage | Out-Null
        Get-AppxPackage "Microsoft.Xbox.TCUI" | Remove-AppxPackage | Out-Null
        New-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -PropertyType DWord -Value 0 -Force | Out-Null
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"))
        {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" | Out-Null
        }
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -PropertyType DWord -Value 0 -Force | Out-Null
    
        Write-Output "Removing Unwanted Default Apps" | TimeStamp
        $Packages = $a = Get-Appxpackage -Allusers | Where-Object { $_.Name -Notlike "*Store*" } |
            Where-Object { $_.Name -Notlike "*.NET*" } |
            Where-Object { $_.Name -Notlike "*Paint*" } |
            Where-Object { $_.Name -Notlike "*Print*" } |
            Where-Object { $_.Name -Notlike "*Edge*" } |
            Where-Object { $_.Name -Notlike "*Calculator*" } |
            Sort-Object -Property { $_.Name.Length }
    
        ForEach ($Package in $Packages)
        {
            Write-Output "Uninstalling: $($Package.Name)" | TimeStamp
            Remove-Appxpackage -Package $($Package.Name) -Erroraction Silentlycontinue | Out-Null
        }

        $PPackages = Get-Appxprovisionedpackage -Online | Where-Object { $_.Packagename -Notlike "*Store*" } |
            Where-Object { $_.Packagename -Notlike "*.NET*" } |
            Where-Object { $_.Packagename -Notlike "*Paint*" } |
            Where-Object { $_.Packagename -Notlike "*Print*" } |
            Where-Object { $_.Packagename -Notlike "*Edge*" } |
            Where-Object { $_.Packagename -Notlike "*Calculator*" } |
            Sort-Object -Property { $_.PackageName.Length }   
    
        ForEach ($PPackage in $PPackages)
        {
            Write-Output "Uninstalling: $($PPackage.PackageName)" | TimeStamp
            Remove-Appxprovisionedpackage -PackageName $($PPackage.PackageName) -Online -Erroraction Silentlycontinue | Out-Null
        }
     
    }

    End
    {
        Write-Output "Enabling System Restore and creating a checkpoint" | TimeStamp
        Enable-ComputerRestore -Drive $env:systemdrive -Verbose
        Checkpoint-Computer -Description "Default Config" -RestorePointType "MODIFY_SETTINGS" -Verbose
        
        Write-Output "Setting Execution Policy Back To Correct Settings" | TimeStamp
        Write-Output "Ignore the error" | TimeStamp
        Set-Executionpolicy Remotesigned -Force | Out-Null

        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
        
        Write-Output "Configuration Complete. Press any key to reboot the computer" | TimeStamp
        cmd /c "Pause"
        Restart-Computer  
    }

}
<#
Below are features that used to work in prior versions that seem to throw errors now.
Some are ones I never implemented anyways but you may want to:

Write-Output "Disabling Let Apps Access Camera" | TimeStamp
SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessCamera" -Value "2" 

Write-Output "Disabling Delivery Optomization" | TimeStamp
SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization" -Name "SystemSettingsDownloadMode" -Value "3"

Write-Output "Disabling WifiSense" | TimeStamp
SetReg -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Value "0"

Write-Output "Disabling Sleep start menu and keyboard button..." | TimeStamp
SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowSleepOption" -Value "0"
cmd /c "powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0"
cmd /c "powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0"

Write-Output "Disabling Hibernation" | TimeStamp
SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Value "0"

Write-Output "Allowing Lock Screen" | TimeStamp
SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value "0"
SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoChangingLockScreen" -Value "0"

Write-Output "Unpinning all items on taskbar - Irreversible!" | Timestamp
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name "Favorites" -PropertyType Binary -Value ([byte[]](0xFF)) -Force
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name "FavoritesResolve" -ErrorAction SilentlyContinue

Write-Output "Enabling built-in Adobe Flash in IE and Edge..." | Timestamp
Remove-ItemProperty -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Addons" -Name "FlashPlayerEnabled" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Ext\Settings\{D27CDB6E-AE6D-11CF-96B8-444553540000}" -Name "Flags" -ErrorAction SilentlyContinue

Disable all apps from store, left disabled by default			
SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "DisableStoreApps" -Value "1" 
Turn off Store, left disabled by default
SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "RemoveWindowsStore" -Value "1" 

Write-Output "Setting current network profile to private" | TimeStamp
Set-NetConnectionProfile -NetworkCategory Private

Write-Output "Removing memory dumping, event logging, and automatic restarts on operating system crashes" | TimeStamp
SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "LogEvent" -Value "0"
SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value "0"

Write-Output "Unpinning all Taskbar icons. Pin back the ones you want" | TimeStamp
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name "Favorites" -Type Binary -Value ([byte[]](255))
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name "FavoritesResolve" -ErrorAction SilentlyContinue

# These services don't seem to be installed in W10v1803
$Services += "Homegroupprovider"
$Services += "Wmpnetworksvc"

#>

<#######</Body>#######>
<#######</Script>#######>