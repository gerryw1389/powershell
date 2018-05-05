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
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Update-File C:\scripts\text.txt
Creates a "text.txt" in C:\scripts. If it already exists, it just updates the file's "lastwritetime" property.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [String[]]$File,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Update-File.Log"
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
    }
    
    Process
    { 
        Foreach ($F In $File)
        {
            If (Test-Path -Literalpath $F)
            {
                # File Exists, Update Last Write Time To Now
                $Setprops = @{
                    Literalpath = $F
                    Name        = 'Lastwritetime'
                    Value       = (Get-Date)
                }
                Set-Itemproperty @Setprops
                Write-Output "$F already exists, updating file to today's lastwritetime" | Timestamp
            }
            Else
            {
                # Create New File. 
                # Don't Use `Echo $Null > $File` Because It Creates An Utf-16 (Le)
                # And A Lot Of Tools Have Issues With That
                Write-Output $Null | Out-File -Encoding Ascii -Literalpath $F
                Write-Output "$F does not exist, creating an empty file" | Timestamp
                # Alternative
                # New-Item -Path $File -Itemtype File | Out-Null
            }
        }
    }

    End
    {
        If ($EnableLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>