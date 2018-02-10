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
.Parameter Folder
Mandatory parameter that defines the folder.
.Parameter OldExtension
Mandatory parameter that defines the extension you want to change.
.Parameter NewExtension
Mandatory parameter that defines the extension you want to change to.
.Parameter Recurse
Optional parameter that tells the script to do the same action against all subfolders of the given folder.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Rename-Items -Source C:\scripts -OldExtension txt -NewExtension ps1 -Recurse
Changes all text files in C:\scripts to powershell files. With the "Recurse" option, we also do this to all subfolders in "C:\Scripts"
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>

    [Cmdletbinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Source,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$OldExtension,
        
        [Parameter(Position = 2, Mandatory = $true)]
        [String]$NewExtension,
        
        [Switch]$Recurse,
        
        [string]$logfile = "$PSScriptRoot\..\Logs\Rename-Items.log"
    )

    Begin
    {
        
        [String]$OldExtension = "." + $OldExtension
        [String]$NewExtension = "." + $NewExtension

        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log

    }
    
     Process
    {
        
        
                
        If ([Bool]($MyInvocation.BoundParameters.Keys -match 'Recurse'))
        {
            Get-Childitem $Source -Filter ("*" + $OldExtension) -Recurse | Rename-Item -Newname { [Io.Path]::Changeextension($_.Name, $NewExtension) }
            Log "Renamed all items in $Source and subfolders from $OldExtension to $NewExtension" 
        }
        Else
        {
            Get-Childitem $Source -Filter ( "*" + $OldExtension ) | Rename-Item -Newname { [Io.Path]::Changeextension($_.Name, $NewExtension) }
            Log "Renamed all items in $Source from $OldExtension to $NewExtension" 
        }
    }
    
    End
    {
        Stop-Log  
    }

}   

# Rename-Items

<#######</Body>#######>
<#######</Script>#######>