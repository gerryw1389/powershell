<#######<Script>#######>
<#######<Header>#######>
# Name: Move-FilesToArchive
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Move-FilesToArchive
{
    <#
.Synopsis
Moves files older than a specific number of days to a new location.
.Description
Moves files older than a specific number of days to a new location.
.Parameter Source
Mandatory parameter that specifies a source directory. This will be searched RECURSIVELY to move older files.
.Parameter Destination
Mandatory parameter that specifies a destination directory.
.Parameter Days
Mandatory parameter that specifies how many days back you want to go for moving files.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Move-FilesToArchive -Source C:\test -Dest C:\test2 -Days 365
Moves files older than a specific number of days to a new location.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>    
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Source,
    
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Destination,
    
        [Parameter(Position = 2, Mandatory = $true)]
        [Int]$Days,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Move-FilesToArchive.Log"
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
        Write-Output "Moving all files under directory $Source to $Destination" | Timestamp
        Get-Childitem $Source -Recurse |
            Where-Object { $_.Lastwritetime -Lt (Get-Date).Adddays( - $Days) } | 
            Move-Item -Destination $Destination -Force 

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

<#######</Body>#######>
<#######</Script>#######>