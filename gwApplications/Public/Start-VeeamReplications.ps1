<#######<Script>#######>
<#######<Header>#######>
# Name: Start-VeeamReplications
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Start-VeeamReplications
{
    
    <#
.Synopsis
Start Veeam Replication Jobs Using Veeam Backup And Recovery.
.Description
Start Veeam Replication Jobs Using Veeam Backup And Recovery. Usually Set To Run After Backups Have Been Completed.
.PARAMETER Jobs
Mandatory parameter that lists the jobs you would like to start replications on.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Start-VeeamReplications -Jobs "DC1", "SQL", "WSUS"
Starts Selected Replication Jobs.
.Notes
Requires the Veeam PSSnapin.
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>

    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String[]]$Jobs,
        
        [String]$Logfile = "$PSScriptRoot\..\Logs\Start-VeeamReplications.Log"
    )

    Begin
    {

        #Enable The Veeam Powershell Snapin
        Add-Pssnapin Veeampssnapin

        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    }


    Process
    {
        
        
        Foreach ($Job In $Jobs)
        {
            $Currentjob = Get-Vbrjob -Name $Job | Enable-Vbrjob
            If ($Currentjob.Isscheduleenabled -Eq $True)
            {
                Log "Successfully Started $Job" 
            }
            Else
            {
                Log "Failed To Enable $Job. Please Take Appropriate Action." 
            }
        }
    }

    End
    {
        Stop-Log  
    }

}

# Start-VeeamReplications -Jobs "DC1", "DC2"

<#######</Body>#######>
<#######</Script>#######>