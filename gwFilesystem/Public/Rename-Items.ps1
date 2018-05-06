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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
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

    }
    
    Process
    {
        If ([Bool]($MyInvocation.BoundParameters.Keys -match 'Recurse'))
        {
            Get-Childitem $Source -Filter ("*" + $OldExtension) -Recurse | Rename-Item -Newname { [Io.Path]::Changeextension($_.Name, $NewExtension) }
            Write-Output "Renamed all items in $Source and subfolders from $OldExtension to $NewExtension" | TimeStamp
        }
        Else
        {
            Get-Childitem $Source -Filter ( "*" + $OldExtension ) | Rename-Item -Newname { [Io.Path]::Changeextension($_.Name, $NewExtension) }
            Write-Output "Renamed all items in $Source from $OldExtension to $NewExtension" | TimeStamp
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

# Rename-Items

<#######</Body>#######>
<#######</Script>#######>