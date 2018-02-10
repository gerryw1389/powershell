<#######<Script>#######>
<#######<Header>#######>
# Name: Stop-VeeamReplications
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Stop-VeeamReplications
{
    <#
.Synopsis
Stops Veeam replication jobs using Veeam Backup and Recovery.
.DESCRIPTION
Stops Veeam replication jobs using Veeam Backup and Recovery. Usually set to run before backups have started.
.PARAMETER Jobs
Mandatory parameter that lists the jobs you would like to stop replications on.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.EXAMPLE
Stop-VeeamReplications -Jobs "DC1", "SQL", "WSUS"
Stops selected replication jobs.
.Notes
Requires the Veeam PSSnapin.
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>
    [CmdletBinding()]

    PARAM
    (
        [Parameter( Position = 0, Mandatory = $true)]
        [String[]]$Jobs,
        
        [String]$LogFile = "$PSScriptRoot\..\Logs\Stop-VeeamReplications.log"
    )

    Begin
    {
        
        #Enable the Veeam Powershell Snapin
        Add-PsSnapin VeeamPsSnapin
        
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log

       
    }
    
    Process
    {
        
    
        Foreach ($job in $jobs)
        {
            $CurrentJob = Get-VBRJob -name $job
            $CurrentJob | Disable-VBRJob
            If ($CurrentJob.IsScheduleEnabled -eq $True)
            {
                Log "FAILED to disable $job. Please take appropriate action." 
            }
            Else
            {
                Log "Successfully disabled $job" 
            } 
        }
    }
    End
    {
        Stop-Log  
    }

}

# Stop-VeeamReplications -Jobs "DC1", "DC2"

<#######</Body>#######>
<#######</Script>#######>