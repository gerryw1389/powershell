<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-CustomMenu
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: Brian Clark - AKA Kewlb - AKA The IT Jedi - brian@clarkhouse.org / brian@itjedi.org
<#######</Header>#######>
<#######<Body>#######>
Function Invoke-CustomMenu
{
    <#
    .Synopsis
    Invokes a menu driven application that can run pre-defined Powershell commands and scripts.
    .Description
    Invokes a menu driven application that can run pre-defined Powershell commands and scripts.
    .Example
    Invoke-CustomMenu
    Invokes a menu driven application that can run pre-defined Powershell commands and scripts.
    .Example
    Invoke-CustomMenu
    Invokes a menu driven application that can run pre-defined Powershell commands and scripts.
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

        Function Write-Color
        {
            <#
            .SYNOPSIS
            Enables support to write multiple color text on a single line
            .DESCRIPTION
            Users color codes to enable support to write multiple color text on a single line
            ################################################
            # Write-Color Color Codes
            ################################################
            # ^cn = Normal Output Color
            # ^ck = Black
            # ^cb = Blue
            # ^cc = Cyan
            # ^ce = Gray
            # ^cg = Green
            # ^cm = Magenta
            # ^cr = Red
            # ^cw = White
            # ^cy = Yellow
            # ^cB = DarkBlue
            # ^cC = DarkCyan
            # ^cE = DarkGray
            # ^cG = DarkGreen
            # ^cM = DarkMagenta
            # ^cR = DarkRed
            # ^cY = DarkYellow
            ################################################
            .PARAMETER text
            Mandatory. Line of text to write
            .INPUTS
            [string]$text
            .OUTPUTS
            None
            .NOTES
            Version:    1.0
            Author:     Brian Clark
            Creation Date:  01/21/2017
            Purpose/Change: Initial function development
            Version:    1.1
            Author:     Brian Clark
            Creation Date:  01/23/2017
            Purpose/Change: Fix Gray / Code Format Fixes
            .EXAMPLE
            Write-Color "Hey look ^crThis is red ^cgAnd this is green!"
            #>

            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)][string]$text
            )

            ### If $text contains no color codes just write-host as normal
            if (-not $text.Contains("^c"))
            {
                Write-Host "$($text)"
                return
            }


            ### Set to true if the beginning of $text is a color code. The reason for this is that
            ### the generated array will have an empty/null value for the first element in the array
            ### if this is the case.
            ### Since we also assume that the first character of a split string is a color code we
            ### also need to know if it is, in fact, a color code or if it is a legitimate character.
            $blnStartsWithColor = $false
            if ($text.StartsWith("^c"))
            {
                $blnStartsWithColor = $true
            }

            ### Split the array based on our color code delimeter
            $strArray = $text -split "\^c"
            ### Loop Counter so we can generate a new empty line on the last element of the loop
            $count = 1

            ### Loop through the array
            $strArray | ForEach-Object {
                if ($count -eq 1 -and $blnStartsWithColor -eq $false)
                {
                    Write-Host $_ -NoNewline
                    $count++
                }
                elseif ($_.Length -eq 0)
                {
                    $count++
                }
                else
                {

                    $char = $_.Substring(0, 1)
                    $color = ""
                    switch -CaseSensitive ($char)
                    {
                        "b"
                        {
                            $color = "Blue" 
                        }
                        "B"
                        {
                            $color = "DarkBlue" 
                        }
                        "c"
                        {
                            $color = "Cyan" 
                        }
                        "C"
                        {
                            $color = "DarkCyan" 
                        }
                        "e"
                        {
                            $color = "Gray" 
                        }
                        "E"
                        {
                            $color = "DarkGray" 
                        }
                        "g"
                        {
                            $color = "Green" 
                        }
                        "G"
                        {
                            $color = "DarkGreen" 
                        }
                        "k"
                        {
                            $color = "Black" 
                        }
                        "m"
                        {
                            $color = "Magenta" 
                        }
                        "M"
                        {
                            $color = "DarkMagenta" 
                        }
                        "r"
                        {
                            $color = "Red" 
                        }
                        "R"
                        {
                            $color = "DarkRed" 
                        }
                        "w"
                        {
                            $color = "White" 
                        }
                        "y"
                        {
                            $color = "Yellow" 
                        }
                        "Y"
                        {
                            $color = "DarkYellow" 
                        }
                    }

                    ### If $color is empty write a Normal line without ForgroundColor Option
                    ### else write our colored line without a new line.
                    if ($color -eq "")
                    {
                        Write-Host $_.Substring(1) -NoNewline
                    }
                    else
                    {
                        Write-Host $_.Substring(1) -NoNewline -ForegroundColor $color
                    }
                    ### Last element in the array writes a blank line.
                    if ($count -eq $strArray.Count)
                    {
                        Write-Host ""
                    }
                    $count++
                }
            }
        }

        Function New-MenuItem
        {
            <#
            .SYNOPSIS
            Creates a Menu Item used with New-Menu
            .DESCRIPTION
            Use this in conjunction with New-Menu and Show-Menu
            to generate a menu system for your scripts
            .PARAMETER Name
            Mandatory. Text that shows up in the menu for this menu item.
            .PARAMETER Command
            Mandatory. Command the menu item executes when selected
            Important Note: Define your command in single quotes '' and not double quotes ""
            .INPUTS
            [string]$Name
            [string]$Command
            .OUTPUTS
            [PSObject] Name, Command
            .NOTES
            Version:    1.0
            Author:     Brian Clark
            Creation Date:  03/23/2017
            Purpose/Change: Initial function development
            .EXAMPLE
            $item = New-MenuItem -Name "List All Services" -Command 'Get-Service'
            $item_end = New-MenuItem -Name "Exit Menu" -Command 'End-Menu'
            $item_switch_menu = New-MenuItem -Name "View Menu 2" -Command 'Show-Menu $menu2'
            #>
            [CmdletBinding()]
            Param ([Parameter(Mandatory = $true)][string]$Name,
                [Parameter(Mandatory = $true)]$Command)

            ### The first whole word should be the cmdlet.
            $cmd_array = $Command.Split(" ")
            $cmd = $cmd_array[0]

            ### Ensure cmdlet/function is defined if so create and return the menu item
            if ($cmd -eq "End-Menu" -or (Get-Command $cmd -ErrorAction SilentlyContinue))
            {
                $menu_item = New-Object -TypeName PSObject | Select-Object Name, Command
                $menu_item.Name = $Name
                $menu_item.Command = $Command
                return $menu_item
            }
            else
            {
                Write-Error -Message "The command $($Command) does not exist!" -Category ObjectNotFound
                return $null
            }
        }

        Function New-Menu
        {
            <#
            .SYNOPSIS
            Creates a looping menu system
            .DESCRIPTION
            Use this in conjunction with New-MenuItem and Show-Menu
            to generate a menu system for your scripts
            .PARAMETER Name
            Mandatory. Text that shows up as the menu title in the menu screen
            .PARAMETER MenuItems[]
            Mandatory. Array of Menu Items created via the New-MenuItem cmdlet
            .INPUTS
            [string]$Name
            [PSObject]$MenuItems[]
            .OUTPUTS
            [PSObject] Name, MenuItems[]
            .NOTES
            Version:    1.0
            Author:     Brian Clark
            Creation Date:  03/23/2017
            Purpose/Change: Initial function development
            .EXAMPLE
            $main_menu = New-Menu -Name 'Main Menu' -MenuItems @(
                (New-MenuItem -Name 'Get Services' -Command 'Get-Service'),
                (New-MenuItem -Name 'Get ChildItems' -Command 'Get-ChildItem'),
                (New-MenuItem -Name 'GoTo Sub Menu' -Command 'Show-Menu -Menu $sub_menu'),
                (New-MenuItem -Name 'Exit' -Command "End-Menu")
            )
            #>
            [CmdletBinding()]
            Param ([Parameter(Mandatory = $true)][string]$Name,
                [Parameter(Mandatory = $true)][PSObject[]]$MenuItems)

            ### Create Menu PSObject
            $menu = New-Object -TypeName PSObject | Select-Object Name, MenuItems
            $menu.Name = $Name
            $menu.MenuItems = @()

            ### Loop through each MenuItem and verify they have the correct Properties
            ### and verify that there is a way to exit the menu or open a different menu
            $blnFoundMenuExit = $false
            $blnMenuExitsToMenu = $false
            for ($i = 0; $i -lt $MenuItems.Length; $i++)
            {
                if ((-not $MenuItems[$i].PSObject.Properties['Name']) -or 
                    (-not $MenuItems[$i].PSObject.Properties['Command']))
                {
                    Write-Error "One or more passed Menu Items were not created with New-MenuItem!" -Category InvalidType
                    return
                }
                if ($MenuItems[$i].Command -eq "End-Menu")
                {
                    $blnFoundMenuExit = $true 
                }
                if ($MenuItems[$i].Command.Contains("Show-Menu"))
                {
                    $blnMenuExitsToMenu = $true 
                }
                $menu_item = New-Object -TypeName PSObject | Select-Object Number, Name, Command
                $menu_item.Number = $i
                $menu_item.Name = $MenuItems[$i].Name
                $menu_item.Command = $MenuItems[$i].Command
                $menu.MenuItems += @($menu_item)
            }
            if ($blnFoundMenuExit -eq $false -and $blnMenuExitsToMenu -eq $false)
            {
                Write-Error "This menu does not contain an End-Menu or Show-Menu MenuItem and would loop forever!" -Category SyntaxError
                return
            }
            return $menu

        }

        Function Show-Menu
        {
            <#
            .SYNOPSIS
            Starts the menu display/selection loop for a menu created with New-Menu
            .DESCRIPTION
            Use this in conjunction with New-Menu and New-MenuItem
            to generate a menu system for your scripts
            .PARAMETER Menu
            Mandatory. A menu created with the New-Menu cmdlet
            .INPUTS
            [PSObject]$Menu
            .OUTPUTS
            Starts the Menu Display Loop
            This function returns nothing
            .NOTES
            Version:    1.0
            Author:     Brian Clark
            Creation Date:  03/23/2017
            Purpose/Change: Initial function development
            .EXAMPLE
            Show-Menu $MyMenu
            #>
            [CmdletBinding()]
            Param ([Parameter(Mandatory = $true)][PSObject]$Menu)

            ### Verify $Menu has the right properties
            if ((-not $Menu.PSObject.Properties['Name']) -or 
                (-not $Menu.PSObject.Properties['MenuItems']))
            {
                Write-Error -Message "The passed object is not a Menu created with New-Menu!" -Category InvalidType
                return
            }

            ### Display the Menu via a Do Loop
            $blnMenuExit = $false
            $choice = -1
            Do
            {
                Write-Host "`r`n===================================================================================================="
                Write-Host "$($Menu.Name)" -ForegroundColor DarkYellow
                Write-Host "----------------------------------------------------------------------------------------------------"
                for ($i = 0; $i -lt $Menu.MenuItems.Length; $i++)
                {
                    Write-Color " ^cg$($i)^cn) ^cy$($Menu.MenuItems[$i].Name)^cn"
                }
                Write-Host "`r`n====================================================================================================`r`n"
                Write-Host "Please select an item (0-$($Menu.MenuItems.Length-1)) : " -ForegroundColor DarkYellow -NoNewline
                $choice = Read-Host
                $choice = ($choice -as [int])
                if ($choice.GetType() -ne [int])
                {
                    Write-Host "`r`nError - Invalid choice!`r`n" -ForegroundColor Red
                }
                elseif ($choice -lt 0 -or $choice -ge $Menu.MenuItems.Length)
                {
                    Write-Host "`r`nError - choice must be between 0 and $($Menu.MenuItems.Length-1)!`r`n" -ForegroundColor Red
                }
                else
                {
                    if ($Menu.MenuItems[$choice].Command -eq "End-Menu" -or 
                        $Menu.MenuItems[$choice].Command.Contains("Show-Menu"))
                    {
                        $blnMenuExit = $true
                    }
                    else
                    {
                        Invoke-Expression -Command $Menu.MenuItems[$choice].Command
                    }
                }
            } Until ($blnMenuExit -eq $true)

            if ($Menu.MenuItems[$choice].Command.Contains("Show-Menu"))
            {
                Invoke-Expression -Command $Menu.MenuItems[$choice].Command
            }
        }

    }
    
    
    Process
    {   
        # MENU SAMPLE
    
        Function Start-PowershellISE 
        { 
            Powershell.exe Start-Process "Powershell_ise" -Verb runas 
        }

        ### Setup Window for best fit of menu
        $Host.UI.RawUI.BackgroundColor = "Black"
        $HOST.UI.RawUI.ForegroundColor = "White"
        $Host.UI.RawUI.WindowTitle = "Scripts"
        $pshost = Get-Host
        $pswindow = $pshost.ui.rawui
        $newsize = $pswindow.buffersize
        $newsize.height = 3000
        $newsize.width = 100
        $pswindow.buffersize = $newsize
        $newsize = $pswindow.windowsize
        $newsize.height = 50
        $newsize.width = 100
        $pswindow.windowsize = $newsize
        [System.Console]::Clear();

        $main_menu = New-Menu -Name 'Main Menu' -MenuItems @(
            (New-MenuItem -Name 'LaunchPS' -Command 'Invoke-Item "c:\scripts\ps.bat"'),
            (New-MenuItem -Name 'LaunchPSISE' -Command 'Start-PowershellISE'),
            (New-MenuItem -Name 'GoTo Sub Menu' -Command 'Show-Menu -Menu $sub_menu'),
            (New-MenuItem -Name 'Exit' -Command "End-Menu")
        )
        $sub_menu = New-Menu -Name 'Sub Menu' -MenuItems @(
            (New-MenuItem -Name 'Directory' -Command 'Dir'),
            (New-MenuItem -Name 'Hostname' -Command 'Hostname'),
            (New-MenuItem -Name 'GoTo Main Menu' -Command 'Show-Menu -Menu $main_menu'),
            (New-MenuItem -Name 'Exit' -Command "End-Menu")
        )

        Show-Menu -Menu $main_menu	
    
    }

    End
    {
       Stop-Log
    }
 
}

<#######</Body>#######>
<#######</Script>#######>