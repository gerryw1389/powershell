<#######<Script>#######>
<#######<Header>#######>
# Name: Send-Gmail
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Send-Gmail
{
    <#
.Synopsis
Sends an email from one gmail account to another using powershell.
.Description
Sends an email from one gmail account to another using powershell. Make sure to edit the $Body and enter the email password in the credential pop up.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/

.Example
Send-Gmail
Sends an email from one gmail account to another using powershell.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Send-Gmail.log"
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
        $From = "from@gmail.com"
        $To = "to@gmail.com"
        $Subject = "Read this"
        $Body = "<HTML><HEAD><META http-equiv=""Content-Type"" content=""text/html; charset=iso-8859-1"" /><TITLE></TITLE></HEAD>"
        $Body += "<BODY bgcolor=""#FFFFFF"" style=""font-size: Small; font-family: TAHOMA; color: #000000""><P>"
        $Body += "Dear <b><font color=red>customer</b></font><br>"
        $Body += "This is an <b>HTML</b> email<br>"
        $Body += "Click <a href=http://www.google.com target=""_blank"">here</a> to open google <br>"
        $SMTPServer = "smtp.gmail.com"
        $SMTPPort = "587"
        # $Cc = "YourBoss@YourDomain.com"
        # $Attachment = "C:\temp\Some random file.txt"

        # Optionally include:
        # -Attachments $Attachment
        # -Cc $Cc

        Send-MailMessage -From $From -to $To -Subject $Subject `
            -BodyAsHTML -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `
            -Credential (Get-Credential -Credential "from@gmail.com")

        Log "Sent email $From to $To"    
    
    }

    End
    {
        Stop-Log  
    }

}

# Send-Gmail

<#######</Body>#######>
<#######</Script>#######>