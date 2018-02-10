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
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
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
        
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
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
$Replace = (Get-Content $File -Raw) -replace '<DT>', '' -Replace '<DL>', '' -Replace '</DL>','' -replace 'ADD_DATE=..................','' |
Add-Content -Path "$File.tmp" -Force 
Remove-Item -Path $File 
Rename-Item -Path "$File.tmp" -NewName $File

$a = foreach ($line in [System.IO.File]::ReadLines($file)) 
{
    If ( $line -cmatch '^<A HREF' )
       {
            [regex]$pattern = '>'
            $pattern.replace($line,' target="_blank">', 1) 
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
        Stop-Log  
    }

}

# Convert-Bookmarks

<#######</Body>#######>
<#######</Script>#######>