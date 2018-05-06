<#######<Script>#######>
<#######<Header>#######>
# Name: Set-FileTimeStamps
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-FileTimeStamps
{
    <#
.Synopsis
Sets the time stamps for all files in a given folder (and optionally, subfolders) to a specific date.
.Description
Sets the time stamps for all files in a given folder (and optionally, subfolders) to a specific date.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Set-FileTimeStamps -Source C:\scripts -Date 3/3/2015
Sets the time stamps for all files in a given folder to a specific date.
.Example
Set-FileTimeStamps -Path C:\scripts -Date 3/3/2015 -Recurse
Sets the time stamps for all files in a given folder and subfolders to a specific date.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>  [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Source,
    
        [Parameter(Position = 1, Mandatory = $true)]
        [DateTime]$Date,
    
        [Parameter(Position = 2)]
        [Switch]$Recurse,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-FileTimeStamps.Log"
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
        If ($Recurse)
        {
            Get-ChildItem -Path $Source -Recurse |
                ForEach-Object {
                $_.CreationTime = $Date
                $_.LastAccessTime = $Date
                $_.LastWriteTime = $Date }
            Write-Output "all files in $Source successfully set to $Date" | Timestamp
        }
    
        Else
        {
            Get-ChildItem -Path $Source |
                ForEach-Object {
                $_.CreationTime = $Date
                $_.LastAccessTime = $Date
                $_.LastWriteTime = $Date }
            Write-Output "all files in $Source successfully set to $Date" | Timestamp
        }
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

# Set-FileTimeStamps -Path C:\scripts -Date 3/3/2015

<#######</Body>#######>
<#######</Script>#######>