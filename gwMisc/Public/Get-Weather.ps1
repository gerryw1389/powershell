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
    .Example
    Get-Weather
    Gets three day weather forcast.
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
        [String]$MoonOnDate
    )
    
    Begin
    {   
    }
    
    Process
    {   
        If ($City)
        {
            Write-Output "Getting weather for $City"
            (curl http://wttr.in/$City -UserAgent "curl" ).Content
            # Cannot substitue "curl" for "Invoke-WebRequest -URI" ....
        }
        ElseIf ($JustToday)
        {
            Write-Output "Getting weather for today's current location"
            (curl http://wttr.in/?0 -UserAgent "curl" ).Content
        }
        ElseIf ($TwoDays)
        {
            Write-Output "Getting two days weather forcast for current location"
            (curl http://wttr.in/?2 -UserAgent "curl" ).Content
        }
        ElseIf ($ByZip)
        {
            Write-Output "Getting weather for zipcode $ByZip"
            (curl http://wttr.in/$ByZip -UserAgent "curl" ).Content
        }
        ElseIf ($Moon)
        {
            Write-Output "Getting today's moon phase"
            (curl http://wttr.in/moon -UserAgent "curl" ).Content
        }
        ElseIf ($MoonOnDate)
        {
            Write-Output "Getting moon phase for $MoonOnDate"
            (curl http://wttr.in/moon@$MoonOnDate -UserAgent "curl" ).Content
        }
        Else
        {
            Write-Output "Getting weather for current location"
            (curl http://wttr.in -UserAgent "curl" ).Content
        }
    
    }

    End
    {
        
    }
}

<#######</Body>#######>
<#######</Script>#######>