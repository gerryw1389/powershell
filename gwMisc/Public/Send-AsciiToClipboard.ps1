<#######<Script>#######>
<#######<Header>#######>
# Name: Send-AsciiToClipboard
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

FUNCTION Send-AsciiToClipboard
{
    <#
.SYNOPSIS
Send-AsciiToClipboard sends a set of ASCII symbols to your clipboard.
.DESCRIPTION 
Send-AsciiToClipboard sends a set of ASCII symbols to your clipboard.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.EXAMPLE
Send-AsciiToClipboard -Shrug
# Sends ?¯\_(?)_/¯ to the clipboard
.LINK
https://www.reddit.com/r/PowerShell/comments/4aipw5/%E3%83%84/
.NOTES
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>   
    [cmdletbinding()]

    Param
    (
        [switch]$Shrug,
        [switch]$Disapproval,
        [switch]$TableFlip,
        [switch]$TableBack,
        [switch]$TableFlip2,
        [switch]$TableBack2,
        [switch]$TableFlip3,
        [switch]$Denko,
        [switch]$BlowKiss,
        [switch]$Lenny,
        [switch]$Angry,
        [switch]$DontKnow,
        [String]$Logfile = "$PSScriptRoot\..\Logs\Send-AsciiToClipboard.Log"
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

        $OutputEncoding = [System.Text.Encoding]::unicode
    }

    Process
    {    
        If ($Shrug)
        {
            [char[]]@(175, 92, 95, 40, 12484, 41, 95, 47, 175) -join '' | clip
            Write-Output "Shrug sent to clipboard" | Timestamp
        }
        If ($Disapproval)
        {
            [char[]]@(3232, 95, 3232) -join '' | clip
            Write-Output "Disapproval sent to clipboard" | Timestamp
        }
        If ($TableFlip)
        {
            [char[]]@(40, 9583, 176, 9633, 176, 65289, 9583, 65077, 32, 9531, 9473, 9531, 41) -join '' | clip
            Write-Output "TableFlip sent to clipboard" | Timestamp
        }
        If ($TableBack)
        {
            [char[]]@(9516, 9472, 9472, 9516, 32, 175, 92, 95, 40, 12484, 41) -join '' | clip
            Write-Output "TableBack sent to clipboard" | Timestamp
        }
        If ($TableFlip2)
        {
            [char[]]@(9531, 9473, 9531, 32, 65077, 12541, 40, 96, 1044, 180, 41, 65417, 65077, 32, 9531, 9473, 9531) -join '' | clip
            Write-Output "TableFlip2 sent to clipboard" | Timestamp
        }
        If ($TableBack2)
        {
            [char[]]@(9516, 9472, 9516, 12494, 40, 32, 186, 32, 95, 32, 186, 12494, 41) -join '' | clip
            Write-Output "$TableBack2 sent to clipboard" | Timestamp
        }
        If ($TableFlip3)
        {
            [char[]]@(40, 12494, 3232, 30410, 3232, 41, 12494, 24417, 9531, 9473, 9531) -join '' | clip
            Write-Output "TableFlip3 sent to clipboard" | Timestamp
        }
        If ($Denko)
        {
            [char[]]@(40, 180, 65381, 969, 65381, 96, 41) -join '' | clip
            Write-Output "Denko sent to clipboard" | Timestamp
        }
        If ($BlowKiss)
        {
            [char[]]@(40, 42, 94, 51, 94, 41, 47, 126, 9734) -join '' | clip
            Write-Output "BlowKiss sent to clipboard" | Timestamp
        }
        If ($Lenny)
        {
            [char[]]@(40, 32, 865, 176, 32, 860, 662, 32, 865, 176, 41) -join '' | clip
            Write-Output "Lenny sent to clipboard" | Timestamp
        }
        If ($Angry)
        {
            [char[]]@(40, 65283, 65439, 1044, 65439, 41) -join '' | clip
            Write-Output "Angry sent to clipboard" | Timestamp
        }
        If ($DontKnow)
        {
            [char[]]@(9488, 40, 39, 65374, 39, 65307, 41, 9484) -join '' | clip
            Write-Output "DontKnow sent to clipboard" | Timestamp
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

# Send-AsciiToClipboard

<#######</Body>#######>
<#######</Script>#######>