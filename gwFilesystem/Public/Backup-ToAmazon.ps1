<#######<Script>#######>
<#######<Header>#######>
# Name: Backup-ToAmazon
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Backup-ToAmazon
{
    <#
.Synopsis
Backs up a folder to Amazon S3 storage.
.Description
Backs up a folder to Amazon S3 storage. It works by taking a source folder, sorting by last created on each folder and zipping them up one by one.
It deletes the folder and then uploads the zip files to Amazon.
.Parameter Source
Mandatory parameter to specify the source folder directory.
.Parameter Bucket
Mandatory parameter to specify the Amazon Bucket Name.
.Parameter AKey
Mandatory parameter to specify the Amazon Access Key.
.Parameter SKey
Mandatory parameter to specify the Amazon Secret Key.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Backup-ToAmazon -Source "D:\backups" -Bucket "Backups" -Akey "asdfadfasdf" -Skey "adfasdfsdaf"
Zips up every folder in D:\backups one by one into separate zip files. It then uploads them to an Amazon Bucket called "backups".
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>    
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]$Source,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]$Bucket,
    
        [Parameter(Position = 2, Mandatory = $True)]
        [String]$Akey,
    
        [Parameter(Position = 3, Mandatory = $True)]
        [String]$Skey,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Backup-ToAmazon.Log"
    )

    
    Begin
    {
        Import-Module pscx
        Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

        Set-AWSCredentials -AccessKey $AKey -SecretKey $SKey
 
        Set-Location $Source
        $Source = Get-Childitem $Source | Where-Object { $_.PSisContainer }
    
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
        ForEach ($S in $Source)
        {
            $ItemName = $S.name
            Write-Output "Uploading $ItemName" | Timestamp
            $Destination = $Source + "\" + "$ItemName.zip"
            Write-Zip -LiteralPath $S.fullname -OutputPath $Destination -Level 1
            Remove-Item $S.fullname -Recurse -Force
            Write-S3Object -BucketName $Bucket -File $Destination
            Write-Output "Upload of $ItemName completed" | Timestamp
    
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

# Backup-ToAmazon

<#######</Body>#######>
<#######</Script>#######>