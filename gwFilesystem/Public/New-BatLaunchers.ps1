<#######<Script>#######>
<#######<Header>#######>
# Name: New-BatLaunchers
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function New-BatLaunchers
{
    <#
.Synopsis
Creates batch files for each powershell script in a directory.
.Description
Creates batch files for each powershell script in a directory. 
All my scripts call their main function at the end. You will need to uncomment this if you want the script to run by batch file!!!
.Parameter Path
The path to the scripts directory with the powershell scripts.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
New-BatLaunchers -Path C:\scripts
Creates a batch file for every powershell script that when double clicked, launches the script bypassing Executionpolicy.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [String]$Path,

        [String]$Logfile = "$PSScriptRoot\..\Logs\New-BatLaunchers.log"
    )
    
    Begin
    {       
        
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log

        Function Write-TestFiles
        {
            New-Item -Path "C:\scripts" -Name "g" -ItemType Directory
            New-Item -Path "C:\scripts\g" -Name "1.ps1" -ItemType File
            New-Item -Path "C:\scripts\g" -Name "2.ps1" -ItemType File
            New-Item -Path "C:\scripts\g" -Name "h" -ItemType Directory
            New-Item -Path "C:\scripts\g\h" -Name "1.ps1" -ItemType File
            New-Item -Path "C:\scripts\g\h" -Name "2.ps1" -ItemType File
            New-Item -Path "C:\scripts\g\h" -Name "i" -ItemType Directory
            New-Item -Path "C:\scripts\g\h\i" -Name "1.ps1" -ItemType File
            New-Item -Path "C:\scripts\g\h\i" -Name "2.ps1" -ItemType File
            $Path = "C:\scripts\g"
        }

    }
    
    Process
    {   
        #Write-TestFiles
        $Files = Get-ChildItem $Path -Filter "*.ps1" -Recurse

        ForEach ($File in $Files)
        {
            $Batch = $($File.DirectoryName) + "\" + $($File.BaseName) + ".bat"
            $String = @"
`@ECHO OFF
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dpn0.ps1""' -Verb RunAs}"
PAUSE
"@
            Write-Output $String | Out-File -LiteralPath $Batch -Encoding ascii

        }    
    
    }

    End
    {
        Stop-Log  
    }

}

# New-BatLaunchers

<#######</Body>#######>
<#######</Script>#######>