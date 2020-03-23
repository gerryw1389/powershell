<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-CustomMenuGUI
# Copyright: Gerry Williams (https://automationadmin.com)
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
    .Example
    Invoke-CustomMenuGUI
    Creates a form that is used to launch pre-defined scripts from.
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

        $Form.ShowDialog() | Out-Null   
    }

    End
    {
        Stop-Log
    }

}

<#######</Body>#######>
<#######</Script>#######>