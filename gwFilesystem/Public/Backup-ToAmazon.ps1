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
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
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
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log

    }
    
    Process
    {    
        
        

        ForEach ($S in $Source)
        {
            $ItemName = $S.name
            Log "Uploading $ItemName"
            $Destination = $Source + "\" + "$ItemName.zip"
            Write-Zip -LiteralPath $S.fullname -OutputPath $Destination -Level 1
            Remove-Item $S.fullname -Recurse -Force
            Write-S3Object -BucketName $Bucket -File $Destination
            Log "Upload of $ItemName completed"
            
        } 
    }

    End
    {
        Stop-Log  
    }

}

# Backup-ToAmazon

<#######</Body>#######>
<#######</Script>#######>