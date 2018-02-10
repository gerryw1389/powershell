
<#######<Script>#######>
<#######<Header>#######>
# Name: Add-PSModulePath
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Add-PSModulePath
{
    <#
.Synopsis
Adds one or more paths to PS Module Path so that you can auto-load modules from a custom directory.
.Description
Adds one or more paths to PS Module Path so that you can auto-load modules from a custom directory.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Add-PSModulePath -Path "C:\Scripts\Modules"
Adds C:\scripts\Modules to your $env:psmodulepath.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]] $Path,
        
        [String]$Logfile = "$PSScriptRoot\..\Logs\Add-PSModulePath.log"
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
        
        

        ForEach ($P in $Path)
        {
            $P = ";" + $P
            Log "Adding $P to PSModulePath"
            $CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
            [Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + $P, "Machine")
        }
         
    }

    End
    {
        Log "Make sure to restart powershell to see the new module path. Run '`$env:psmodulepath -split ';' to check"
        Log "For a GUI version, run sysdm.cpl and go to Advanced - Environmental Variables - PSModulePath "
        Stop-Log
    }

}

# Add-PSModulePath

<#######</Body>#######>
<#######</Script>#######>