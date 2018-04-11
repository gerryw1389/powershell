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
Usually same as synopsis.
.Notes
2017-12-26: Updated to single file for one off executions.
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>   
    
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\Set-Template.Log"
    )

   
    Begin
    {
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    }
        
    Process
    {    
        Log "Setting User Privacy Settings" -Color Cyan

        Log "Removing App Telemetry Settings for..."
        Log "Location"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "Value" -Value "Deny" -PropertyType "String"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E6AD100E-5F4E-44CD-BE0F-2265D88D14F5}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "Camera"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E5323777-F976-4f5b-9B55-B94699C46E44}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "Calendar"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{D89823BA-7180-4B81-B50C-7E471E6121A3}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "Contacts"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{7D7E8402-7C54-4821-A34E-AEEFD62DED93}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "Notifications"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{52079E78-A92B-413F-B213-E8FE35712E72}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "Microphone"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2EEF81BE-33FA-4800-9670-1CD474972C3F}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "Account Info"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "Call history"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{8BC668CF-7728-45BD-93F8-CF2B3B41D7AB}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "Email, may break the Mail app?"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{9231CB4C-BF57-4AF3-8C55-FDA7BFCC04C5}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "TXT/MMS"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{992AFA70-6F47-4148-B3E9-3003349C1548}" -Name "Value" -Value "Deny" -PropertyType "String"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{21157C1F-2651-4CC1-90CA-1F28B02263F6}" -Name "Value" -Value "Deny" -PropertyType "String"
        Log "Radios"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}" -Name "Value" -Value "Deny" -PropertyType "String"

        Log "Disabling Notifications for lockscreen"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" -Value "0"
		
        Log "Disabling Notifications"
        $RegPaths = Get-ChildItem -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" 
        ForEach ($RegPath in $RegPaths) 
        {
            SetReg -Path $RegPath.PsPath -Name "Enabled" -Value "0"
        }
            
        Log "Lockscreen suggestions, rotating pictures"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value "0"  
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value "0"
        
        Log "Disabling Welcome Experience Notification"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Value "0"

        Log "Preinstalled apps, Minecraft Twitter etc all that - Enterprise only it seems"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OEMPreInstalledAppsEnabled" -Value "0"
            
        Log "Stop MS shoehorning apps quietly into your profile"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Value "0"

        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContentEnabled" -Value "0"
            
        Log "Ads in File Explorer"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ShowSyncProviderNotifications" -Value "0"
            
        Log "Disabling auto update and download of Windows Store Apps - enable if you are not using the store"
        SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value "2"
            
        Log "Let websites provide local content by accessing language list"
        SetReg -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Value "1"
            
        Log "Let apps share and sync non-explicitly paired wireless devices over uPnP"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled" -Name "Value" -Value "Deny" -PropertyType "String"
            
        Log "Don't ask for feedback"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -Value "0" 
            
        Log "Stopping Cortana/Microsoft from getting to know you"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Name "Enabled" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value "1" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value "1" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Input\TIPC" -Name "Enabled" -Value "0" 
            
        Log "Disabling Cortana and Bing search user settings"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaEnabled" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value "0" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "DeviceHistoryEnabled" -Value "0"

        $Build = (Get-CimInstance -ClassName CIM_OperatingSystem).Buildnumber
        If ($Build -like "17*")
        {
        Log "New Build detected: Blocking Internet Search via Windows Search"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "AllowSearchToUseLocation" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value "0"
        }
            
        Log "Below takes search bar off the taskbar, personal preference"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value "0"
            
        Log "Stop Cortana from remembering history"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "HistoryViewEnabled" -Value "0"

        Log "Disabling Shared Experiences"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" -Name "RomeSdkChannelUserAuthzPolicy" -Value "0"
            
        Log "Disabling Bing In Start Menu and Cortana In Search" 
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value "0"
            
        Log "Disabling Delivery Optomization"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization" -Name "SystemSettingsDownloadMode" -Value "3"

        Function Remove-AutoLogger
        {
            Log "Removing Autologger File And Restricting Directory" 
    
            $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
            If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl")
            {
                Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
            }
            cmd /c "icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F" | Out-Null
        } 
        Remove-AutoLogger

        Log "Setting Global User Settings" -Color Cyan
    
        Log "Setting Visual Style to best visual"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value "1"

        Log "Disabling Autoplay"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Value "1"

        Log "Disabling Auto Update And Download Of Windows Store Apps" 
        SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value "2"

        Log "Setting Explorer Default To This PC" 
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value "1"

        Log "Setting Explorer Default To Show File Extensions"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value "0"

        Log "Setting Windows to not track app launches"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value "0"

        Log "Setting Windows Powershell to default on Win X Menu"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DontUsePowerShellOnWinX" -Value "0"
        
        Log "Unchecking Show Recently Used Files In Quick Access" 
        SetReg -Path "HKCU:\Software\Microsoft\Windows\Currentversion\Explorer" -Name "ShowRecent" -Value "0"

        Log "Unchecking Show Frequently Used Folders In Quick Access" 
        SetReg -Path "HKCU:\Software\Microsoft\Windows\Currentversion\Explorer" -Name "ShowFrequent" -Value "0"

        Log "Disabling AeroShake"
        SetReg -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "NoWindowMinimizingShortcuts" -Value "1"

        Log "Hiding Cortana"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value "0"

        Log "Disabling Sticky keys prompt"
        SetReg -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -PropertyType "String"

        Log "Disabling TaskBar People Icon"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Value "0"

        Log "Disabling Taskview on Taskbar"
        SetReg -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value "0"

        # Log "Unpinning all items on taskbar - Irreversible!"
        # New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name "Favorites" -PropertyType Binary -Value ([byte[]](0xFF)) -Force
        # Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name "FavoritesResolve" -ErrorAction SilentlyContinue

        # Log "Enabling built-in Adobe Flash in IE and Edge..."
        # Remove-ItemProperty -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Addons" -Name "FlashPlayerEnabled" -ErrorAction SilentlyContinue
        # Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Ext\Settings\{D27CDB6E-AE6D-11CF-96B8-444553540000}" -Name "Flags" -ErrorAction SilentlyContinue

        Function Set-DesktopIcons
        {
            Log "Setting Desktop Icons: My PC, User Files, and Recycle Bin on Desktop / Remove OneDrive"
    
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
            Log "Removing User Folders From This PC"
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

        
        Log "Setting System Privacy Settings" -Color Cyan
    
        # Local Group Policy Settings - Can be adjusted in GPedit.msc in Pro+ editions. Local Policy/Computer Config/Admin Templates/Windows Components			
        Log "Removing App Telemetry Settings for..."			
        Log "Account Info"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessAccountInfo" -Value "2" 
        Log "Calendar"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessCalendar" -Value "2" 
        Log "Call History"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessCallHistory" -Value "2" 
        Log "Camera"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessCamera" -Value "2" 
        Log "Contacts"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessContacts" -Value "2" 
        Log "Email"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessEmail" -Value "2" 
        Log "Location"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessLocation" -Value "2" 
        Log "Messaging"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessMessaging" -Value "2" 
        Log "Microphone"		
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessMicrophone" -Value "2" 
        Log "Motion"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessMotion" -Value "2" 
        Log "Notifications"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessNotifications" -Value "2" 
        Log "Make Phone Calls"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessPhone" -Value "2" 
        Log "Radios"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessRadios" -Value "2" 
        Log "Access trusted devices"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessTrustedDevices" -Value "2" 
        Log "Sync with devices"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsSyncWithDevices" -Value "2"
        Log "Tasks"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessTasks" -Value "2"

        Log "Application Compatibility Settings..."
        Log "Turn off Application Telemetry"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Value "0" 			
        Log "Turn off inventory collector"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableInventory" -Value "1" 
        Log "Turn off steps recorder"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableUAR" -Value "1" 

        Log "Cloud Content Settings..."			
        Log "Do not show Windows Tips"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding" -Value "1" 
        Log "Turn off Consumer Experiences"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value "1" 
  
        Log "Data Collection Settings..."		
        Log "Set Telemetry to Basic"	
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value "0" 
        SetReg -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value "0"  
        Log "Disable pre-release features and settings"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Name "EnableConfigFlighting" -Value "0" 
        Log "Do not show feedback notifications"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value "1" 

        Log "Delivery Optimization Settings..."			
        # Disable DO; set to "1" to allow DO over LAN only			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value "0" 
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DownloadMode" -Value "0" 
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value "0" 
    
        Log "Location and Sensors"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value "1" 
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableSensors" -Value "1" 

        Log "Microsoft Edge - Always send do not track"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Name "DoNotTrack" -Value "1" 

        Log "Disabling Cortana..."			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value "0"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "BingSearchEnabled" -Value "0" 
        Log "Disallow Cortana on lock screen"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock" -Value "0" 
        Log "Disallow web search from desktop search"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value "1"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCloudSearch" -Value "0"
        Log "Don't search the web or display web results in search"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value "0" 

        Log "Windows Store..."			
        Log "Turn off Automatic download/install of app updates"		
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value "2" 		
        # Disable all apps from store, left disabled by default			
        # SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "DisableStoreApps" -Value "1" 
        # Turn off Store, left disabled by default
        # SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "RemoveWindowsStore" -Value "1" 

        Log "Sync Settings..."			
        Log "Do not syncanything"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSync" -Value "2" 
        Log "Disallow users to override this"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSyncUserOverride" -Value "1" 

        Log "Windows Update Settings..."			
        Log "Turn off featured software notifications through WU (basically ads)"			
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "EnableFeaturedSoftware" -Value "0" 

        Log "Disabling Wifi Sense" 
        SetReg -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Value "0"
        SetReg -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Value "0"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Value "0"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "WiFISenseAllowed" -Value "0"

        Log "Disabling Location Tracking" 
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Value "0"
        SetReg -Path "HKLM:\System\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value "0"

        Log "Disabling Map tracking" 
        SetReg -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Value "0"

        Log "Disable Error Reporting"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value "1"

        Log "Disabling advertising info and device metadata collection for this machine"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value "0" 
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Value "1" 
    
        Log "Prevent apps on other devices from opening apps on this PC"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SmartGlass" -Name "UserAuthPolicy " -Value "0" 
    
        Log "Prevent using sign-in info to automatically finish setting up after an update"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "ARSOUserConsent" -Value "2"   
    
        Log "Disable Malicious Software Removal Tool through WU, and CEIP"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\MRT" -Name "DontOfferThroughWUAU" -Value "1" 
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value "0"

        Log "Setting System Settings" -Color Cyan

        Log "Setting Execution Policy Back To Correct Settings"
        Set-Executionpolicy Remotesigned -Force | Out-Null
		
        Log "Disabling The Built-In Admin Account"
        Cmd /c "Net User Administrator /Active:No"
         
        Log "Setting Power Settings To Never Sleep" 
        cmd /c "powercfg -change -monitor-timeout-ac 0"
        cmd /c "powercfg -change -monitor-timeout-dc 0"
        cmd /c "powercfg -change -standby-timeout-ac 0"
        cmd /c "powercfg -change -standby-timeout-dc 0"
        cmd /c "powercfg -change -disk-timeout-ac 0"
        cmd /c "powercfg -change -disk-timeout-dc 0"
        cmd /c "powercfg -change -hibernate-timeout-ac 0"
        cmd /c "powercfg -change -hibernate-timeout-dc 0"

        Log "Disabling display and sleep mode timeouts..."
        cmd /c "powercfg /X monitor-timeout-ac 0"
        cmd /c "powercfg /X monitor-timeout-dc 0"
        cmd /c "powercfg /X standby-timeout-ac 0"
        cmd /c "powercfg /X standby-timeout-dc 0"

        Log "Disabling Sleep start menu and keyboard button..."
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowSleepOption" -Value "0"
        cmd /c "powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0"
        cmd /c "powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0"

        Log "Disabling Hibernation"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Value "0"

        Log "Enable F8 boot menu options"
        cmd /c "bcdedit /set `{current`} bootmenupolicy Legacy" | Out-Null
 
        Log "Setting time zone to Central Standard"    
        $TimeZone = 'Central Standard Time'
        If ( (Get-TimeZone).StandardName -eq $TimeZone)
        {
            Log "The time zone is already set to $TimeZone."
        }
        Else
        {
            Set-TimeZone -Name $TimeZone
            Log "The time zone set to $TimeZone."
        }

        Log "Setting current network profile to private"
        Set-NetConnectionProfile -NetworkCategory Private

        Log "Configuring To Allow Pings, RDP, WMI, and File and Printer Sharing Through Firewall" 
        Import-Module NetSecurity

        Log "Setting RDP to allow inbound connections"    
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

        Log "Setting Ping firewall rule (in/out)"
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
        Log "Setting Remote Desktop firewall rule"
        Set-NetFirewallRule -DisplayGroup "Remote Desktop" -Profile Any -Enabled True | Out-Null    
        Log "Setting Windows Management Instrumentation (WMI) firewall rule"
        Set-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)" -Profile Any -Enabled True | Out-Null
        Log "Setting Network Discovery firewall rule"
        Set-NetFirewallRule -DisplayGroup "Network Discovery" -Profile Any -Enabled True | Out-Null
        Log "Setting File and Printer Sharing firewall rule"
        Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Profile Any -Enabled True | Out-Null
        Log "Setting Windows Remote Management firewall rule"
        Set-NetFirewallRule -DisplayGroup "Windows Remote Management" -Profile Any -Enabled True | Out-Null
        Log "Setting Core Networking firewall rule"
        Set-NetFirewallRule -DisplayGroup "Core Networking" -Profile Any -Enabled True | Out-Null

        Log "Setting UAC Setting To Third Bar Down (Notify When Apps Make Changes… Don't Dim)" 
        SetReg -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value "0"
        SetReg -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableInstallerDetection" -Value "0"
        SetReg -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value "0"
        SetReg -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "FilterAdministratorToken" -Value "0"
    
        Log "Removing memory dumping, event logging, and automatic restarts on operating system crashes"
        # SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "LogEvent" -Value "0"
        SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value "0"
        # SetReg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value "0"
    
        Log "Allowing Lock Screen"
        SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value "0"
        SetReg -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoChangingLockScreen" -Value "0"
            
        Log "Disabling Windows Update automatic restart"
        SetReg -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name "NoAutoRebootWithLoggedOnUsers" -Value "1"
        SetReg -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Value "1"
    
        Log "Disabling search for app in store for unknown extensions"
        SetReg -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoUseStoreOpenWith" -Value "1"
    
        Log "Disabling Autorun for all drives"
        SetReg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value "255"
    
        Log "Enabling Remote Desktop With Network Level Authentication" 
        SetReg -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value "0"
        SetReg -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value "0"
    
        Log "Disabling Remote Assistance" 
        SetReg -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value "0"

        Function EnableNumlock
        {
            Log "Enabling NumLock after startup..."
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
            Log "Setting a default start menu for all users"
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
            Log "Setting up Windows Photo Viewer"
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

            
        Log "Stopping and Disabling Diagnostics Tracking Service, WAP Push Service, Home Groups service, Xbox Services, and Other Unncessary Services" 
        $Services = @()
        $Services += "Diagtrack"
        $Services += "Homegroupprovider"
        $Services += "Xblauthmanager"
        $Services += "Xblgamesave"
        $Services += "Xboxnetapisvc"
        $Services += "Trkwks"
        $Services += "Wmpnetworksvc"
        $Services += "dmwappushservice"
        Foreach ($Service In $Services) 
        {
            Log "Stopping Service $Service and setting startup to disabled"
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
            Log "Disabing $Task"
            Disable-ScheduledTask -TaskName $Task | Out-Null
        }

        Function Get-ScheduledTasksStatus
        {

            $Tasks = @()
            $Tasks += "Microsoft Compatibility Appraiser"
            $Tasks += "ProgramDataUpdater"
            $Tasks += "Proxy"
            $Tasks += "Consolidator"
            $Tasks += "UsbCeip"
            $Tasks += "Microsoft-Windows-DiskDiagnosticDataCollector"
            $Tasks += "GatherNetworkInfo"  
            $Tasks += "QueueReporting"
            $Tasks += "DmClient"
            $Tasks += "DmClientOnScenarioDownload" 
            ForEach ($Task in $Tasks)
            {
                Get-ScheduledTask -TaskName $Task
            }
        }
        # Get-ScheduledTasksStatus
            
        Log "Disabling Xbox features..."
        Get-AppxPackage "Microsoft.XboxApp" | Remove-AppxPackage
        Get-AppxPackage "Microsoft.XboxIdentityProvider" | Remove-AppxPackage
        Get-AppxPackage "Microsoft.XboxSpeechToTextOverlay" | Remove-AppxPackage
        Get-AppxPackage "Microsoft.XboxGameOverlay" | Remove-AppxPackage
        Get-AppxPackage "Microsoft.Xbox.TCUI" | Remove-AppxPackage
        New-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -PropertyType DWord -Value 0 -Force
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"))
        {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" | Out-Null
        }
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -PropertyType DWord -Value 0 -Force
            
        Log "Removing Unwanted Default Apps" 
        $Packages = $a = Get-Appxpackage -Allusers | Where-Object { $_.Name -Notlike "*Store*" } |
            Where-Object { $_.Name -Notlike "*.NET*" } |
            Where-Object { $_.Name -Notlike "*Paint*" } |
            Where-Object { $_.Name -Notlike "*Print*" } |
            Where-Object { $_.Name -Notlike "*Edge*" } |
            Where-Object { $_.Name -Notlike "*Calculator*" } |
            Sort-Object -Property { $_.Name.Length }
            
        ForEach ($Package in $Packages)
        {
            Log "Uninstalling: $($Package.Name)"
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
            Log "Uninstalling: $($PPackage.PackageName)"
            Remove-Appxprovisionedpackage -PackageName $($PPackage.PackageName) -Online -Erroraction Silentlycontinue | Out-Null
        }
         
    }

    End
    {
        Log "Enabling System Restore and creating a checkpoint" -Color Yellow
        Enable-ComputerRestore -Drive $env:systemdrive -Verbose
        Checkpoint-Computer -Description "Default Config" -RestorePointType "MODIFY_SETTINGS" -Verbose
        Stop-Log
        Log "Configuration Complete. Press any key to reboot the computer"
        cmd /c "Pause"
        Restart-Computer  
    }

}

<#######</Body>#######>
<#######</Script>#######>