<#######<Script>#######>
<#######<Header>#######>
# Name: Set-FileTimeStamps
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-FileTimeStamps
{
    <#
.Synopsis
Sets the time stamps for all files in a given folder (and optionally, subfolders) to a specific date.
.Description
Sets the time stamps for all files in a given folder (and optionally, subfolders) to a specific date.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Set-FileTimeStamps -Source C:\scripts -Date 3/3/2015
Sets the time stamps for all files in a given folder to a specific date.
.Example
Set-FileTimeStamps -Path C:\scripts -Date 3/3/2015 -Recurse
Sets the time stamps for all files in a given folder and subfolders to a specific date.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>  [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Source,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [DateTime]$Date,
        
        [Parameter(Position = 2)]
        [Switch]$Recurse,
        
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-FileTimeStamps.Log"
    )

  
    Begin
    {
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    }
    
    Process
    {    
        If ($Recurse)
        {
            Get-ChildItem -Path $Source -Recurse |
                ForEach-Object {
                $_.CreationTime = $Date
                $_.LastAccessTime = $Date
                $_.LastWriteTime = $Date }
            Log "all files in $Source successfully set to $Date" 
        }
        
        Else
        {
            Get-ChildItem -Path $Source |
                ForEach-Object {
                $_.CreationTime = $Date
                $_.LastAccessTime = $Date
                $_.LastWriteTime = $Date }
            Log "all files in $Source successfully set to $Date" 
        }
    }

    End
    {
        Stop-Log  
    }

}

# Set-FileTimeStamps -Path C:\scripts -Date 3/3/2015

<#######</Body>#######>
<#######</Script>#######>