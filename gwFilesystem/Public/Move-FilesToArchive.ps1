<#######<Script>#######>
<#######<Header>#######>
# Name: Move-FilesToArchive
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Move-FilesToArchive
{
    <#
.Synopsis
Moves files older than a specific number of days to a new location.
.Description
Moves files older than a specific number of days to a new location.
.Parameter Source
Mandatory parameter that specifies a source directory. This will be searched RECURSIVELY to move older files.
.Parameter Destination
Mandatory parameter that specifies a destination directory.
.Parameter Days
Mandatory parameter that specifies how many days back you want to go for moving files.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Move-FilesToArchive -Source C:\test -Dest C:\test2 -Days 365
Moves files older than a specific number of days to a new location.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>    
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Source,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Destination,
        
        [Parameter(Position = 2, Mandatory = $true)]
        [Int]$Days,
        
        [String]$Logfile = "$PSScriptRoot\..\Logs\Move-FilesToArchive.Log"
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
        
        

        Get-Childitem $Source -Recurse |
            Where-Object { $_.Lastwritetime -Lt (Get-Date).Adddays( - $Days) } | 
            Move-Item -Destination $Destination -Force 
    }
    
    End
    {
        Stop-Log  
    }

}

# Move-FilesToArchive -Source C:\test -Dest C:\test2 -Days 10

<#######</Body>#######>
<#######</Script>#######>