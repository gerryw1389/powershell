<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-CustomMenuGUI
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Invoke-CustomMenuGUI
{
    <#
.Synopsis
Creates a form that is used to launch pre-defined scripts from.
.Description
Creates a form that is used to launch pre-defined scripts from.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Invoke-CustomMenuGUI
Creates a form that is used to launch pre-defined scripts from.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>    
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Invoke-CustomMenuGUI.Log"
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

        Function Initialize-Window
        {
            $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
            Add-Type -Name Win -Member $t -Namespace native
            [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)
        }
        Initialize-Window

        $StartPowershell = 
        { 
            Powershell.exe Start-Process Powershell -Verb runas 
        }

        $StartPowershellISE = 
        { 
            Powershell.exe Start-Process "Powershell_ise" -Verb runas 
        }

        $RunMyScript = 
        { 
            Start-Process Powershell -Argument "C:\_ill\google\_myprogs\ill\resources\invokepassword.ps1"
        }

        $EndForm = 
        { 
            Stop-Process -id $pid
        }
    }
    
    Process
    {   
        Add-Type -AssemblyName System.Windows.Forms
        $Form = New-Object system.Windows.Forms.Form 
        $Form.Text = "GerrysScripts"
        $Form.TopMost = $true
        $Form.BackColor = "#0b0b0b"
        $Form.Width = 256
        $Form.Height = 410

        $label = New-Object system.windows.Forms.Label 
        $label.Text = "Select A Task `r`nTo Run:"
        $label.AutoSize = $true
        $label.ForeColor = "#0CF110"
        $label.Width = 217
        $label.Height = 10
        $label.location = new-object system.drawing.point(5, 19)
        $label.Font = "Verdana,12"
        $Form.controls.Add($label) 

        $button = New-Object system.windows.Forms.Button 
        $button.Text = "StartPS"
        $button.ForeColor = "#0CF110"
        $button.Width = 159
        $button.Height = 23
        $button.location = new-object system.drawing.point(4, 70)
        $button.Font = "Verdana,10"
        $button.Add_Click($StartPowershell)
        $Form.controls.Add($button)
 
        $button2 = New-Object system.windows.Forms.Button 
        $button2.Text = "StartISE"
        $button2.ForeColor = "#0CF110"
        $button2.Width = 159
        $button2.Height = 23
        $button2.location = new-object system.drawing.point(4, 100)
        $button2.Font = "Verdana,10"
        $button2.Add_Click($StartPowershellISE)
        $Form.controls.Add($button2)

        $button3 = New-Object system.windows.Forms.Button 
        $button3.Text = "button"
        $button3.ForeColor = "#0CF110"
        $button3.Width = 159
        $button3.Height = 23
        $button3.location = new-object system.drawing.point(4, 130)
        $button3.Font = "Verdana,10"
        $button3.Add_Click($RunMyScript)
        $Form.controls.Add($button3) 

        $button4 = New-Object system.windows.Forms.Button 
        $button4.Text = "button"
        $button4.ForeColor = "#0CF110"
        $button4.Width = 159
        $button4.Height = 23
        $button4.location = new-object system.drawing.point(4, 160)
        $button4.Font = "Verdana,10"
        $button4.Add_Click($StartPowershellISE)
        $Form.controls.Add($button4)

        $button5 = New-Object system.windows.Forms.Button 
        $button5.Text = "button"
        $button5.ForeColor = "#0CF110"
        $button5.Width = 159
        $button5.Height = 23
        $button5.location = new-object system.drawing.point(4, 190)
        $button5.Font = "Verdana,10"
        $button5.Add_Click($StartPowershellISE)
        $Form.controls.Add($button5) 

        $button6 = New-Object system.windows.Forms.Button 
        $button6.Text = "button"
        $button6.ForeColor = "#0CF110"
        $button6.Width = 159
        $button6.Height = 23
        $button6.location = new-object system.drawing.point(4, 220)
        $button6.Font = "Verdana,10"
        $button6.Add_Click($StartPowershellISE)
        $Form.controls.Add($button6) 

        $button7 = New-Object system.windows.Forms.Button 
        $button7.Text = "button"
        $button7.ForeColor = "#0CF110"
        $button7.Width = 159
        $button7.Height = 23
        $button7.location = new-object system.drawing.point(4, 250)
        $button7.Font = "Verdana,10"
        $button7.Add_Click($StartPowershellISE)
        $Form.controls.Add($button7) 

        $button8 = New-Object system.windows.Forms.Button 
        $button8.Text = "button"
        $button8.ForeColor = "#0CF110"
        $button8.Width = 159
        $button8.Height = 23
        $button8.location = new-object system.drawing.point(4, 280)
        $button8.Font = "Verdana,10"
        $button8.Add_Click($StartPowershellISE)
        $Form.controls.Add($button8)

        $button9 = New-Object system.windows.Forms.Button 
        $button9.Text = "button"
        $button9.ForeColor = "#0CF110"
        $button9.Width = 159
        $button9.Height = 23
        $button9.location = new-object system.drawing.point(4, 310)
        $button9.Font = "Verdana,10"
        $button9.Add_Click($StartPowershellISE)
        $Form.controls.Add($button9)

        $button10 = New-Object system.windows.Forms.Button 
        $button10.Text = "Close Form"
        $button10.ForeColor = "#0CF110"
        $button10.Width = 159
        $button10.Height = 23
        $button10.location = new-object system.drawing.point(4, 340)
        $button10.Font = "Verdana,10"
        $button10.Add_Click($EndForm)
        $Form.controls.Add($button10) 

        $Form.ShowDialog() | out-null   
    }

    End
    {
        If ($EnabledLogging)
        {
            Stop-Log
        }
    }

}   

# Invoke-CustomMenuGUI

<#######</Body>#######>
<#######</Script>#######>