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
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

# Start-MarioThemeSong


<#######</Body>#######>
<#######</Script>#######>