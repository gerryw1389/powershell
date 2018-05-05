<#######<Script>#######>
<#######<Header>#######>
# Name: Set-TempFile
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-TempFile
{
    <#
.Synopsis
Creates a blank temp file to be used by other functions.
.Description
Creates a blank temp file to be used by other functions.
.Parameter Path
Mandatory parameter that specifies the path for the blank file.
.Parameter Size
Mandatory parameter that specifies the size of the blank file in megabytes (mb).
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Set-TempFile -Path "c:\scripts\tempfile.txt" -Size 10mb
Creates a file called tempfile.txt at the C:\scripts location with a size of ten megabytes.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]]$Path,

        [Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Enter the size in MB')]
        [Double]$Size,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-TempFile.log"
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
            If (Test-Path $P)
            {
                Write-Output "File already exists, skipping..." | Timestamp
            }
            Else
            {
                $File = [io.file]::Create($P)
                Write-Output "File $P created" | Timestamp
    
                $File.SetLength($Size)
                Write-Output "File $P set to $Size megabytes" | Timestamp
		
                $File.Close()  
            }
    
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

# Set-TempFile

<#######</Body>#######>
<#######</Script>#######>