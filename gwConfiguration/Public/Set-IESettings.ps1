<#######<Script>#######>
<#######<Header>#######>
# Name: Set-IESettings
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-IESettings
{
    <#
    .Synopsis
    Resets IE and adds your site(s) to trusted site and pop up blocker.
    .Description
    Resets IE and adds your site(s) to trusted site and pop up blocker.
    Additionally, it opens trusted zones for those crappy enterprise portals that need "full allow" settings.
    .Parameter Logfile
    Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
    .Example
    Set-OutlookAutodiscover
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
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String[]]$TrustedSites,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-IESettings.log"
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
    }

    Process
    {
        Write-ToString "Configuring Internet Settings"

        # Reset IE to defaults, you don't have to click, just wait and it will for you.
        Write-ToString "Resetting to defaults"
        Add-Type -Assemblyname Microsoft.Visualbasic
        Add-Type -Assemblyname System.Windows.Forms
        rundll32.exe inetcpl.cpl ResetIEtoDefaults
        Start-Sleep -Milliseconds 500
        [Microsoft.Visualbasic.Interaction]::Appactivate("Reset Internet Explorer Settings")
        [System.Windows.Forms.Sendkeys]::Sendwait("%R")
        Start-Sleep -Seconds 2
        [System.Windows.Forms.Sendkeys]::Sendwait("%C")

        Write-ToString "Setting Homepage to Google"
        SetReg -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -Name "Start Page" -Value "https://google.com" -PropertyType "String"

        ForEach ($Site in $TrustedSites)
        {
            Write-ToString "Adding $Site To Trusted Sites"
            $Substring = $Site.Replace('http://', '').replace('https://', '').replace('www.', '')
            SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\$Substring" -Name "*" -Value "2"
            Write-ToString "Adding $Site to Pop Up Blocker list..."
            SetReg -Path "HKCU:\Software\Microsoft\Internet Explorer\New Windows\Allow" -Name "*.$Substring" -Value "00,00" -PropertyType "Binary"
        }

        # Basically full open the trusted sites zone.
        Write-ToString "Configuring zones"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1001" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1004" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1200" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1201" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1206" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1208" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1209" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "120A" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "120B" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1400" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1402" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1405" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1607" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1609" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1803" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1809" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "2000" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "2201" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "2702" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "270C" -Value "0"
    
        Write-ToString "Launching IE"
        Invoke-Item "C:\Program Files (x86)\Internet Explorer\iexplore.exe" 
 
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