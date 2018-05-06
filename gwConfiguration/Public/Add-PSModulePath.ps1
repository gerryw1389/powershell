
<#######<Script>#######>
<#######<Header>#######>
# Name: Add-PSModulePath
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Add-PSModulePath
{
    <#
.Synopsis
Adds one or more paths to PS Module Path so that you can auto-load modules from a custom directory.
.Description
Adds one or more paths to PS Module Path so that you can auto-load modules from a custom directory.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Add-PSModulePath -Path "C:\Scripts\Modules"
Adds C:\scripts\Modules to your $env:psmodulepath.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]] $Path,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Add-PSModulePath.log"
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
        ForEach ($P in $Path)
        {
            $P = ";" + $P
            Write-Output "Adding $P to PSModulePath" | Timestamp
            $CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
            [Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + $P, "Machine")
        }
     
    }

    End
    {
        Write-Output "Make sure to restart powershell to see the new module path. Run '`$env:psmodulepath -split ';' to check" | Timestamp
        Write-Output "For a GUI version, run sysdm.cpl and go to Advanced - Environmental Variables - PSModulePath " | Timestamp
        
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