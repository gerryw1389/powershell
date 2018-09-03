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
    .Example
    Start-VeeamReplications -Jobs "DC1", "SQL", "WSUS"
    Starts Selected Replication Jobs.
    .Notes
    Requires the Veeam PSSnapin.
    #>

    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String[]]$Jobs
    )

    Begin
    {
       Add-Pssnapin Veeampssnapin
    }

    Process
    {
        Foreach ($Job In $Jobs)
        {
            $Currentjob = Get-Vbrjob -Name $Job | Enable-Vbrjob
            If ($Currentjob.Isscheduleenabled -Eq $True)
            {
                Write-Output "Successfully Started $Job"
            }
            Else
            {
                Write-Output "Failed To Enable $Job. Please Take Appropriate Action."
            }
        }
    }

    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>