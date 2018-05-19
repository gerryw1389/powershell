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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging..Example
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

        Write-Output "Sent email $From to $To" | TimeStamp
    
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

# Send-Gmail

<#######</Body>#######>
<#######</Script>#######>