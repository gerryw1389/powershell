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
    .Example
    Get-ExtractedEmailAddresses -InputFile c:\scripts\myfile.log
    Parses "c:\scripts\myfile.log" for any email addresses and returns a document called "extracted.txt" in the scripts running directory with the emails returned.
    #>

    [Cmdletbinding()]
    
    Param
    (
        [Parameter(Mandatory = $True)][String[]]$InputFile
    )
    
    Begin
    {   
        $OutputFile = "$Psscriptroot\extracted.txt"
        # Overwrite output file from previous run
        New-Item $OutputFile -ItemType File -Force | Out-Null
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
                Out-File $OutputFile -Encoding Ascii

            Write-Output "Successfully parsed $InputFile"
        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }

    End
    {
    }
}

<#######</Body>#######>
<#######</Script>#######>