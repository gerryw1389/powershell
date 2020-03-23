<#######<Script>#######>
<#######<Header>#######>
# Name: Set-PSProfile
# Copyright: Gerry Williams (https://automationadmin.com)
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
        ####################<Default Begin Block>####################
        # Force verbose because Write-Output doesn't look well in transcript files
        $VerbosePreference = "Continue"
        
        [String]$Logfile = $PSScriptRoot + '\PSLogs\' + (Get-Date -Format "yyyy-MM-dd") +
        "-" + $MyInvocation.MyCommand.Name + ".log"
        
        Function Write-Log
        {
            <#
            .Synopsis
            This writes objects to the logfile and to the screen with optional coloring.
            .Parameter InputObject
            This can be text or an object. The function will convert it to a string and verbose it out.
            Since the main function forces verbose output, everything passed here will be displayed on the screen and to the logfile.
            .Parameter Color
            Optional coloring of the input object.
            .Example
            Write-Log "hello" -Color "yellow"
            Will write the string "VERBOSE: YYYY-MM-DD HH: Hello" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Example
            Write-Log (cmd /c "ipconfig /all")
            Will write the string "VERBOSE: YYYY-MM-DD HH: ****ipconfig output***" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Notes
            2018-06-24: Initial script
            #>
            
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                # I usually set this to = "Green" since I use a black and green theme console
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color = "Green"
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

        Function Start-Log
        {
            <#
            .Synopsis
            Creates the log file and starts transcribing the session.
            .Notes
            2018-06-24: Initial script
            #>
            
            # Create transcript file if it doesn't exist
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
            Start-Transcript -Path $Logfile -Append 
            Write-Log "####################<Function>####################"
            Write-Log "Function started on $env:COMPUTERNAME"

        }
        
        Function Stop-Log
        {
            <#
            .Synopsis
            Stops transcribing the session and cleans the transcript file by removing the fluff.
            .Notes
            2018-06-24: Initial script
            #>
            
            Write-Log "Function completed on $env:COMPUTERNAME"
            Write-Log "####################</Function>####################"
            Stop-Transcript
       
            # Now we will clean up the transcript file as it contains filler info that needs to be removed...
            $Transcript = Get-Content $Logfile -raw

            # Create a tempfile
            $TempFile = $PSScriptRoot + "\PSLogs\temp.txt"
            New-Item -Path $TempFile -ItemType File | Out-Null
			
            # Get all the matches for PS Headers and dump to a file
            $Transcript | 
                Select-String '(?smi)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*([\S\s]*?)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*' -AllMatches | 
                ForEach-Object {$_.Matches} | 
                ForEach-Object {$_.Value} | 
                Out-File -FilePath $TempFile -Append

            # Compare the two and put the differences in a third file
            $m1 = Get-Content -Path $Logfile
            $m2 = Get-Content -Path $TempFile
            $all = Compare-Object -ReferenceObject $m1 -DifferenceObject $m2 | Where-Object -Property Sideindicator -eq '<='
            $Array = [System.Collections.Generic.List[PSObject]]@()
            foreach ($a in $all)
            {
                [void]$Array.Add($($a.InputObject))
            }
            $Array = $Array -replace 'VERBOSE: ', ''

            Remove-Item -Path $Logfile -Force
            Remove-Item -Path $TempFile -Force
            # Finally, put the information we care about in the original file and discard the rest.
            $Array | Out-File $Logfile -Append -Encoding ASCII
            
        }
        
        Start-Log

        Function Set-Console
        {
            <# 
        .Synopsis
        Function to set console colors just for the session.
        .Description
        Function to set console colors just for the session.
        This function sets background to black and foreground to green.
        Verbose is DarkCyan which is what I use often with logging in scripts.
        I mainly did this because darkgreen does not look too good on blue (Powershell defaults).
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
        
            Function Test-IsAdmin
            {
                <#
                .Synopsis
                Determines whether or not the user is a member of the local Administrators security group.
                .Outputs
                System.Bool
                #>

                [CmdletBinding()]
    
                $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $Principal = new-object System.Security.Principal.WindowsPrincipal(${Identity})
                $IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
                Write-Output -InputObject $IsAdmin
            }

            $console = $host.UI.RawUI
            If (Test-IsAdmin)
            {
                $console.WindowTitle = "Administrator: Powershell"
            }
            Else
            {
                $console.WindowTitle = "Powershell"
            }
            $Background = "Black"
            $Foreground = "Green"
            $Messages = "DarkCyan"
            $Host.UI.RawUI.BackgroundColor = $Background
            $Host.UI.RawUI.ForegroundColor = $Foreground
            $Host.PrivateData.ErrorForegroundColor = $Messages
            $Host.PrivateData.ErrorBackgroundColor = $Background
            $Host.PrivateData.WarningForegroundColor = $Messages
            $Host.PrivateData.WarningBackgroundColor = $Background
            $Host.PrivateData.DebugForegroundColor = $Messages
            $Host.PrivateData.DebugBackgroundColor = $Background
            $Host.PrivateData.VerboseForegroundColor = $Messages
            $Host.PrivateData.VerboseBackgroundColor = $Background
            $Host.PrivateData.ProgressForegroundColor = $Messages
            $Host.PrivateData.ProgressBackgroundColor = $Background
            Clear-Host
        }
        Set-Console

        ####################</Default Begin Block>####################

        
        # Load the required module(s) 
        Try
        {
            Import-Module "$Psscriptroot\..\Private\helpers.psm1" -ErrorAction Stop
        }
        Catch
        {
            Write-Log "Module 'Helpers' was not found, stopping script"
            Exit 1
        }

        Function Set-ProfileRegSettings
        {
            Write-Log "Setting console related registry settings"

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
        Write-Log "Downloading default profile from Github"
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
            Write-Log "Profile $F has been set"
        }
    }
    
    End
    {
        Stop-log
    }

}

<#######</Body>#######>
<#######</Script>#######>