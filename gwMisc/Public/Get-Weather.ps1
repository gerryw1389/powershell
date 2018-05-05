<#######<Script>#######>
<#######<Header>#######>
# Name: Get-Weather
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Get-Weather
{
    <#
.Synopsis
Gets the weather according to wttr.in using Invoke-RestMethod.
.Description
Gets the weather according to wttr.in using Invoke-RestMethod.
.Parameter City
Specifies a city.
.Parameter JustToday
Specifies to get just today's weather.
.Parameter TwoDays
Specifies to get two days worth of weather.
.Parameter ByZip
Specifies to get the weather by zip code.
.Parameter Moon
Specifies the phase of the moon for today.
.Parameter MoonOnDate
Specifies the phase of the moon on a given date. Must be in a format like 2017-11-01.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Get-Weather
Gets three day weather forcast.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding(DefaultParametersetName = 'Default')]
    Param
    (
        [String]$City,
		
        [Switch]$JustToday,
		
        [Switch]$TwoDays,
		
        [ValidateLength(5, 5)]
        [String]$ByZip,
		
        [Switch]$Moon,
		
        [ValidateLength(10, 10)]
        [String]$MoonOnDate,
			
        [String]$Logfile = "$PSScriptRoot\..\Logs\Get-Weather.log"
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
    }
    
    Process
    {   
        If ($City)
        {
            Write-Output "Getting weather for $City" | Timestamp
            (curl http://wttr.in/$City -UserAgent "curl" ).Content
            # Cannot substitue "curl" for "Invoke-WebRequest -URI" ....
        }
        ElseIf ($JustToday)
        {
            Write-Output "Getting weather for today's current location" | Timestamp
            (curl http://wttr.in/?0 -UserAgent "curl" ).Content
        }
        ElseIf ($TwoDays)
        {
            Write-Output "Getting two days weather forcast for current location" | Timestamp
            (curl http://wttr.in/?2 -UserAgent "curl" ).Content
        }
        ElseIf ($ByZip)
        {
            Write-Output "Getting weather for zipcode $ByZip" | Timestamp
            (curl http://wttr.in/$ByZip -UserAgent "curl" ).Content
        }
        ElseIf ($Moon)
        {
            Write-Output "Getting today's moon phase" | Timestamp
            (curl http://wttr.in/moon -UserAgent "curl" ).Content
        }
        ElseIf ($MoonOnDate)
        {
            Write-Output "Getting moon phase for $MoonOnDate" | Timestamp
            (curl http://wttr.in/moon@$MoonOnDate -UserAgent "curl" ).Content
        }
        Else
        {
            Write-Output "Getting weather for current location" | Timestamp
            (curl http://wttr.in -UserAgent "curl" ).Content
        }
    
    }

    End
    {
        If ($EnableLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

# Get-Weather

<#######</Body>#######>
<#######</Script>#######>