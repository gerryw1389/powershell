<#######<Script>#######>
<#######<Header>#######>
# Name: Set-Content
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-Content
{
    <#
.Synopsis
Adds formatted text to the beginning and end of all text, log, and powershell files in the source directory. 
Make sure to edit the $Preformatting and $Postformatting variables before running it!
.Description
Adds formatted text to the beginning and end of all text, log, and powershell files in the source directory. 
Make sure to edit the $Preformatting and $Postformatting variables before running it!
.Parameter Source
Mandatory parameter that specifies a source directory where your files are located.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Set-Content -Source C:\scripts
Adds formatted text to the beginning and end of all files at c:\scripts.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>   [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Source,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-Content.Log"
    )

    Begin
    {
    
        # Edit these extensions to the type of files you want to add content to.
        $Include = @("*.txt", "*.ps1", "*.log")
    
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
        # $Source = Get-Childitem "C:\Test" -Include "$Include" -Recurse
        $Source = Get-Childitem "C:\Test" -Include "$Include"

        Foreach ($File In $Source)
        {

            Write-Output "Processing $File ..." | Timestamp
    
            # Remember to use the escape character "`" before every dollar sign and ` character. For example `$myVar and ``r``n (new line)
            $Preformatting = @"
Multi-Line
Text
To
Insert
At
Top
"@

            $CurrentFile = Get-Content $File

            $PostFormatting = @"
Multi-Line
Text
To
Insert
At
Bottom
"@

            $Val = -Join $Preformatting, $CurrentFile, $PostFormatting
            Set-Content -Path $File -Value $Val
            Write-Output "$File rewritten successfully" | Timestamp
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

# Set-Content -Source C:\scripts

<#######</Body>#######>
<#######</Script>#######>