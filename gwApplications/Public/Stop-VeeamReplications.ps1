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
    .EXAMPLE
    Stop-VeeamReplications -Jobs "DC1", "SQL", "WSUS"
    Stops selected replication jobs.
    .Notes
    Requires the Veeam PSSnapin.
    
    #>
    [CmdletBinding()]

    PARAM
    (
        [Parameter( Position = 0, Mandatory = $true)]
        [String[]]$Jobs
    )

    Begin
    {
        Add-PsSnapin VeeamPsSnapin
    }
    
    Process
    {
        Foreach ($job in $jobs)
        {
            $CurrentJob = Get-VBRJob -name $job
            $CurrentJob | Disable-VBRJob
            If ($CurrentJob.IsScheduleEnabled -eq $True)
            {
                Write-Output "FAILED to disable $job. Please take appropriate action."
            }
            Else
            {
                Write-Output "Successfully disabled $job"
            } 
        }
    }
    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>