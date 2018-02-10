<#######<Script>#######>
<#######<Header>#######>
# Name: Restart-NIC
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Restart-NIC
{
    <#
.Synopsis
Restarts one or more network cards.
.Description
Restarts one or more network cards.
.Parameter NetAdapter
Mandatory parameter that specifies the name of the NICs you want to restart.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Set-Template
Usually same as synopsis.
.Notes
2017-10-26: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>


    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]]$NetAdapter,
        [String]$Logfile = "$PSScriptRoot\..\Logs\Restart-NIC.log"
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
        
        
        ForEach ($Adapter in $NetAdapter)
        {
            Restart-NetAdapter -Name $Adapter
            Log "Restarting Adapter $Adapter"
        }
        
    }

    End
    {
        Stop-Log  
    }
    
}

# Restart-NIC -NetAdapter "vEthernet (BridgedNet)", "Ethernet 5"

<#######</Body>#######>
<#######</Script>#######>