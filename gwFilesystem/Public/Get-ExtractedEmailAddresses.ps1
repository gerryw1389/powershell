<#######<Script>#######>
<#######<Header>#######>
# Name: Get-ExtractedEmailAddresses
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Get-ExtractedEmailAddresses
{
    <#
.Synopsis
Gets email addresses from one or more text files.
.Description
Gets email addresses from one or more text files. Returns a seperate parsed file called ".\extracted.txt"
To further clean up the results, I would run: Get-Content .\Extracted.Txt | Sort-Object | Select-Object -Unique | Out-File .\Sorted.Txt -Force
.Parameter InputFile
Mandatory. List of one or more files to be processed.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
.Example
Get-ExtractedEmailAddresses -InputFile c:\scripts\myfile.log
Parses "c:\scripts\myfile.log" for any email addresses and returns a document called "extracted.txt" in the scripts running directory with the emails returned.
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $True)][String[]]$InputFile,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-Template.log"
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

        $OutputFile = "$Psscriptroot\extracted.txt"
        # Overwrite output file from previous run
        New-Item $OutputFile -ItemType File -Force
        Write-Output "Creating output file if it doesn't exist. If it does, it is being overwritten." | Timestamp
    }
    
    Process
    {   
        Try
        {
    
            $EmailRegex = '\b[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}\b'
            # $IPAddressRegex = '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'
            # $URLRegex = '([a-zA-Z]{3,})://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'

            Select-String -Path $InputFile -Pattern $EmailRegex -AllMatches | 
                ForEach-Object { $_.Matches } | 
                ForEach-Object { $_.Value } |
                Out-File $OutputFile -Encoding ascii

            Write-Output "Successfully parsed $InputFile" | Timestamp
        }
        Catch
        {
            Write-Error $($_.Exception.Message)
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