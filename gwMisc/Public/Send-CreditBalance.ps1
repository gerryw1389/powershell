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

        # Generate all paydays for the year
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
    
        # Add in recurring bills.
        <#
    Bills: Day - Bill - Amount
    1 - Internet - $105
    14 - Hulu - $13
    16 - Water - $90
    16- ATT Cell - $45
		24- Netflix - $11
    27 - Electric - $166
    28 - Auto Ins - $176
    #>
    
        $DayofMonth = $($(Get-Date).Day)
        # Ignore Internet because it's already charged. Add Internet Streaming + Water bills until they are paid.
        If (($DayofMonth -ge 1) -And ($DayofMonth -le 13))
        {
            $ResultsWithBills = $Results + 103
            $UpcomingBills = '14 - Hulu - $13<br>'
            $UpcomingBills += '16 - Water - $90<br>'
        }
        # Bills should be paid by now, don't add anything
        If (($DayofMonth -ge 14) -And ($DayofMonth -le 15))
        {
            $ResultsWithBills = $Results
        }
        # Still have rest of the months bills coming, credit card should be paid off (hopefully)
        If (($DayofMonth -ge 16) -And ($DayofMonth -le 22))
        {
            $ResultsWithBills = $Results + 398
            $UpcomingBills = '16- ATT Cell - $45<br>'
            $UpcomingBills += '24- Netflix - $11<br>'
            $UpcomingBills += '27 - Electric - $166<br>'
            $UpcomingBills += '28 - Auto Ins. - $176'
        }
        # Take off Internet Streaming and Cell Phone from the balance
        If (($DayofMonth -ge 23) -And ($DayofMonth -le 26))
        {
            $ResultsWithBills = $Results + 342
            $UpcomingBills += '27 - Electric - $166<br>'
            $UpcomingBills += '28 - Auto Ins. - $176'
        }
        # Take off Electric
        If (($DayofMonth -ge 27) -And ($DayofMonth -le 28))
        {
            $ResultsWithBills = $Results + 176
            $UpcomingBills += '28 - Auto Ins. - $176'
        }
        # Finally, take off Auto Ins
        If (($DayofMonth -ge 28) -And ($DayofMonth -le 31))
        {
            $ResultsWithBills = $Results + 105
            $UpcomingBills = '1 - ATT Internet - $105'
        }

        $Budget = 1200 - $Results
        $RealisticBudget = 1200 - $ResultsWithBills
        Write-Output "Budget: `$$Budget" | Timestamp
        Write-Output "RealisticBudget: `$$RealisticBudget" | Timestamp
        ###########

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
            $Body += '<p style="color:#006400"><b>Budget before payday:</b></p>$' + $RealisticBudget + '<br><br>'
            $Body += '<p style="color:#006400"><b>Actual combined balance:</b></p>$' + $Results + '<br><br>'
            $Body += '<p style="color:#006400"><b>Budget (1200 - Combined balance):</b></p>$' + $Budget + '<br><br>'
            $Body += '<p style="color:#006400"><b>Upcoming Bills:</b></p><br>' + $UpcomingBills
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -BodyAsHTML -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Write-Output "Sent email $From to $To" | Timestamp
		
            $From = "me1@gmail.com"
            $To = "8170000000@txt.att.net"
            $Subject = "Budget"
            $Body = "Budget before payday: `$$RealisticBudget"
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
        # Get all emails and put them in the trash so that we don't have too many messages to go through tomorrow
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