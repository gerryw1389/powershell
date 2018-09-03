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
    See https://www.gerrywilliams.net/2018/02/ps-send-me-my-credit-balance/ to see an overview.
    Line(s) you will need to edit:
    194 - Client ID - See https://www.gerrywilliams.net/2018/01/using-powershell-to-access-gmail-api/
    195 - Secret - See https://www.gerrywilliams.net/2018/01/using-powershell-to-access-gmail-api/
    197 - Refresh Token - See https://www.gerrywilliams.net/2018/01/using-powershell-to-access-gmail-api/
    224 - If your bank includes the last four of your Credit Card, enter it here.
    234 - 254 - This is parsing the email exactly because my bank always sends a template with just the amount that changes, YMMV.
    464 - Edit your gmail credentials
    473-517 - Edit your email / phone info. I'm not breaking this down because it's pretty self explanatory.
    .Example
    Send-CreditBalance
    Sends a text message of the daily credit balance.
    #>

    [Cmdletbinding()]
    
    Param
    (
    )
    
    Begin
    {   
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
        Write-Output "Found $($messages.count) messages to go through"
    
        ForEach ($message in $messages)
        {
            $a = $($message.id)
            $b = Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a" + "?access_token=$accesstoken") -Method Get | ConvertFrom-Json
            # Find emails from bank
            Write-Output "Message Subject : $($b.snippet)"
            Write-Output "Seeing if this message matches the automated email we are looking for"
            If ($($b.snippet) -match "2800")
            {
                Write-Output "Matched"
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
                Write-Output "Amount extracted from email: $j"
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
                Write-Output "Card: $l"
                Write-Output "Amount to add to total: `$$k"
                [single]$Results += $k
                # Move to trash so it won't confuse the script for the next day
                Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken") -Method Post
            }
            Else
            {
                Write-Output "Didn't match"
                $Counter += 0
            }
        }
        Write-Output "Total charged: `$$Results"

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

        <#
        My new version just pays the bills on the fifth each month so the paydays are irrelevant:
        # Get the number of days until the fifth
        [int]$ThisFifth = ((Get-Date -Day 5).Date - (Get-Date)).Days
        [int]$NextFifth = ((Get-Date -Day 5).AddMonths(1).Date - (Get-Date)).Days
        If ($ThisFifth -ge 0)
        {
            # Prevent it from sending 1 on the actual fifth
            If ($ThisFifth -eq 0)
            {
                $DaysTilPayday = 0
            }
            Else
            {
                $DaysTilPayday = $($ThisFifth + 1)
            }
        }
        Else
        {
            $DaysTilPayday = $($NextFifth + 1 )
        }
        
        #>
    
        # Section 3: Add in recurring bills. See https://www.gerrywilliams.net/2018/02/ps-send-me-my-credit-balance/ for a description.
        $DayofMonth = $($(Get-Date).Day)
        $UpcomingBills = [System.Collections.ArrayList]@()
        # Credit cards paid off monthly on the fifth and next bill isn't until 6th, so no charge here.
        If ($DayofMonth -eq 5)
        {
            # For this one exception, don't worry about the parsed email amount, it doesn't matter as it will be paid today.
            $Results = 0
            # This means the budget will always be $979 on the fifth ($2400 - $1421 for bills below)
            $ResultsWithBills = $Results + 1421
            [void]$UpcomingBills.Add('6 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('13 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('14 - Hulu - $13<br>')
            [void]$UpcomingBills.Add('16 - Water - $90<br>')
            [void]$UpcomingBills.Add('16 - ATT Cell - $45<br>')
            [void]$UpcomingBills.Add('20 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('24 - Netflix - $11<br>')
            [void]$UpcomingBills.Add('27 - Electric - $166<br>')
            [void]$UpcomingBills.Add('27 - Plex - $15<br>')
            [void]$UpcomingBills.Add('27 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('28 - Auto Ins. - $176<br>')
            [void]$UpcomingBills.Add('1 - Internet - $105<br>')
            [void]$UpcomingBills.Add('Total: 1421<br>')
        }

        ElseIf (($DayofMonth -ge 6) -And ($DayofMonth -le 12))
        {
            $ResultsWithBills = $Results + 1221
            [void]$UpcomingBills.Add('13 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('14 - Hulu - $13<br>')
            [void]$UpcomingBills.Add('16 - Water - $90<br>')
            [void]$UpcomingBills.Add('16 - ATT Cell - $45<br>')
            [void]$UpcomingBills.Add('20 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('24 - Netflix - $11<br>')
            [void]$UpcomingBills.Add('27 - Electric - $166<br>')
            [void]$UpcomingBills.Add('27 - Plex - $15<br>')
            [void]$UpcomingBills.Add('27 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('28 - Auto Ins. - $176<br>')
            [void]$UpcomingBills.Add('1 - Internet - $105<br>')
            [void]$UpcomingBills.Add('Total: 1221<br>')
        }
        
        ElseIf ($DayofMonth -eq 13)
        {
            $ResultsWithBills = $Results + 1021
            [void]$UpcomingBills.Add('14 - Hulu - $13<br>')
            [void]$UpcomingBills.Add('16 - Water - $90<br>')
            [void]$UpcomingBills.Add('16 - ATT Cell - $45<br>')
            [void]$UpcomingBills.Add('20 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('24 - Netflix - $11<br>')
            [void]$UpcomingBills.Add('27 - Electric - $166<br>')
            [void]$UpcomingBills.Add('27 - Plex - $15<br>')
            [void]$UpcomingBills.Add('27 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('28 - Auto Ins. - $176<br>')
            [void]$UpcomingBills.Add('1 - Internet - $105<br>')
            [void]$UpcomingBills.Add('Total: 1021<br>')
        }
        
        ElseIf (($DayofMonth -ge 14) -And ($DayofMonth -le 15))
        {
            $ResultsWithBills = $Results + 1008
            [void]$UpcomingBills.Add('16 - Water - $90<br>')
            [void]$UpcomingBills.Add('16 - ATT Cell - $45<br>')
            [void]$UpcomingBills.Add('20 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('24 - Netflix - $11<br>')
            [void]$UpcomingBills.Add('27 - Electric - $166<br>')
            [void]$UpcomingBills.Add('27 - Plex - $15<br>')
            [void]$UpcomingBills.Add('27 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('28 - Auto Ins. - $176<br>')
            [void]$UpcomingBills.Add('1 - Internet - $105<br>')
            [void]$UpcomingBills.Add('Total: 1008<br>')
        }

        ElseIf (($DayofMonth -ge 16) -And ($DayofMonth -le 19))
        {
            $ResultsWithBills = $Results + 873
            [void]$UpcomingBills.Add('20 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('24 - Netflix - $11<br>')
            [void]$UpcomingBills.Add('27 - Electric - $166<br>')
            [void]$UpcomingBills.Add('27 - Plex - $15<br>')
            [void]$UpcomingBills.Add('27 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('28 - Auto Ins. - $176<br>')
            [void]$UpcomingBills.Add('1 - Internet - $105<br>')
            [void]$UpcomingBills.Add('Total: 873<br>')
        }

        ElseIf (($DayofMonth -ge 20) -And ($DayofMonth -le 23))
        {
            $ResultsWithBills = $Results + 673
            [void]$UpcomingBills.Add('24 - Netflix - $11<br>')
            [void]$UpcomingBills.Add('27 - Electric - $166<br>')
            [void]$UpcomingBills.Add('27 - Plex - $15<br>')
            [void]$UpcomingBills.Add('27 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('28 - Auto Ins. - $176<br>')
            [void]$UpcomingBills.Add('1 - Internet - $105<br>')
            [void]$UpcomingBills.Add('Total: 673<br>')
        }

        ElseIf (($DayofMonth -ge 24) -And ($DayofMonth -le 26))
        {
            $ResultsWithBills = $Results + 662
            [void]$UpcomingBills.Add('27 - Electric - $166<br>')
            [void]$UpcomingBills.Add('27 - Plex - $15<br>')
            [void]$UpcomingBills.Add('27 - Groceries - $200<br>')
            [void]$UpcomingBills.Add('28 - Auto Ins. - $176<br>')
            [void]$UpcomingBills.Add('1 - Internet - $105<br>')
            [void]$UpcomingBills.Add('Total: 662<br>')
        }

        ElseIf ($DayofMonth -eq 27)
        {
            $ResultsWithBills = $Results + 281
            [void]$UpcomingBills.Add('28 - Auto Ins. - $176<br>')
            [void]$UpcomingBills.Add('1 - Internet - $105<br>')
            [void]$UpcomingBills.Add('Total: 281<br>')
        }

        Elseif (($DayofMonth -ge 28) -And ($DayofMonth -le 31))
        {
            $ResultsWithBills = $Results + 105
            [void]$UpcomingBills.Add('1 - Internet - $105<br>')
            [void]$UpcomingBills.Add('Total: 105<br>')
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
        Write-Output "Budget: `$$Budget"
        
        
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
            Write-Output "Sent email $From to $To"
        
            # Send me a text message as well
            $From = "me1@gmail.com"
            $To = "8170000000@txt.att.net"
            $Subject = "Budget"
            $Body = "Budget before payday: `$$Budget"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Write-Output "Sent text message $From to $To"
		
		
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
            Write-Output "Sent email $From to $To"
		
            $From = "me1@gmail.com"
            $To = "8170000000@txt.att.net"
            $Subject = "WilliamsBudget"
            $Body = "Email didn't arrive"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Write-Output "Sent text message $From to $To"
		
        }
    
    }

    End
    {
        # Section 5: Clean up
        # Get all emails and put them in the trash so that we don't have the same messages to go through tomorrow.
        $Request = Invoke-WebRequest -Uri "https://www.googleapis.com/gmail/v1/users/me/messages?access_token=$accesstoken" -Method Get | ConvertFrom-Json
        $messages = $($Request.messages)
        Write-Output "Found $($messages.count) messages to delete"

        ForEach ($message in $messages)
        {
            $a = $($message.id)
            $b = Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken") -Method POST | ConvertFrom-Json
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>