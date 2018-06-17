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
    It verifies that I have required modules prior
    .Parameter Logfile
    Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
    NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
    .Example
    Set-PSProfile
    This function creates my PS profile.
    .Example
    "Pc1" | Set-PSProfile
    This function creates my PS profile.
    .Notes
    Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
    Main code usually starts around line 185ish.
    If -Verbose is not passed (Default) and logfile is not defined, don't show messages on the screen and don't transcript the session.
    If -Verbose is not passed (Default) and logfile is defined, enable verbose for them and transcript the session.
    If -Verbose is passed and logfile is defined, show messages on the screen and transcript the session.
    If -Verbose is passed and logfile is not defined, show messages on the screen, but don't transcript the session.
    2018-06-17: v1.1 Updated template.
    2017-09-08: v1.0 Initial script 
    #>   
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-PSProfile.Log"
    )

    Begin
    {
        <#######<Default Begin Block>#######>
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
                [String]$Color
            )
            
            $ConvertToString = Out-String -InputObject $InputObject -Width 100
            
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
        If ($($Logfile.Length) -gt 1)
        {
            $Global:EnabledLogging = $True 
            Set-Variable -Name Logfile -Value $Logfile -Scope Global
            $VerbosePreference = "Continue"
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
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
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
                    Write-ToString "Logfile has been cleared due to size"
                }
                Else
                {
                    Write-ToString "Logfile was less than 10 MB"   
                }
                # Start writing to logfile
                Start-Transcript -Path $Logfile -Append 
                Write-ToString "####################<Script>####################"
                Write-ToString "Script Started on $env:COMPUTERNAME"
            }
            Start-Log -Logfile $Logfile -Verbose

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
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
                Write-ToString "Script Completed on $env:COMPUTERNAME"
                Write-ToString "####################</Script>####################"
                Stop-Transcript
            }
        }
        Else
        {
            $Global:EnabledLogging = $False
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

        Function Set-ProfileRegSettings
        {
            Write-ToString "Setting console related registry settings"

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
        Write-ToString "Downloading default profile from Github"
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
            Write-ToString "Profile $F has been set"
        }
    }
    End
    {
        If ($Global:EnabledLogging)
        {
            Stop-Log -Logfile $Logfile
        }
        Else
        {
            $Date = $(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt")
            Write-Output "Function completed at $Date"
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>