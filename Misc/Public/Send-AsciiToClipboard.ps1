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
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
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
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log 

        $OutputEncoding = [System.Text.Encoding]::unicode
    }

    Process
    {    
        If ($Shrug)
        {
            [char[]]@(175, 92, 95, 40, 12484, 41, 95, 47, 175) -join '' | clip
            Log "Shrug sent to clipboard" 
        }
        If ($Disapproval)
        {
            [char[]]@(3232, 95, 3232) -join '' | clip
            Log "Disapproval sent to clipboard"  
        }
        If ($TableFlip)
        {
            [char[]]@(40, 9583, 176, 9633, 176, 65289, 9583, 65077, 32, 9531, 9473, 9531, 41) -join '' | clip
            Log "TableFlip sent to clipboard"  
        }
        If ($TableBack)
        {
            [char[]]@(9516, 9472, 9472, 9516, 32, 175, 92, 95, 40, 12484, 41) -join '' | clip
            Log "TableBack sent to clipboard"  
        }
        If ($TableFlip2)
        {
            [char[]]@(9531, 9473, 9531, 32, 65077, 12541, 40, 96, 1044, 180, 41, 65417, 65077, 32, 9531, 9473, 9531) -join '' | clip
            Log "TableFlip2 sent to clipboard"  
        }
        If ($TableBack2)
        {
            [char[]]@(9516, 9472, 9516, 12494, 40, 32, 186, 32, 95, 32, 186, 12494, 41) -join '' | clip
            Log "$TableBack2 sent to clipboard"  
        }
        If ($TableFlip3)
        {
            [char[]]@(40, 12494, 3232, 30410, 3232, 41, 12494, 24417, 9531, 9473, 9531) -join '' | clip
            Log "TableFlip3 sent to clipboard"  
        }
        If ($Denko)
        {
            [char[]]@(40, 180, 65381, 969, 65381, 96, 41) -join '' | clip
            Log "Denko sent to clipboard"  
        }
        If ($BlowKiss)
        {
            [char[]]@(40, 42, 94, 51, 94, 41, 47, 126, 9734) -join '' | clip
            Log "BlowKiss sent to clipboard" 
        }
        If ($Lenny)
        {
            [char[]]@(40, 32, 865, 176, 32, 860, 662, 32, 865, 176, 41) -join '' | clip
            Log "Lenny sent to clipboard"  
        }
        If ($Angry)
        {
            [char[]]@(40, 65283, 65439, 1044, 65439, 41) -join '' | clip
            Log "Angry sent to clipboard"  
        }
        If ($DontKnow)
        {
            [char[]]@(9488, 40, 39, 65374, 39, 65307, 41, 9484) -join '' | clip
            Log "DontKnow sent to clipboard"  
        }
          
    }
        
    End
    {
        Stop-Log  
    }

}

# Send-AsciiToClipboard

<#######</Body>#######>
<#######</Script>#######>