<#######<Script>#######>
<#######<Header>#######>
# Name: Convert-Bookmarks
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Convert-Bookmarks
{
    <#
.Synopsis
This script takes my bookmarks from "bookmarks.google.com" and removes the "fluff" so that I can post it to my Bookmarks page on my blog.
.Description
This script takes my bookmarks from "bookmarks.google.com" and removes the "fluff" so that I can post it to my Bookmarks page on my blog.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Convert-Bookmarks
Downloads my current bookmarks, does replacements, and sends out a "completed.html" to my downloads folder.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Convert-Bookmarks.log"
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
    }
    
    Process
    {   
        If (Test-Path "c:\users\$env:username\Downloads\GoogleBookmarks.html")
        {
            Remove-Item "c:\users\$env:username\Downloads\GoogleBookmarks.html"
        }

        & 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' https://www.google.com/bookmarks/bookmarks.html?hl=en

        Set-Location -Path "$env:userprofile\Downloads"
        Start-Sleep -Seconds 6

        $File = "$env:userprofile\Downloads\GoogleBookmarks.html"
        $Find = [regex]::Escape($Find) 

        $Find = '<DT>'
        $Replace = (Get-Content $File -Raw) -replace '<DT>', '' -Replace '<DL>', '' -Replace '</DL>', '' -replace 'ADD_DATE=..................', '' |
            Add-Content -Path "$File.tmp" -Force 
        Remove-Item -Path $File 
        Rename-Item -Path "$File.tmp" -NewName $File

        $a = foreach ($line in [System.IO.File]::ReadLines($file)) 
        {
            If ( $line -cmatch '^<A HREF' )
            {
                [regex]$pattern = '>'
                $pattern.replace($line, ' target="_blank">', 1) 
            }
            Else
            {
                $line
            }
        }
        $a | Out-File '.\Completed.html'    
    
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

# Convert-Bookmarks

<#######</Body>#######>
<#######</Script>#######>