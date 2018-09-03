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
    This function is best placed a scheduled task to run every 5 minutes on the domain controller. 
    It will send an email if replication status fails.
    .Description
    This function is best placed a scheduled task to run every 5 minutes on the domain controller. 
    It will send an email if replication status fails.
    You will need to setup the "from address, to address, smtp server, $logfile" variables.
    .Example
    Watch-ADReplicationStatus
    Sends a report to the email you if replication status fails.
    #>
 
    [Cmdletbinding()]

    Param
    (
        
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

    }

    Process
    {    
        $Result = Convertfrom-Csv -Inputobject (repadmin.exe /showrepl * /csv) | 
            Where-Object { $_.Showrepl_Columns -Ne 'Showrepl_Info'} | Out-String

        If ($Result -Ne "")
        {
            Send-Email $Result
            Write-Output "Sending Email Due To Replication Issues!"
        }
        Else
        {
            Write-Output "No Replication Issues At This Time"
        }
    
    }

    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>