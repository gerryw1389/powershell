<#######<Script>#######>
<#######<Header>#######>
# Name: Start-MarioThemeSong
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Start-MarioThemeSong
{
    <#
.Synopsis
Start-MarioThemeSong plays the Mario Theme Song.
.Description
Start-MarioThemeSong plays the Mario Theme Song.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Start-MarioThemeSong
Start-MarioThemeSong plays the Mario Theme Song.
.Example
"Pc2", "Pc1" | Start-MarioThemeSong
Start-MarioThemeSong plays the Mario Theme Song.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>    
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Start-MarioThemeSong.Log"
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

        Function Play-MarioIntro 
        {
            [console]::beep($E, $SIXTEENTH)
            [console]::beep($E, $EIGHTH)
            [console]::beep($E, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($C, $SIXTEENTH)
            [console]::beep($E, $EIGHTH)
            [console]::beep($G, $QUARTER)
        }

        Function Play-MarioIntro2
        {
            [console]::beep($C, $EIGHTHDOT)
            [console]::beep($GbelowC, $SIXTEENTH)
            Start-Sleep -m $EIGHTH
            [console]::beep($EbelowG, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($A, $EIGHTH)
            [console]::beep($B, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($Asharp, $SIXTEENTH)
            [console]::beep($A, $EIGHTH)
            [console]::beep($GbelowC, $SIXTEENTHDOT)
            [console]::beep($E, $SIXTEENTHDOT)
            [console]::beep($G, $EIGHTH)
            [console]::beep($AHigh, $EIGHTH)
            [console]::beep($F, $SIXTEENTH)
            [console]::beep($G, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($E, $EIGHTH)
            [console]::beep($C, $SIXTEENTH)
            [console]::beep($D, $SIXTEENTH)
            [console]::beep($B, $EIGHTHDOT)
            [console]::beep($C, $EIGHTHDOT)
            [console]::beep($GbelowC, $SIXTEENTH)
            Start-Sleep -m $EIGHTH
            [console]::beep($EbelowG, $EIGHTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($A, $EIGHTH)
            [console]::beep($B, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($Asharp, $SIXTEENTH)
            [console]::beep($A, $EIGHTH)
            [console]::beep($GbelowC, $SIXTEENTHDOT)
            [console]::beep($E, $SIXTEENTHDOT)
            [console]::beep($G, $EIGHTH)
            [console]::beep($AHigh, $EIGHTH)
            [console]::beep($F, $SIXTEENTH)
            [console]::beep($G, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($E, $EIGHTH)
            [console]::beep($C, $SIXTEENTH)
            [console]::beep($D, $SIXTEENTH)
            [console]::beep($B, $EIGHTHDOT)
            Start-Sleep -m $EIGHTH
            [console]::beep($G, $SIXTEENTH)
            [console]::beep($Fsharp, $SIXTEENTH)
            [console]::beep($F, $SIXTEENTH)
            [console]::beep($Dsharp, $EIGHTH)
            [console]::beep($E, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($GbelowCSharp, $SIXTEENTH)
            [console]::beep($A, $SIXTEENTH)
            [console]::beep($C, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($A, $SIXTEENTH)
            [console]::beep($C, $SIXTEENTH)
            [console]::beep($D, $SIXTEENTH)
            Start-Sleep -m $EIGHTH
            [console]::beep($G, $SIXTEENTH)
            [console]::beep($Fsharp, $SIXTEENTH)
            [console]::beep($F, $SIXTEENTH)
            [console]::beep($Dsharp, $EIGHTH)
            [console]::beep($E, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($CHigh, $EIGHTH)
            [console]::beep($CHigh, $SIXTEENTH)
            [console]::beep($CHigh, $QUARTER)
            [console]::beep($G, $SIXTEENTH)
            [console]::beep($Fsharp, $SIXTEENTH)
            [console]::beep($F, $SIXTEENTH)
            [console]::beep($Dsharp, $EIGHTH)
            [console]::beep($E, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($GbelowCSharp, $SIXTEENTH)
            [console]::beep($A, $SIXTEENTH)
            [console]::beep($C, $SIXTEENTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($A, $SIXTEENTH)
            [console]::beep($C, $SIXTEENTH)
            [console]::beep($D, $SIXTEENTH)
            Start-Sleep -m $EIGHTH
            [console]::beep($Dsharp, $EIGHTH)
            Start-Sleep -m $SIXTEENTH
            [console]::beep($D, $EIGHTH)
            [console]::beep($C, $QUARTER)
        }

    }
    
    Process
    {    
        #Set Speed and Tones
        If ($CHigh -eq $null)
        {
            $WHOLE = 2200
            $HALF = $WHOLE / 2
            $QUARTER = $HALF / 2
            $EIGHTH = $QUARTER / 2
            $SIXTEENTH = $EIGHTH / 2
            $EIGHTHDOT = $EIGHTH + $SIXTEENTH
            $QUARTERDOT = $QUARTER + $EIGHTH
            $SIXTEENTHDOT = $SIXTEENTH + ($SIXTEENTH / 2)

            $REST = 37
            $EbelowG = 164
            $GbelowC = 196
            $GbelowCSharp = 207
            $A = 220
            $Asharp = 233
            $B = 247
            $C = 262
            $Csharp = 277
            $D = 294
            $Dsharp = 311
            $E = 330
            $F = 349
            $Fsharp = 370
            $G = 392
            $Gsharp = 415
            $AHigh = 440
            $CHigh = 523
        }

        Play-MarioIntro
        Play-MarioIntro2

    }

    End
    {
        If ($EnabledLogging)
        {
            Stop-Log
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>