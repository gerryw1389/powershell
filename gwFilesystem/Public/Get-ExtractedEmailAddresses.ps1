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
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Console
        Start-Log

        $OutputFile = "$Psscriptroot\extracted.txt"
        # Overwrite output file from previous run
        New-Item $OutputFile -ItemType File -Force
        Log "Creating output file if it doesn't exist. If it does, it is being overwritten."
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

            Log "Successfully parsed $InputFile"
        }
        Catch
        {
            Log $($_.Exception.Message) -Error -ExitGracefully
        }
    }

    End
    {
        Stop-Log  
    }

}


<#######</Body>#######>
<#######</Script>#######>