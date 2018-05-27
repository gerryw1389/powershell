<#######<Script>#######>
<#######<Header>#######>
# Name: Send-CreditBalance
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Send-CreditBalance
{
    <#
.Synopsis
Function to send credit card balance by text message daily based on email alerts from bank.
.Description
Function to send credit card balance by text message daily based on email alerts from bank.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Send-CreditBalance
Sends a text message of the daily credit balance.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Send-CreditBalance.log"
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

        # Section 1: Get the current balance of my credit cards from credit balance alerts sent to me from my bank daily

        # Please see https://www.gerrywilliams.net/2018/01/using-powershell-to-access-gmail-api/ on how to do this section
        # Note this is made up - you will need to generate your own!
        # Get Access Token
        $clientId = "883355712819-sfasdfasdfapps.googleusercontent.com"; 
        $secret = "fOjIP3IQnfqX4asdasdf";
        $redirectURI = "urn:ietf:wg:oauth:2.0:oob";
        $refreshToken = "1/nclSRpl4oFD1o_adsfGHeyvrT2DMGYeMZ_IbJ3f8";
        $refreshTokenParams = @{
            client_id     = $clientId;
            client_secret = $secret;
            refresh_token = $refreshToken;
            grant_type    = 'refresh_token';
        }
        $refreshedToken = Invoke-WebRequest -Uri "https://accounts.google.com/o/oauth2/token" -Method POST -Body $refreshTokenParams | ConvertFrom-Json
        $accesstoken = $refreshedToken.access_token
    
        # Initialize counter variables
        $Results = 0
        # Create a counter variable that if, equals 0, means no emails matched.
        $Counter = 0
    
        # Get all emails
        $Request = Invoke-WebRequest -Uri "https://www.googleapis.com/gmail/v1/users/me/messages?access_token=$accesstoken" -Method Get | ConvertFrom-Json
        $messages = $($Request.messages)
        Write-Output "Found $($messages.count) messages to go through" | Timestamp
    
        ForEach ($message in $messages)
        {
            $a = $($message.id)
            $b = Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a" + "?access_token=$accesstoken") -Method Get | ConvertFrom-Json
            # Find emails from bank
            Write-Output "Message Subject : $($b.snippet)" | Timestamp
            Write-Output "Seeing if this message matches the automated email we are looking for" | Timestamp
            If ($($b.snippet) -match "2800")
            {
                Write-Output "Matched" | Timestamp
                # Increment counter for email sending at the bottom
                $Counter += 1
                # Gets the Base64 message and decrypts it
                $c = $b.payload.parts.body.data[0]
                $d = $c.Replace('-', '+').Replace('_', '/')
                [String]$e = [System.Text.Encoding]::Ascii.GetString([System.Convert]::FromBase64String($d))
    
                #Places decrypted email in a single block of text. Searches for the balance and places in a variable.
                $f = $e -Replace '\s', ''
                $g = $f.IndexOf('$')
                $h = $f.Substring($g, 11)
                $i = $h -match '\$(.*)[V]'
                $j = $matches[1] -as [single]
                Write-Output "Amount extracted from email: $j" | Timestamp
                If ($f -match "7585")
                {
                    $k = 10500 - $j
                    $l = "Purchasing CC"
                }
                Else
                {
                    $k = 4500 - $j
                    $l = "Bills CC"
                }
                $matches = $null
                Write-Output "Card: $l" | Timestamp
                Write-Output "Amount to add to total: `$$k" | Timestamp
                [single]$Results += $k
                # Move to trash so it won't confuse the script for the next day
                Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken") -Method Post
            }
            Else
            {
                Write-Output "Didn't match" | Timestamp
                $Counter += 0
            }
        }
        Write-Output "Total charged: `$$Results" | Timestamp

        # Section 2: Generate all paydays for the year
        [DateTime] $StartDate = "2018-01-05"
        [Int]$DaysToSkip = 14
        [DateTime]$EndDate = "2018-12-31"
        $Arr = @()
        while ($StartDate -le $EndDate) 
        {
            $Arr += $StartDate 
            $StartDate = $StartDate.AddDays($DaysToSkip)
        }

        # Remove all paydays less than today and place in new array
        $NewArr = @()
        ForEach ($Ar in $Arr)
        {
            $s = (Get-Date)
            $e = $Ar
            $Difference = New-TimeSpan -Start $s -End $e
            If ( $Difference -ge 1)
            {
                $NewArr += $Ar
            }
        }

        # Select the first one
        $ClosestPayday = $NewArr[0].ToString("yyyy-MM-dd")

        # Calculate how many days from now until payday
        $Span = New-TimeSpan -Start (Get-Date) -End $NewArr[0]

        # Round up one because there is always a whole number and some change
        $DaysTilPayday = ($Span.Days + 1).ToString()
    
        # Section 3: Add in recurring bills. See https://www.gerrywilliams.net/2018/02/ps-send-me-my-credit-balance/ for a description.
        $DayofMonth = $($(Get-Date).Day)

        If ($DayofMonth -eq 5)
        {
            $ResultsWithBills = $Results + 1421
            $UpcomingBills = '6 - Groceries - $200<br>'
            $UpcomingBills += '13 - Groceries - $200<br>'
            $UpcomingBills += '14 - Hulu - $13<br>'
            $UpcomingBills += '16 - Water - $90<br>'
            $UpcomingBills += '16 - ATT Cell - $45<br>'
            $UpcomingBills += '20 - Groceries - $200<br>'
            $UpcomingBills += '24 - Netflix - $11<br>'
            $UpcomingBills += '27 - Electric - $166<br>'
            $UpcomingBills += '27 - Plex - $15<br>'
            $UpcomingBills += '27 - Groceries - $200<br>'
            $UpcomingBills += '28 - Auto Ins. - $176<br>'
            $UpcomingBills += '1 - Internet - $105<br>'
        }

        ElseIf (($DayofMonth -ge 6) -And ($DayofMonth -le 12))
        {
            $ResultsWithBills = $Results + 1221
            $UpcomingBills = '13 - Groceries - $200<br>'
            $UpcomingBills += '14 - Hulu - $13<br>'
            $UpcomingBills += '16 - Water - $90<br>'
            $UpcomingBills += '16 - ATT Cell - $45<br>'
            $UpcomingBills += '20 - Groceries - $200<br>'
            $UpcomingBills += '24 - Netflix - $11<br>'
            $UpcomingBills += '27 - Electric - $166<br>'
            $UpcomingBills += '27 - Plex - $15<br>'
            $UpcomingBills += '27 - Groceries - $200<br>'
            $UpcomingBills += '28 - Auto Ins. - $176<br>'
            $UpcomingBills += '1 - Internet - $105<br>'
        }

        ElseIf ($DayofMonth -eq 13)
        {
            $ResultsWithBills = $Results + 1021
            $UpcomingBills = '14 - Hulu - $13<br>'
            $UpcomingBills += '16 - Water - $90<br>'
            $UpcomingBills += '16 - ATT Cell - $45<br>'
            $UpcomingBills += '20 - Groceries - $200<br>'
            $UpcomingBills += '24 - Netflix - $11<br>'
            $UpcomingBills += '27 - Electric - $166<br>'
            $UpcomingBills += '27 - Plex - $15<br>'
            $UpcomingBills += '27 - Groceries - $200<br>'
            $UpcomingBills += '28 - Auto Ins. - $176<br>'
            $UpcomingBills += '1 - Internet - $105<br>'
        }

        ElseIf (($DayofMonth -ge 14) -And ($DayofMonth -le 15))
        {
            $ResultsWithBills = $Results + 1008
            $UpcomingBills = '16 - Water - $90<br>'
            $UpcomingBills += '16 - ATT Cell - $45<br>'
            $UpcomingBills += '20 - Groceries - $200<br>'
            $UpcomingBills += '24 - Netflix - $11<br>'
            $UpcomingBills += '27 - Electric - $166<br>'
            $UpcomingBills += '27 - Plex - $15<br>'
            $UpcomingBills += '27 - Groceries - $200<br>'
            $UpcomingBills += '28 - Auto Ins. - $176<br>'
            $UpcomingBills += '1 - Internet - $105<br>'
        }

        ElseIf (($DayofMonth -ge 20) -And ($DayofMonth -le 23))
        {
            $ResultsWithBills = $Results + 673
            $UpcomingBills = '24 - Netflix - $11<br>'
            $UpcomingBills += '27 - Electric - $166<br>'
            $UpcomingBills += '27 - Plex - $15<br>'
            $UpcomingBills += '27 - Groceries - $200<br>'
            $UpcomingBills += '28 - Auto Ins. - $176<br>'
            $UpcomingBills += '1 - Internet - $105<br>'
        }

        ElseIf (($DayofMonth -ge 24) -And ($DayofMonth -le 26))
        {
            $ResultsWithBills = $Results + 662
            $UpcomingBills = '27 - Electric - $166<br>'
            $UpcomingBills += '27 - Plex - $15<br>'
            $UpcomingBills += '27 - Groceries - $200<br>'
            $UpcomingBills += '28 - Auto Ins. - $176<br>'
            $UpcomingBills += '1 - Internet - $105<br>'
        }

        ElseIf ($DayofMonth -eq 27)
        {
            $ResultsWithBills = $Results + 281
            $UpcomingBills = '28 - Auto Ins. - $176<br>'
            $UpcomingBills += '1 - Internet - $105<br>'
        }

        Elseif (($DayofMonth -ge 28) -And ($DayofMonth -le 31))
        {
            $ResultsWithBills = $Results + 105
            $UpcomingBills = '1 - Internet - $105<br>'
        }

        Elseif (($DayofMonth -ge 1) -And ($DayofMonth -le 4))
        {
            $ResultsWithBills = $Results
        }

        # If nothing matches (which it should seeing as there is always 1-31 days in a month), just add nothing to the balance.
        Else
        {
            $ResultsWithBills = $Results
        }

        $Budget = 2400 - $ResultsWithBills
        Write-Output "Budget: `$$Budget" | TimeStamp
        
        
        # Section 4: Send email with all these results 
        # Build creds
        $User = "me@gmail.com"
        # $PasswordFile = "$Psscriptroot\AESpassword.txt"
        # $KeyFile = "$Psscriptroot\aes.key"
        # $Key = Get-Content $KeyFile
        # $Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $Key)

        # Send to emails
    
        If ($Counter -ge 1)
        {
            $From = "me1@gmail.com"
            $To = "me2@gmail.com"
            $Subject = "Daily Budget Automated Task"
            $Body = '<p style="color:#006400"><b>Next payday:</b></p>' + $ClosestPayday + '<br><br>'
            $Body += '<p style="color:#006400"><b>Days until payday</b></p>' + $DaysTilPayday + '<br><br>'
            $Body += '<p style="color:#006400"><b>Budget before payday:</b></p>$' + $Budget + '<br><br>'
            $Body += '<p style="color:#006400"><b>Actual combined balance:</b></p>$' + $Results + '<br><br>'
            $Body += '<p style="color:#006400"><b>Upcoming Bills:</b></p><br>' + $UpcomingBills
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -BodyAsHTML -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Write-Output "Sent email $From to $To" | TimeStamp
        
            # Send me a text message as well
            $From = "me1@gmail.com"
            $To = "8170000000@txt.att.net"
            $Subject = "Budget"
            $Body = "Budget before payday: `$$Budget"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Write-Output "Sent text message $From to $To" | Timestamp
		
		
        }
        Else
        {
            $From = "me1@gmail.com"
            $To = "me2@gmail.com"
            $Subject = "Daily Budget Automated Task"
            $Body = "Email didn't arrive"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Write-Output "Sent email $From to $To" | Timestamp
		
            $From = "me1@gmail.com"
            $To = "8170000000@txt.att.net"
            $Subject = "WilliamsBudget"
            $Body = "Email didn't arrive"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Write-Output "Sent text message $From to $To" | Timestamp
		
        }
    
    }

    End
    {
        # Section 5: Clean up
        # Get all emails and put them in the trash so that we don't have the same messages to go through tomorrow.
        $Request = Invoke-WebRequest -Uri "https://www.googleapis.com/gmail/v1/users/me/messages?access_token=$accesstoken" -Method Get | ConvertFrom-Json
        $messages = $($Request.messages)
        Write-Output "Found $($messages.count) messages to delete" | Timestamp

        ForEach ($message in $messages)
        {
            $a = $($message.id)
            $b = Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken") -Method POST | ConvertFrom-Json
        }
		
        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>