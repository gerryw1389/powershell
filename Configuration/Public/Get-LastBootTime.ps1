<#######<Script>#######>
<#######<Header>#######>
# Name: Get-LastBootTime
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Get-LastBootTime
{
    <#
.Synopsis
Returns the last boot time of the computer.
.Description
Returns the last boot time of the computer.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Get-LastBootTime
Returns the last boot time of the computer.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>    
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Get-LastBootTime.Log"
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
        
        

        $computer = $($env:COMPUTERNAME)
        $Lastboottime = (Get-Ciminstance -Classname Win32_Operatingsystem | Select-Object -Property Lastbootuptime).Lastbootuptime
         
        $table = [Pscustomobject] @{
            ComputerName = $Computer
            LastBootTime = $Lastboottime
        }
        Log $table
        $table | Out-File $Logfile -Append
    }

    End
    {
        Stop-Log  
    }

}

# Get-LastBootTime

<#######</Body>#######>
<#######</Script>#######>