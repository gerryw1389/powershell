<#######<Script>#######>
<#######<Header>#######>
# Name: Send-LinkToHelpdesk
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Send-LinkToHelpdesk
{
 
    <#
.Synopsis
Sends Helpdesk link to Desktop
.Description
Sends Helpdesk link to Desktop. Feel free to omit this code, but it works great with web API's as you just insert
User names into the URL to create a custom form the user can click on to submit a ticket. YMMV.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Send-LinkToHelpdesk
Sends Helpdesk link to Desktop
.Example
"Pc2", "Pc1" | Send-LinkToHelpdesk
Sends Helpdesk link to Desktop
.Notes
This function is interactive due to read-host.
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>   
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Send-LinkToHelpdesk.Log"
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
        $fname = read-host "enter the first name of the user"
        $lname = read-host "enter the last name of the user"

        $string = 'http://helpdeskexample.com/Helpdesk/Tickets/New/?name=' `
            + $fname + '%20' + $lname + '&userName=' + $fname + $lname `
            + '&email=' `
            + $fname + $lname + '@yourdomain.com'

        $TargetFile = "$string"
        $ShortcutFile = "$env:userprofile\Desktop\Helpdesk.url"
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
        $Shortcut.TargetPath = $TargetFile
        $Shortcut.Save()
        Log "Link $string sent to desktop as shortcut"

    }

    End
    {
        Stop-Log  
    }

}

# Send-LinkToHelpdesk


<#######</Body>#######>
<#######</Script>#######>