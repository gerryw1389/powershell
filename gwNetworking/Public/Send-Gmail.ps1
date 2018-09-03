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
    .Example
    Send-Gmail
    Sends an email from one gmail account to another using powershell.
    #>

    [Cmdletbinding()]
    
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]$From,
        
        [Parameter(Position = 1, Mandatory = $True)]
        [String]$To,
        
        [String]$Subject,
        
        [String]$Body
    )
    
    Begin
    {   
    }
    
    Process
    {   
        $Subject = "Read this"
        $Body = "<HTML><HEAD><META http-equiv=""Content-Type"" content=""text/html; charset=iso-8859-1"" /><TITLE></TITLE></HEAD>"
        $Body += "<BODY bgcolor=""#FFFFFF"" style=""font-size: Small; font-family: TAHOMA; color: #000000""><P>"
        $Body += "Dear <b><font color=red>customer</b></font><br>"
        $Body += "This is an <b>HTML</b> email<br>"
        $Body += "Click <a href=http://www.google.com target=""_blank"">here</a> to open google <br>"
        $SMTPServer = "smtp.gmail.com"
        $SMTPPort = "587"
        #$Cc = ""
        #$Attachments = ""

        $Params = @{
            'From' = $From
            'To' = $To
            'Subject' = $Subject
            'Body' = $Body
            'BodyAsHTML' = $True
            'SmtpServer' = $SMTPServer
            'Port' = $SMTPPort
            'Credential' = (Get-Credential -Credential "$from")
            #'Cc' = $cc
            #'Attachments' = $Attachments
        }
        Send-MailMessage @Params -UseSsl
        Write-Output "Sent email $From to $To"
    }

    End
    {
    }

}

<#######</Body>#######>
<#######</Script>#######>