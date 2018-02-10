<#######<Script>#######>
<#######<Header>#######>
# Name: Send-GUIDToClipboard
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Send-GUIDToClipboard
{
    <#
.Synopsis
Small function that sends a newly generated GUID to the clipboard. Usually used as random data.
.Description
Small function that sends a newly generated GUID to the clipboard. Usually used as random data.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Send-GUIDToClipboard
Sends a newly generated GUID to the clipboard.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Send-GUIDToClipboard.log"
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

        $GUID = [guid]::NewGuid().ToString() 
        $GUID | Clip.exe
        Log "Guid: $GUID sent to clipboard"
    
    }

    End
    {
        Stop-Log  
    }

}

# Send-GUIDToClipboard

<#######</Body>#######>
<#######</Script>#######>