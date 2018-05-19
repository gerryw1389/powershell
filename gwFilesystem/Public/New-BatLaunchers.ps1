<#######<Script>#######>
<#######<Header>#######>
# Name: New-BatLaunchers
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function New-BatLaunchers
{
    <#
.Synopsis
Creates batch files for each powershell script in a directory.
.Description
Creates batch files for each powershell script in a directory. 
All my scripts call their main function at the end. You will need to uncomment this if you want the script to run by batch file!!!
.Parameter Path
The path to the scripts directory with the powershell scripts.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
New-BatLaunchers -Path C:\scripts
Creates a batch file for every powershell script that when double clicked, launches the script bypassing Executionpolicy.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [String]$Path,

        [String]$Logfile = "$PSScriptRoot\..\Logs\New-BatLaunchers.log"
    )
    
    Begin
    {   
    
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

        Function Write-TestFiles
        {
            New-Item -Path "C:\scripts" -Name "g" -ItemType Directory -Force | Out-Null
            New-Item -Path "C:\scripts\g" -Name "1.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g" -Name "2.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g" -Name "h" -ItemType Directory -Force | Out-Null
            New-Item -Path "C:\scripts\g\h" -Name "1.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g\h" -Name "2.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g\h" -Name "i" -ItemType Directory -Force | Out-Null
            New-Item -Path "C:\scripts\g\h\i" -Name "1.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g\h\i" -Name "2.ps1" -ItemType File -Force | Out-Null
            $Path = "C:\scripts\g"
        }

    }
    
    Process
    {   
        #Write-TestFiles
        $Files = Get-ChildItem $Path -Filter "*.ps1" -Recurse

        ForEach ($File in $Files)
        {
            Write-Output "Creating batch launcher for file $file" | Timestamp
            $Batch = $($File.DirectoryName) + "\" + $($File.BaseName) + ".bat"
            $String = @"
`@ECHO OFF
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dpn0.ps1""' -Verb RunAs}"
PAUSE
"@
            Write-Output $String | Out-File -LiteralPath $Batch -Encoding ascii

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

# New-BatLaunchers

<#######</Body>#######>
<#######</Script>#######>