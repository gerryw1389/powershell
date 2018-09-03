<#######<Script>#######>
<#######<Header>#######>
# Name: Update-File
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Update-File
{    
    <#
    .Synopsis
    Same as unix "touch" command. Updates a pre-existing file's "lastwritetime" property or creates a new emtpy file.
    .Description
    Same as unix "touch" command. Updates a pre-existing file's "lastwritetime" property or creates a new emtpy file.
    .Parameter File
    Mandatory parameter that specifies the file or files to be created or updated.
    .Example
    Update-File C:\scripts\text.txt
    Creates a "text.txt" in C:\scripts. If it already exists, it just updates the file's "lastwritetime" property.
    #>

    [Cmdletbinding()]
    
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [String[]]$File
    )

    Begin
    {
        $Date = Get-Date
    }
    
    Process
    { 
        Foreach ($F In $File)
        {
            If (Test-Path -Literalpath $F)
            {
                # File Exists, Update Last Write Time To Now
                Get-ChildItem -Path $Source |
                ForEach-Object {
                $_.CreationTime = $Date
                $_.LastAccessTime = $Date
                $_.LastWriteTime = $Date }
                Write-Output "$F already exists, updating file to today's lastwritetime"
            }
            Else
            {
                # Create New File. 
                # Don't Use `Echo $Null > $File` Because It Creates An Utf-16 (Le)
                # And A Lot Of Tools Have Issues With That
                Write-Output $Null | Out-File -Encoding Ascii -Literalpath $F
                Write-Output "$F does not exist, creating an empty file"
                # Alternative
                # New-Item -Path $File -Itemtype File | Out-Null
            }
        }
    }

    End
    {
        
    }
}

<#######</Body>#######>
<#######</Script>#######>