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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
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
        If ($($Logfile.Length) -gt 1)
        {
            $EnabledLogging = $True
        }
        Else
        {
            $EnabledLogging = $False
        }
    
        Filter Timestamp
        {
            "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $_"
        }

        If ($EnabledLogging)
        {
            # Create parent path and logfile if it doesn't exist
            $Regex = '([^\\]*)$'
            $Logparent = $Logfile -Replace $Regex
            If (!(Test-Path $Logparent))
            {
                New-Item -Itemtype Directory -Path $Logparent -Force | Out-Null
            }
            If (!(Test-Path $Logfile))
            {
                New-Item -Itemtype File -Path $Logfile -Force | Out-Null
            }
    
            # Clear it if it is over 10 MB
            $Sizemax = 10
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            $Sizemb = "{0:N2}" -F ($Size.Sum / 1mb) + "Mb"
            If ($Sizemb -Ge $Sizemax)
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            # Start writing to logfile
            Start-Transcript -Path $Logfile -Append 
            Write-Output "####################<Script>####################"
            Write-Output "Script Started on $env:COMPUTERNAME" | TimeStamp
        }

    }
    
    Process
    {
        Foreach ($job in $jobs)
        {
            $CurrentJob = Get-VBRJob -name $job
            $CurrentJob | Disable-VBRJob
            If ($CurrentJob.IsScheduleEnabled -eq $True)
            {
                Write-Output "FAILED to disable $job. Please take appropriate action." | TimeStamp
            }
            Else
            {
                Write-Output "Successfully disabled $job" | TimeStamp
            } 
        }
    }
    End
    {
        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

# Stop-VeeamReplications -Jobs "DC1", "DC2"

<#######</Body>#######>
<#######</Script>#######>