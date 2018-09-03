<#######<Script>#######>
<#######<Header>#######>
# Name: Set-PSProfile
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-PSProfile
{
    <#
    .Synopsis
    This function creates my PS profile.
    .Description
    This function creates my PS profile. It does the following:
    Downloads my Github PSProfile and sets it for each of my PS Profiles. This includes setting the title, font, and color settings.
    It sets registry settings to make the cursor an underscore.
    It verifies that I have required modules prior.
    .Example
    Set-PSProfile
    This function creates my PS profile.
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

        Function Set-ProfileRegSettings
        {
            Write-Output "Setting console related registry settings"

            SetReg -Path "HKCU:\Console" -Name "CtrlKeyShortcutsDisabled" -Value "0x00000000"
            SetReg -Path "HKCU:\Console" -Name "CursorSize" -Value "0x00000019"
            SetReg -Path "HKCU:\Console" -Name "EnableColorSelection" -Value "0x00000000"
            SetReg -Path "HKCU:\Console" -Name "ExtendedEditKey" -Value "0x00000001"
            SetReg -Path "HKCU:\Console" -Name "ExtendedEditKeyCustom" -Value "0x00000000"
            SetReg -Path "HKCU:\Console" -Name "FilterOnPaste" -Value "0x00000001"
            SetReg -Path "HKCU:\Console" -Name "ForceV2" -Value "0x00000001"
            SetReg -Path "HKCU:\Console" -Name "FullScreen" -Value "0x00000000"
            SetReg -Path "HKCU:\Console" -Name "HistoryBufferSize" -Value "0x00000032"
            SetReg -Path "HKCU:\Console" -Name "HistoryNoDup" -Value "0x00000000"
            SetReg -Path "HKCU:\Console" -Name "InsertMode" -Value "0x00000001"
            SetReg -Path "HKCU:\Console" -Name "LineSelection" -Value "0x00000001"
            SetReg -Path "HKCU:\Console" -Name "LineWrap" -Value "0x00000001"
            SetReg -Path "HKCU:\Console" -Name "LoadConIme" -Value "0x00000001"
            SetReg -Path "HKCU:\Console" -Name "NumberOfHistoryBuffers" -Value "0x00000004"
            SetReg -Path "HKCU:\Console" -Name "QuickEdit" -Value "0x00000001"
            SetReg -Path "HKCU:\Console" -Name "ScreenBufferSize" -Value "0x23290078"
            SetReg -Path "HKCU:\Console" -Name "ScrollScale" -Value "0x00000001"
            SetReg -Path "HKCU:\Console" -Name "TrimLeadingZeros" -Value "0x00000000"
            SetReg -Path "HKCU:\Console" -Name "WindowAlpha" -Value "0x000000ff"
            SetReg -Path "HKCU:\Console" -Name "WindowSize" -Value "0x001e0078"
            SetReg -Path "HKCU:\Console" -Name "WordDelimiters" -Value "0x00000000"
            SetReg -Path "HKCU:\Console" -Name "FaceName" -PropertyType "String" -Value "Consolas"
            SetReg -Path "HKCU:\Console" -Name "FontFamily" -Value "0x00000036"
            SetReg -Path "HKCU:\Console" -Name "FontSize" -Value "0x00140000"
            SetReg -Path "HKCU:\Console" -Name "FontWeight" -Value "0x00000190"
            SetReg -Path "HKCU:\Console" -Name "PopupColors" -Value "0x0000000a"
            SetReg -Path "HKCU:\Console" -Name "ScreenColors" -Value "0x0000000a"
            SetReg -Path "HKCU:\Console" -Name "ColorTable00" -Value "0x00000000"
            SetReg -Path "HKCU:\Console" -Name "ColorTable01" -Value "0x00800000"
            SetReg -Path "HKCU:\Console" -Name "ColorTable02" -Value "0x00008000"
            SetReg -Path "HKCU:\Console" -Name "ColorTable03" -Value "0x00808000"
            SetReg -Path "HKCU:\Console" -Name "ColorTable04" -Value "0x00000080"
            SetReg -Path "HKCU:\Console" -Name "ColorTable05" -Value "0x00800080"
            SetReg -Path "HKCU:\Console" -Name "ColorTable06" -Value "0x00008080"
            SetReg -Path "HKCU:\Console" -Name "ColorTable07" -Value "0x00c0c0c0"
            SetReg -Path "HKCU:\Console" -Name "ColorTable08" -Value "0x00808080"
            SetReg -Path "HKCU:\Console" -Name "ColorTable09" -Value "0x00ff0000"
            SetReg -Path "HKCU:\Console" -Name "ColorTable10" -Value "0x0000ff00"
            SetReg -Path "HKCU:\Console" -Name "ColorTable11" -Value "0x00ffff00"
            SetReg -Path "HKCU:\Console" -Name "ColorTable12" -Value "0x000000ff"
            SetReg -Path "HKCU:\Console" -Name "ColorTable13" -Value "0x00ff00ff"
            SetReg -Path "HKCU:\Console" -Name "ColorTable14" -Value "0x0000ffff"
            SetReg -Path "HKCU:\Console" -Name "ColorTable15" -Value "0x00ffffff"
            SetReg -Path "HKCU:\Console" -Name "CurrentPage" -Value "0x00000003"

            SetReg -Path "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe" -Name "ColorTable05" -Value "0x00562401"
            SetReg -Path "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe" -Name "ColorTable06" -Value "0x00f0edee"
            SetReg -Path "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe" -Name "ScreenBufferSize" -Value "0x0bb80078"
            SetReg -Path "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe"-Name "WindowSize" -Value "0x00320078"
            SetReg -Path "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe" -Name "FaceName" -PropertyType "String" -Value "Consolas"
            SetReg -Path "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe" -Name "FontSize" -Value "0x00140009"

            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name "ColorTable05" -Value "0x00562401"
            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name "ColorTable06" -Value "0x00f0edee"
            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name  "FaceName" -PropertyType "String" -Value "Consolas"
            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name "FontFamily" -Value "0x00000036"
            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name "FontWeight" -Value "0x00000190"
            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name "PopupColors" -Value "0x000000f3"
            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name "QuickEdit" -Value "0x00000001"
            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name "ScreenBufferSize" -Value "0x0bb80078"
            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name "ScreenColors" -Value "0x00000056"
            SetReg -Path "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe" -Name "WindowSize" -Value "0x00320078"

            SetReg -Path "HKCU:\Software\Microsoft\Command Processor" -Name "CompletionChar" -Value "0x00000009"
            SetReg -Path "HKCU:\Software\Microsoft\Command Processor" -Name "DefaultColor" -Value "0x00000000"
            SetReg -Path "HKCU:\Software\Microsoft\Command Processor" -Name "EnableExtensions" -Value "0x00000001"
            SetReg -Path "HKCU:\Software\Microsoft\Command Processor" -Name "PathCompletionChar" -Value "0x00000009"

            SetReg -Path "HKLM:\Software\Microsoft\Command Processor" -Name "CompletionChar" -Value "0x00000040"
            SetReg -Path "HKLM:\Software\Microsoft\Command Processor" -Name "DefaultColor" -Value "0x00000000"
            SetReg -Path "HKLM:\Software\Microsoft\Command Processor" -Name "EnableExtensions" -Value "0x00000001"
            SetReg -Path "HKLM:\Software\Microsoft\Command Processor" -Name "PathCompletionChar" -Value "0x00000040"
        }
        
        # Moved to the begin block so it only downloads once
        Write-Output "Downloading default profile from Github"
        $URI = "https://raw.githubusercontent.com/gerryw1389/master/master/Other/psprofile.ps1"
        $Response = Invoke-RestMethod -Method Get -Uri $URI
        $Output = [string]::Join("`r`n", ($response))
    }
    
    Process
    {    
        $Files = @("$env:USERPROFILE\Documents\WindowsPowershell\Microsoft.Powershell_profile.ps1",
            "$env:USERPROFILE\Documents\WindowsPowershell\Microsoft.PowershellISE_profile.ps1",
            "$env:USERPROFILE\Documents\WindowsPowershell\Microsoft.VSCode_profile.ps1")
    
        Set-ProfileRegSettings
        ForEach ($F in $Files)
        {
            Set-Content -Path $F -Value $Output
            Write-Output "Profile $F has been set"
        }
    }
    
    End
    {
    }

}

<#######</Body>#######>
<#######</Script>#######>