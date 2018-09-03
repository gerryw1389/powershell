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
    .Example
    Send-GUIDToClipboard
    Sends a newly generated GUID to the clipboard.
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
        $GUID = [guid]::NewGuid().ToString() 
        $GUID | Clip.exe
        Write-Output "Guid: $GUID sent to clipboard"
    }

    End
    {
    }
}

<#######</Body>#######>
<#######</Script>#######>