<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-CustomMenu
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
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
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Invoke-CustomMenu
Invokes a menu driven application that can run pre-defined Powershell commands and scripts.
.Example
"Pc2", "Pc1" | Invoke-CustomMenu
Invokes a menu driven application that can run pre-defined Powershell commands and scripts.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>


    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Invoke-CustomMenu.Log"
    )

    Begin
    {
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
            $strArray | % {
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
                $menu_item = New-Object -TypeName PSObject | Select Name, Command
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
            $menu = New-Object -TypeName PSObject | Select Name, MenuItems
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
                $menu_item = New-Object -TypeName PSObject | Select Number, Name, Command
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
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        If ($($Logfile.Length) -gt 1)
        {
            $EnabledLogging = $True
        }
        Else
        {
            $EnabledLogging = $False
        }
    
        Filter Timestamp
        {
            "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $_"
        }

        If ($EnabledLogging)
        {
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
            $Sizemax = 10
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            $Sizemb = "{0:N2}" -F ($Size.Sum / 1mb) + "Mb"
            If ($Sizemb -Ge $Sizemax)
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            # Start writing to logfile
            Start-Transcript -Path $Logfile -Append 
            Write-Output "####################<Script>####################"
            Write-Output "Script Started on $env:COMPUTERNAME" | TimeStamp
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
        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }
 
}

<#######</Body>#######>
<#######</Script>#######>