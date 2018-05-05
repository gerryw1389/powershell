<#######<Script>#######>
<#######<Header>#######>
# Name: Watch-ADReplicationStatus
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Watch-ADReplicationStatus
{
    <#
.Synopsis
This Function Is Best Placed A Scheduled Task To Run Every 5 Minutes On The Domain Controller. 
It Will Send An Email If Replication Status Fails.
.Description
This Function Is Best Placed A Scheduled Task To Run Every 5 Minutes On The Domain Controller. 
It Will Send An Email If Replication Status Fails.
You Will Need To Setup The "From Address, To Address, Smtp Server, $Logfile" Variables.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Watch-ADReplicationStatus
Sends A Report To The Email You If Replication Status Fails.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>
 
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Watch-ADReplicationStatus.Log"
    )

    Begin
    {
        Function Send-Email ([String] $Body)
        {
            $Mailmessage = New-Object System.Net.Mail.Mailmessage
            $Mailmessage.From = "Email@Domain.Com"
            $Mailmessage.To.Add("Administrator@Domain.Com")
            $Mailmessage.Subject = "Ad Replication Error!"
            $Mailmessage.Body = $Body
            $Mailmessage.Priority = "High"
            $Mailmessage.Isbodyhtml = $False
            $Smtpclient = New-Object System.Net.Mail.Smtpclient
            $Smtpclient.Host = "Smtp.Server.Int"
            $Smtpclient.Send($Mailmessage)
        }

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
        $Result = Convertfrom-Csv -Inputobject (Repadmin.Exe /Showrepl * /Csv) | 
            Where-Object { $_.Showrepl_Columns -Ne 'Showrepl_Info'} | Out-String

        If ($Result -Ne "")
        {
            Send-Email $Result
            Write-Output "Sending Email Due To Replication Issues!" | TimeStamp
        }
        Else
        {
            Write-Output "No Replication Issues At This Time" | TimeStamp
        }
    
    }

    End
    {
        If ($EnableLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

} 

# Watch-ADReplicationStatus

<#######</Body>#######>
<#######</Script>#######>