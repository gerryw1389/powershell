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
    .Example
    Send-LinkToHelpdesk
    Sends Helpdesk link to Desktop
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
        Write-Output "Link $string sent to desktop as shortcut"
    }

    End
    {
    }
}

<#######</Body>#######>
<#######</Script>#######>