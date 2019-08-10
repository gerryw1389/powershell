<#######<Script>#######>
<#######<Header>#######>
# Name: Read-MultiLineInputBox
<#######</Header>#######>
<#######<Body>#######>
Function Read-MultiLineInputBox
{
    <#
.Synopsis
This function is here for proof of concept, it doesn't actually do anything. It shows how to use a multi-line input box to parse json and returns a json object.
.Description
This function is here for proof of concept, it doesn't actually do anything. It shows how to use a multi-line input box to parse json and returns a json object.
.Notes
Version history:
2018-11-01: version 1
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
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
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
        
        function Read-MultiLineInputBoxDialog
        (
            [string]$Message, 
            [string]$WindowTitle, 
            [string]$DefaultText
        )
        {
            Add-Type -AssemblyName System.Drawing
            Add-Type -AssemblyName System.Windows.Forms
    
            # Create the Label.
            $label = New-Object System.Windows.Forms.Label
            $label.Location = New-Object System.Drawing.Size(10, 10) 
            $label.Size = New-Object System.Drawing.Size(280, 20)
            $label.AutoSize = $true
            $label.Text = $Message
    
            # Create the TextBox used to capture the user's text.
            $textBox = New-Object System.Windows.Forms.TextBox 
            $textBox.Location = New-Object System.Drawing.Size(10, 40) 
            $textBox.Size = New-Object System.Drawing.Size(575, 200)
            $textBox.AcceptsReturn = $true
            $textBox.AcceptsTab = $false
            $textBox.Multiline = $true
            $textBox.ScrollBars = 'Both'
            $textBox.Text = $DefaultText
    
            # Create the OK button.
            $okButton = New-Object System.Windows.Forms.Button
            $okButton.Location = New-Object System.Drawing.Size(415, 250)
            $okButton.Size = New-Object System.Drawing.Size(75, 25)
            $okButton.Text = "OK"
            $okButton.Add_Click( { $form.Tag = $textBox.Text; $form.Close() })
    
            # Create the Cancel button.
            $cancelButton = New-Object System.Windows.Forms.Button
            $cancelButton.Location = New-Object System.Drawing.Size(510, 250)
            $cancelButton.Size = New-Object System.Drawing.Size(75, 25)
            $cancelButton.Text = "Cancel"
            $cancelButton.Add_Click( { $form.Tag = $null; $form.Close() })
    
            # Create the form.
            $form = New-Object System.Windows.Forms.Form 
            $form.Text = $WindowTitle
            $form.Size = New-Object System.Drawing.Size(610, 320)
            $form.FormBorderStyle = 'FixedSingle'
            $form.StartPosition = "CenterScreen"
            $form.AutoSizeMode = 'GrowAndShrink'
            $form.Topmost = $True
            $form.AcceptButton = $okButton
            $form.CancelButton = $cancelButton
            $form.ShowInTaskbar = $true
    
            # Add all of the controls to the form.
            $form.Controls.Add($label)
            $form.Controls.Add($textBox)
            $form.Controls.Add($okButton)
            $form.Controls.Add($cancelButton)
    
            # Initialize and show the form.
            $form.Add_Shown( {$form.Activate()})
            $form.ShowDialog() > $null   # Trash the text of the button that was clicked.
    
            # Return the text that the user entered.
            return $form.Tag
        }
    }
    
    Process
    {
        Try
        {
            <#
        $multiLineText = Read-MultiLineInputBoxDialog -Message "Please enter some text. It can be multiple lines" -WindowTitle "Please enter json from email" -DefaultText "Paste the text here, don't worry if it includes the open bracket..."

            $CleanMultilineText = $multiLineText.trim()

            if ( $CleanMultilineText.StartsWith('[') )
            {
                $CleanMultilineText = $CleanMultilineText.TrimStart('[')  
            }
            else
            {
                continue
            }

            # Convert json to object  
            $json = $CleanMultilineText | convertfrom-json
        #>
            
        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }
    End
    {
        Stop-Log
    }
}
<#######</Body>#######>
<#######</Script>#######>