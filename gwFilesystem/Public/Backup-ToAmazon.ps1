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
    .Example
    Backup-ToAmazon -Source "D:\backups" -Bucket "Backups" -Akey "asdfadfasdf" -Skey "adfasdfsdaf"
    Zips up every folder in D:\backups one by one into separate zip files. It then uploads them to an Amazon Bucket called "backups".
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
        [String]$Skey
    )

    
    Begin
    {
        # Load the required module(s) 
        Try
        {
            Import-Module pscx -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'Pscx' was not found, stopping script"
            Exit 1
        }

        # Load the required module(s) 
        Try
        {
            Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1" -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'AWSPowerShell' was not found, stopping script"
            Exit 1
        }

        Set-AWSCredentials -AccessKey $AKey -SecretKey $SKey
 
        Set-Location $Source
        $Source = Get-Childitem $Source | Where-Object { $_.PSisContainer }
    }
    
    Process
    {    
        ForEach ($S in $Source)
        {
            $ItemName = $S.name
            Write-Output "Uploading $ItemName"
            $Destination = $Source + "\" + "$ItemName.zip"
            Write-Zip -LiteralPath $S.fullname -OutputPath $Destination -Level 1
            Remove-Item $S.fullname -Recurse -Force
            Write-S3Object -BucketName $Bucket -File $Destination
            Write-Output "Upload of $ItemName completed"
        } 
    }

    End
    {    
    }

}

<#######</Body>#######>
<#######</Script>#######>