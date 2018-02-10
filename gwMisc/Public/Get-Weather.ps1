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
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/

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
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log 
    }
    
    Process
    {   
        
        

        If ($City)
        {
            Log "Getting weather for $City"
            (curl http://wttr.in/$City -UserAgent "curl" ).Content
            # Cannot substitue "curl" for "Invoke-WebRequest -URI" ....
        }
        ElseIf ($JustToday)
        {
            Log "Getting weather for today's current location"
            (curl http://wttr.in/?0 -UserAgent "curl" ).Content
        }
        ElseIf ($TwoDays)
        {
            Log "Getting two days weather forcast for current location"
            (curl http://wttr.in/?2 -UserAgent "curl" ).Content
        }
        ElseIf ($ByZip)
        {
            Log "Getting weather for zipcode $ByZip"
            (curl http://wttr.in/$ByZip -UserAgent "curl" ).Content
        }
        ElseIf ($Moon)
        {
            Log "Getting today's moon phase"
            (curl http://wttr.in/moon -UserAgent "curl" ).Content
        }
        ElseIf ($MoonOnDate)
        {
            Log "Getting moon phase for $MoonOnDate"
            (curl http://wttr.in/moon@$MoonOnDate -UserAgent "curl" ).Content
        }
        Else
        {
            Log "Getting weather for current location"
            (curl http://wttr.in -UserAgent "curl" ).Content
        }
    
    }

    End
    {
        Stop-Log  
    }

}

# Get-Weather

<#######</Body>#######>
<#######</Script>#######>