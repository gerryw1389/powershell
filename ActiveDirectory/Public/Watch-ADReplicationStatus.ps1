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
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
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
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    }


    Process
    {    
        
        
        
        $Result = Convertfrom-Csv -Inputobject (Repadmin.Exe /Showrepl * /Csv) | 
            Where-Object { $_.Showrepl_Columns -Ne 'Showrepl_Info'} | Out-String

        If ($Result -Ne "")
        {
            Send-Email $Result
            Log "Sending Email Due To Replication Issues!" 
        }
        Else
        {
            Log "No Replication Issues At This Time" 
        }
            
    }

    End
    {
        Stop-Log  
    }

} 

# Watch-ADReplicationStatus

<#######</Body>#######>
<#######</Script>#######>