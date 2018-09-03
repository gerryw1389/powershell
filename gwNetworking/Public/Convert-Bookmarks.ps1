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
    .Example
    Convert-Bookmarks
    Downloads my current bookmarks, does replacements, and sends out a "completed.html" to my downloads folder.
    #>

    [Cmdletbinding()]
    
    Param
    (
    )
    
    Begin
    {      
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
        (Get-Content $File -Raw) -replace '<DT>', '' -Replace '<DL>', '' -Replace '</DL>', '' -replace 'ADD_DATE=..................', '' |
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
    }

}

<#######</Body>#######>
<#######</Script>#######>