<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-PasswordForm
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: http://www.theagreeablecow.com/2014/08/password-and-phrase-generator-using.html
<#######</Header>#######>
<#######<Body>#######>

Function Invoke-PasswordForm
{
    <#
    .Synopsis
    Creates random passwords of varying complexity from ASCII table of characters or phrases from random words selected from on posts on Reddit.
    .Description
    Creates random passwords of varying complexity from ASCII table of characters or phrases from random words selected from on posts on Reddit.
    .Example
    Invoke-PasswordForm
    Creates random passwords of varying complexity from ASCII table of characters or phrases from random words selected from on posts on Reddit.
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

           
    }
    
    Process
    {   
        #Set Proxy Server Settings (If Required)
        Function Setwebproxy()
        {
            If (Test-Connection Proxy1.Mydomain.Com -Count 1 -Quiet)
            {
                $Global:Psdefaultparametervalues = @{
                    'Invoke-Restmethod:Proxy'      = 'http://proxy1.mydomain.com:8080'
                    'Invoke-Webrequest:Proxy'      = 'http://proxy1.mydomain.com:8080'
                    '*:Proxyusedefaultcredentials' = $True
                }
            }
        }

        #Show A Message Box
        Function Show-Messagebox
        { 
            Param([Parameter(Position = 1, Mandatory = $True)][String]$Message,  
                [String]$Title = "",  
                [Validateset('Ok', 'Okcancel', 'Abortretryignore', 'Yesnocancel', 'Yesno', 'Retrycancel')][String]$Type = 'Ok',  
                [Validateset('None', 'Stop', 'Question', 'Warning', 'Information')][String]$Icon = 'None') 
            Add-Type -Assemblyname System.Windows.Forms 
            [System.Windows.Forms.Messagebox]::Show($Message, $Title, $Type, $Icon) 
        }

        #Generate Password Or Phrase
        Function Generatepassword
        {
            [String]$Password = ""
            $Txtresults.Text = "<Generating Phrase...>"
    
            #Generate Passwords
            If ($Rdchar.Checked -Eq $True)
            {
    
                #Define Default Variables
                [Bool] $Includelower = $False
                [Bool] $Includeupper = $False
                [Bool] $Includenumbers = $False
                [Bool] $Includespecial = $False
    
                #Update Complexity Based On Form
                $Length = $Numericupdown1.Value
                If ($Cblower.Checked -Eq $True)
                {
                    $Includelower = $True
                }
                If ($Cbupper.Checked -Eq $True)
                {
                    $Includeupper = $True
                }
                If ($Cbnumbers.Checked -Eq $True)
                {
                    $Includenumbers = $True
                }
                If ($Cbspecial.Checked -Eq $True)
                {
                    $Includespecial = $True
                }
    
                #Load Ascii Characters
                $Lowercase = [Char[]](97..122)
                $Upercase = [Char[]](65..90)
                $Numbers = [Char[]](48..57)
                $Special = [Char[]](33..47) + [Char[]](58..64) + [Char[]](91..96) + [Char[]](123..126)


                #Build Password Set
                If ($Includelower -Eq $True)
                {
                    $Passwordset += $Lowercase
                }
                If ($Includeupper -Eq $True)
                {
                    $Passwordset += $Upercase
                }
                If ($Includenumbers -Eq $True)
                {
                    $Passwordset += $Numbers
                }
                If ($Includespecial -Eq $True)
                {
                    $Passwordset += $Special
                }


                #Generate Random Password
                $Randomobj = New-Object System.Random
                1..$Length | ForEach-Object {$Password += ($Passwordset | Get-Random)}
            }
            #Generate Phrases
            Elseif ($Rdword.Checked -Eq $True)
            {
                #Define Default Variables
                $Words = @()
                $Uncommonwords = @()
                $Length = $Numericupdown2.Value
                $Subreddit = $Txtsource.Text
                $Scriptpath = Split-Path -Parent $Pscommandpath


                #Launch Web Request To Collect 25x Post Titles From Reddit
                Try
                {
                    Setwebproxy   #  <-- Run This Function To Connect Via A Proxy Server
                    $Uri = "https://www.reddit.com/$Subreddit"
    
                    #If Subreddit Is 'Random', Select The Redirected .Json Page
                    If ($Uri -Eq "https://www.reddit.com/r/random")
                    {
                        $Request = Invoke-Webrequest -Uri $Uri -Maximumredirection 0 -Erroraction Ignore
                        If ($Request.Statusdescription -Eq 'Found')
                        {
                            $Uri = $Request.Headers.Location
                        }
                        $Uri = $Uri.Substring(0, $Uri.Length - 1)
                        $Redirect = $Uri + ".Json"
                        Write-Host "Word Source: $Uri"
                        $Uri = Invoke-Webrequest -Uri $Redirect
                    }
                    #Otherwise, Just Select The Original .Json Page
                    Else
                    {
                        $Original = $Uri + ".Json"
                        Write-Host "Word Source: $Uri"
                        $Uri = Invoke-Webrequest -Uri $Original
                    }
                    $Obj = Convertfrom-Json ($Uri.Content)
                    $Data = $Obj.Data.Children.Data | Select-Object Title
                }
                Catch
                {
                    $Txtresults.Text = "Failed Connection Or Unknown Url. Please Try Again"
                    Break;
                }
    
                #Break Down Titles Into Words
                $Titles = $Data.Title 
                $Words = $Titles.Split(' ')
    
                #Filter Out Common Redit Text, Special Characters And Numbers
                $Reddittext = @("r/", "u/")
                $Punctuation = @('"', "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "=", `
                        "+", "[", "]", "{", "}", "\", "|", ";", ":", "'", ",", "<", ".", ">", "/", "?")
                $Numbers = @("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
                $Characters = $Reddittext + $Punctuation + $Numbers
                Foreach ($Character In $Characters)
                {
                    $Words = $Words.Replace($Character, "")
                }
    
                #Filter Out Small Words And Duplicates
                $Words = $Words | Where-Object {$_.Length -Ge 4}
                $Words = $Words | Select-Object -Uniq
    
                #Filter Out Common Words
                $Excludedwordfile = "$Scriptpath\Excludedcommonwords.Txt"
                If ((Test-Path $Excludedwordfile))
                {
                    $Excludedwords = Get-Content $Excludedwordfile
                    Foreach ($Word In $Words)
                    {
                        If ($Excludedwords -Notcontains $Word)
                        {
                            $Uncommonwords += $Word
                        }
                    }
                    #Check For A Decent Sized Word Pool And Create Phrase Out Of Uncommon Words Only
                    $Count = $Uncommonwords.Count
                    If ($Count -Lt 50)
                    {
                        Write-Warning "The Generated Word List Was Not Very Large ($Count), Which May Result In Limited Word Selection. Suggest You Try Another Subreddit."
                    }
                    1..$Length | ForEach-Object {$Password += ($Uncommonwords | Get-Random)}
                }
                Else
                {
                    #Warn About Excludedwordlist File Missing, Check For A Decent Sized Word Pool And Create Phrase Out Of All Available Words
                    Write-Warning "The Generated Phrase May Contain Very Common Words. Please Add The 'Excluded Common Words' File $Excludedwordfile And Try Again."
                    $Count = $Words.Count
                    If ($Count -Lt 50)
                    {
                        Write-Warning "The Generated Word List Was Not Very Large ($Count), Which May Result In Limited Word Selection. Suggest You Try Another Subreddit."
                    }
                    1..$Length | Foreach-Object {$Password += ($Words | Get-Random)}
                }
    
                #Remove All Remaining Non A-Z Or A-Z Characters And Test Length Of Final Phrase
                $Password = [System.Text.Regularexpressions.Regex]::Replace($Password, "[^A-Za-Z]", "");
                If ($Password.Length -Lt 16)
                {
                    Write-Warning "Phrase Is Not Very Long. Suggest You Try Again."
                }
            }
    
            #Copy To Clipboard
            If ($Cbclipboard.Checked -Eq $True)
            {
                $Password | Clip
            }
 
            #Update Text Display On Form
            If ($Cbmask.Checked -Eq $True)
            {
                1..$Length | Foreach-Object {$Stars += "*"}
                $Txtresults.Text = $Stars
            }
            Else
            {
                $Txtresults.Text = $Password
            }
    
            #Export To Text File
            If ($Cbfile.Checked -Eq $True)
            {
                If ($Cbfile.Text -Eq "Export To File")
                {
                    If ($Savefiledialog1.Showdialog() -Eq 'Ok')
                    {
                        $Password | Out-File $Savefiledialog1.Filename
                    }
                }
                Else
                {
                    $Password | Out-File $Savefiledialog1.Filename -Append
                }
                $Cbfile.Text = "Appending..."
            }
        }

        #------------------------
        #  Form     #
        #------------------------

        Function Generateform
        {

            #Region Import The Assemblies
            [Reflection.Assembly]::Loadwithpartialname("System.Drawing") | Out-Null
            [Reflection.Assembly]::Loadwithpartialname("System.Windows.Forms") | Out-Null

            #Region Generated Form Objects
            $Form1 = New-Object System.Windows.Forms.Form
            $Label1 = New-Object System.Windows.Forms.Label
            $Groupbox2 = New-Object System.Windows.Forms.Groupbox
            $Cbfile = New-Object System.Windows.Forms.Checkbox
            $Cbmask = New-Object System.Windows.Forms.Checkbox
            $Cbclipboard = New-Object System.Windows.Forms.Checkbox
            $Groupbox1 = New-Object System.Windows.Forms.Groupbox
            $Btnhelp = New-Object System.Windows.Forms.Button
            $Txtsource = New-Object System.Windows.Forms.Textbox
            $Label2 = New-Object System.Windows.Forms.Label
            $Numericupdown2 = New-Object System.Windows.Forms.Numericupdown
            $Rdword = New-Object System.Windows.Forms.Radiobutton
            $Rdchar = New-Object System.Windows.Forms.Radiobutton
            $Numericupdown1 = New-Object System.Windows.Forms.Numericupdown
            $Cblower = New-Object System.Windows.Forms.Checkbox
            $Cbupper = New-Object System.Windows.Forms.Checkbox
            $Cbnumbers = New-Object System.Windows.Forms.Checkbox
            $Cbspecial = New-Object System.Windows.Forms.Checkbox
            $Txtresults = New-Object System.Windows.Forms.Textbox
            $Btncancel = New-Object System.Windows.Forms.Button
            $Btngenerate = New-Object System.Windows.Forms.Button
            $Savefiledialog1 = New-Object System.Windows.Forms.Savefiledialog
            $Initialformwindowstate = New-Object System.Windows.Forms.Formwindowstate

            #Event Script Blocks
            $Handler_Btngenerate_Click = {
                Generatepassword
            }

            $Handler_Btncancel_Click = {
                $Form1.Close()
            }

            $Onloadform_Statecorrection = {
                $Form1.Windowstate = $Initialformwindowstate
                [Int]$Runcount = 0
                Generatepassword
            }

            $Btnhelp_Onclick = {  
                Show-Messagebox 'An Effective Word Array Is Dynamic And Random. These Words Are Randomly Sourced In Real Time, From Titles Of Posts On https://www.reddit.com' `
                    -Type Ok -Icon Information
            }

            #----------------------------------------------
            #Region Generated Form Code
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 346
            $System_Drawing_Size.Width = 605
            $Form1.Clientsize = $System_Drawing_Size
            $Form1.Databindings.Defaultdatasourceupdatemode = 0
            $Form1.Name = "Form1"
            $Form1.Startposition = 1
            $Form1.Text = "Password Generator"

            #Logo Label
            $Label1.Databindings.Defaultdatasourceupdatemode = 0
            $Label1.Font = New-Object System.Drawing.Font("Courier New", 6.75, 1, 3, 0)
            $Label1.Forecolor = [System.Drawing.Color]::Fromargb(255, 0, 0, 0)


            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 470
            $System_Drawing_Point.Y = 200
            $Label1.Location = $System_Drawing_Point
            $Label1.Name = "Label1"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 80
            $System_Drawing_Size.Width = 110
            $Label1.Size = $System_Drawing_Size
            $Label1.Tabindex = 13
            <#
$Label1.Text = "
     (__)
     (Oo)  Ok
   /------\/  /
  / |    ||
 *  /\---/\ 
    ^^   ^^   V1.3"
#>
            $Form1.Controls.Add($Label1)

            #Options Group Box
            $Groupbox2.Databindings.Defaultdatasourceupdatemode = 0
            $Groupbox2.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9.75, 0, 3, 1)
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 12
            $System_Drawing_Point.Y = 207
            $Groupbox2.Location = $System_Drawing_Point
            $Groupbox2.Name = "Groupbox2"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 60
            $System_Drawing_Size.Width = 407
            $Groupbox2.Size = $System_Drawing_Size
            $Groupbox2.Tabindex = 12
            $Groupbox2.Tabstop = $False
            $Groupbox2.Text = "Options"

            $Form1.Controls.Add($Groupbox2)

            # Export To File Checkbox 
            $Cbfile.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 281
            $System_Drawing_Point.Y = 22
            $Cbfile.Location = $System_Drawing_Point
            $Cbfile.Name = "Cbfile"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 24
            $System_Drawing_Size.Width = 104
            $Cbfile.Size = $System_Drawing_Size
            $Cbfile.Tabindex = 2
            $Cbfile.Text = "Export To File"
            $Cbfile.Usevisualstylebackcolor = $True

            $Groupbox2.Controls.Add($Cbfile)

            # Mask Checkbox
            $Cbmask.Databindings.Defaultdatasourceupdatemode = 0
            $Cbmask.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9.75, 0, 3, 1)
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 199
            $System_Drawing_Point.Y = 22
            $Cbmask.Location = $System_Drawing_Point
            $Cbmask.Name = "Cbmask"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 24
            $System_Drawing_Size.Width = 104
            $Cbmask.Size = $System_Drawing_Size
            $Cbmask.Tabindex = 1
            $Cbmask.Text = "Mask"
            $Cbmask.Usevisualstylebackcolor = $True

            $Groupbox2.Controls.Add($Cbmask)

            # Copy To Clipboard Checkbox
            $Cbclipboard.Checked = $True
            $Cbclipboard.Checkstate = 1
            $Cbclipboard.Databindings.Defaultdatasourceupdatemode = 0
            $Cbclipboard.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9.75, 0, 3, 1)
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 40
            $System_Drawing_Point.Y = 22
            $Cbclipboard.Location = $System_Drawing_Point
            $Cbclipboard.Name = "Cbclipboard"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 24
            $System_Drawing_Size.Width = 137
            $Cbclipboard.Size = $System_Drawing_Size
            $Cbclipboard.Tabindex = 0
            $Cbclipboard.Text = "Copy To Clipboard"
            $Cbclipboard.Usevisualstylebackcolor = $True

            $Groupbox2.Controls.Add($Cbclipboard)

            #Random Group Box
            $Groupbox1.Databindings.Defaultdatasourceupdatemode = 0
            $Groupbox1.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9.75, 0, 3, 1)
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 12
            $System_Drawing_Point.Y = 55
            $Groupbox1.Location = $System_Drawing_Point
            $Groupbox1.Name = "Groupbox1"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 129
            $System_Drawing_Size.Width = 582
            $Groupbox1.Size = $System_Drawing_Size
            $Groupbox1.Tabindex = 11
            $Groupbox1.Tabstop = $False
            $Groupbox1.Text = "Random"

            $Form1.Controls.Add($Groupbox1)

            # Help Button
            $Btnhelp.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 545
            $System_Drawing_Point.Y = 83
            $Btnhelp.Location = $System_Drawing_Point
            $Btnhelp.Name = "Btnhelp"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 23
            $System_Drawing_Size.Width = 20
            $Btnhelp.Size = $System_Drawing_Size
            $Btnhelp.Tabindex = 13
            $Btnhelp.Text = "?"
            $Btnhelp.Usevisualstylebackcolor = $True
            $Btnhelp.Add_Click($Btnhelp_Onclick)

            $Groupbox1.Controls.Add($Btnhelp)

            #Url Source Text Box
            $Txtsource.Backcolor = [System.Drawing.Color]::Fromargb(255, 255, 255, 255)
            $Txtsource.Databindings.Defaultdatasourceupdatemode = 0
            $Txtsource.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9.75, 0, 3, 0)
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 402
            $System_Drawing_Point.Y = 83
            $Txtsource.Location = $System_Drawing_Point
            $Txtsource.Name = "Txtsource"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 22
            $System_Drawing_Size.Width = 131
            $Txtsource.Size = $System_Drawing_Size
            $Txtsource.Tabindex = 12
            $Txtsource.Text = "R/Random"

            $Groupbox1.Controls.Add($Txtsource)

            #Words Label
            $Label2.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 215
            $System_Drawing_Point.Y = 83
            $Label2.Location = $System_Drawing_Point
            $Label2.Name = "Label2"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 23
            $System_Drawing_Size.Width = 192
            $Label2.Size = $System_Drawing_Size
            $Label2.Tabindex = 11
            $Label2.Text = "Source: https://www.reddit.com/"
            $Label2.Textalign = 16
            $Label2.Add_Click($Handler_Label2_Click)

            $Groupbox1.Controls.Add($Label2)

            #Words Numeric Up/Down
            $Numericupdown2.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 140
            $System_Drawing_Point.Y = 83
            $Numericupdown2.Location = $System_Drawing_Point
            $Numericupdown2.Maximum = 30
            $Numericupdown2.Minimum = 3
            $Numericupdown2.Name = "Numericupdown2"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 22
            $System_Drawing_Size.Width = 47
            $Numericupdown2.Size = $System_Drawing_Size
            $Numericupdown2.Tabindex = 10
            $Numericupdown2.Textalign = 2
            $Numericupdown2.Value = 4

            $Groupbox1.Controls.Add($Numericupdown2)

            # Words Radio Button
            $Rdword.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 20
            $System_Drawing_Point.Y = 82
            $Rdword.Location = $System_Drawing_Point
            $Rdword.Name = "Rdword"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 24
            $System_Drawing_Size.Width = 104
            $Rdword.Size = $System_Drawing_Size
            $Rdword.Tabindex = 9
            $Rdword.Tabstop = $True
            $Rdword.Text = "Words"
            $Rdword.Usevisualstylebackcolor = $True

            $Groupbox1.Controls.Add($Rdword)

            #Characters Radio Button
            $Rdchar.Checked = $True
            $Rdchar.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 20
            $System_Drawing_Point.Y = 30
            $Rdchar.Location = $System_Drawing_Point
            $Rdchar.Name = "Rdchar"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 24
            $System_Drawing_Size.Width = 104
            $Rdchar.Size = $System_Drawing_Size
            $Rdchar.Tabindex = 8
            $Rdchar.Tabstop = $True
            $Rdchar.Text = "Characters"
            $Rdchar.Usevisualstylebackcolor = $True

            $Groupbox1.Controls.Add($Rdchar)

            #Characters Numeric Up/Down
            $Numericupdown1.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 140
            $System_Drawing_Point.Y = 31
            $Numericupdown1.Location = $System_Drawing_Point
            $Numericupdown1.Maximum = 127
            $Numericupdown1.Minimum = 6
            $Numericupdown1.Name = "Numericupdown1"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 22
            $System_Drawing_Size.Width = 47
            $Numericupdown1.Size = $System_Drawing_Size
            $Numericupdown1.Tabindex = 5
            $Numericupdown1.Textalign = 2
            $Numericupdown1.Value = 12

            $Groupbox1.Controls.Add($Numericupdown1)

            #Lowercase Letters Checkbox
            $Cblower.Checked = $True
            $Cblower.Checkstate = 1
            $Cblower.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 235
            $System_Drawing_Point.Y = 30
            $Cblower.Location = $System_Drawing_Point
            $Cblower.Name = "Cblower"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 24
            $System_Drawing_Size.Width = 52
            $Cblower.Size = $System_Drawing_Size
            $Cblower.Tabindex = 3
            $Cblower.Text = "Abc"
            $Cblower.Usevisualstylebackcolor = $True

            $Groupbox1.Controls.Add($Cblower)

            #Uppercase Letters Checkbox
            $Cbupper.Checked = $True
            $Cbupper.Checkstate = 1
            $Cbupper.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 328
            $System_Drawing_Point.Y = 30
            $Cbupper.Location = $System_Drawing_Point
            $Cbupper.Name = "Cbupper"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 24
            $System_Drawing_Size.Width = 57
            $Cbupper.Size = $System_Drawing_Size
            $Cbupper.Tabindex = 4
            $Cbupper.Text = "Abc"
            $Cbupper.Usevisualstylebackcolor = $True

            $Groupbox1.Controls.Add($Cbupper)

            #Numbers Checkbox
            $Cbnumbers.Checked = $True
            $Cbnumbers.Checkstate = 1
            $Cbnumbers.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 422
            $System_Drawing_Point.Y = 30
            $Cbnumbers.Location = $System_Drawing_Point
            $Cbnumbers.Name = "Cbnumbers"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 24
            $System_Drawing_Size.Width = 52
            $Cbnumbers.Size = $System_Drawing_Size
            $Cbnumbers.Tabindex = 6
            $Cbnumbers.Text = "123"
            $Cbnumbers.Usevisualstylebackcolor = $True

            $Groupbox1.Controls.Add($Cbnumbers)

            #Special Characters Checkbox
            $Cbspecial.Checked = $True
            $Cbspecial.Checkstate = 1
            $Cbspecial.Databindings.Defaultdatasourceupdatemode = 0
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 516
            $System_Drawing_Point.Y = 30
            $Cbspecial.Location = $System_Drawing_Point
            $Cbspecial.Name = "Cbspecial"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 24
            $System_Drawing_Size.Width = 60
            $Cbspecial.Size = $System_Drawing_Size
            $Cbspecial.Tabindex = 7
            $Cbspecial.Text = "%$#"
            $Cbspecial.Usevisualstylebackcolor = $True

            $Groupbox1.Controls.Add($Cbspecial)

            #Results Text Box
            $Txtresults.Databindings.Defaultdatasourceupdatemode = 0
            $Txtresults.Font = New-Object System.Drawing.Font("Courier New", 12, 0, 3, 1)
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 11
            $System_Drawing_Point.Y = 17
            $Txtresults.Location = $System_Drawing_Point
            $Txtresults.Name = "Txtresults"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 26
            $System_Drawing_Size.Width = 583
            $Txtresults.Size = $System_Drawing_Size
            $Txtresults.Tabindex = 2
            $Txtresults.Textalign = 2
            $Txtresults.Add_Textchanged($Handler_Txtresults_Textchanged)

            $Form1.Controls.Add($Txtresults)

            #Close Button
            $Btncancel.Databindings.Defaultdatasourceupdatemode = 0
            $Btncancel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 12.25, 0, 3, 0)
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 358
            $System_Drawing_Point.Y = 291
            $Btncancel.Location = $System_Drawing_Point
            $Btncancel.Name = "Btncancel"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 45
            $System_Drawing_Size.Width = 110
            $Btncancel.Size = $System_Drawing_Size
            $Btncancel.Tabindex = 1
            $Btncancel.Text = "Close"
            $Btncancel.Usevisualstylebackcolor = $True
            $Btncancel.Add_Click($Handler_Btncancel_Click)

            $Form1.Controls.Add($Btncancel)

            #Generate Buton
            $Btngenerate.Databindings.Defaultdatasourceupdatemode = 0
            $Btngenerate.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 12.25, 0, 3, 0)
            $System_Drawing_Point = New-Object System.Drawing.Point
            $System_Drawing_Point.X = 138
            $System_Drawing_Point.Y = 291
            $Btngenerate.Location = $System_Drawing_Point
            $Btngenerate.Name = "Btngenerate"
            $System_Drawing_Size = New-Object System.Drawing.Size
            $System_Drawing_Size.Height = 45
            $System_Drawing_Size.Width = 115
            $Btngenerate.Size = $System_Drawing_Size
            $Btngenerate.Tabindex = 0
            $Btngenerate.Text = "Generate"
            $Btngenerate.Usevisualstylebackcolor = $True
            $Btngenerate.Add_Click($Handler_Btngenerate_Click)

            $Form1.Controls.Add($Btngenerate)

            #Save Export File Dialog
            $Savefiledialog1.Createprompt = $True
            $Savefiledialog1.Filename = "Generated Pw List.Txt"
            $Savefiledialog1.Initialdirectory = "C:"
            $Savefiledialog1.Showhelp = $True
            $Savefiledialog1.Title = "Save To File"

            #Save The Initial State Of The Form
            $Initialformwindowstate = $Form1.Windowstate
            #Init The Onload Event To Correct The Initial State Of The Form
            $Form1.Add_Load($Onloadform_Statecorrection)
            #Show The Form
            $Form1.Showdialog()| Out-Null
        }

        #Call The Form
        Generateform
    
    }

    End
    {
        Stop-Log
    }

}

<#######</Body>#######>
<#######</Script>#######>