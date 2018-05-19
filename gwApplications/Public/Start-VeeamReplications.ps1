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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
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
        Foreach ($Job In $Jobs)
        {
            $Currentjob = Get-Vbrjob -Name $Job | Enable-Vbrjob
            If ($Currentjob.Isscheduleenabled -Eq $True)
            {
                Write-Output "Successfully Started $Job" | TimeStamp
            }
            Else
            {
                Write-Output "Failed To Enable $Job. Please Take Appropriate Action." | TimeStamp
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

# Start-VeeamReplications -Jobs "DC1", "DC2"

<#######</Body>#######>
<#######</Script>#######>