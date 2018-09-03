<#######<Script>#######>
<#######<Header>#######>
# Name: Rename-Items
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Rename-Items
{
    <#
    .Synopsis
    Renames all items of a given extension to a new extension.
    .Description
    Renames all items of a given extension to a new extension in a folder or a folder and its subfolders.
    .Parameter Path
    Mandatory parameter that defines the folder.
    .Parameter OldExtension
    Mandatory parameter that defines the extension you want to change.
    .Parameter NewExtension
    Mandatory parameter that defines the extension you want to change to.
    .Parameter Recurse
    Optional parameter that tells the script to do the same action against all subfolders of the given folder.
    .Example
    Rename-Items -Source C:\scripts -OldExtension txt -NewExtension ps1 -Recurse
    Changes all text files in C:\scripts to powershell files. With the "Recurse" option, we also do this to all subfolders in "C:\Scripts"
    #>

    [Cmdletbinding()]
    
    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Path,
    
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$OldExtension,
    
        [Parameter(Position = 2, Mandatory = $true)]
        [String]$NewExtension,
    
        [Switch]$Recurse
    )

    Begin
    {
        [String]$OldExtension = "." + $OldExtension
        [String]$NewExtension = "." + $NewExtension
    }
    
    Process
    {
        If ([Bool]($MyInvocation.BoundParameters.Keys -match 'Recurse'))
        {
            Get-Childitem $Path -Filter ("*" + $OldExtension) -Recurse | Rename-Item -Newname { [Io.Path]::Changeextension($_.Name, $NewExtension) }
            Write-Output "Renamed all items in $Path and subfolders from $OldExtension to $NewExtension"
        }
        Else
        {
            Get-Childitem $Path -Filter ( "*" + $OldExtension ) | Rename-Item -Newname { [Io.Path]::Changeextension($_.Name, $NewExtension) }
            Write-Output "Renamed all items in $Path from $OldExtension to $NewExtension"
        }
    }
    
    End
    {
        
    }
}

<#######</Body>#######>
<#######</Script>#######>