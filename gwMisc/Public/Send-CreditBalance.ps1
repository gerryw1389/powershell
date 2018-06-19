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
    .Parameter Logfile
    Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
    NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
    .Example
    Send-CreditBalance
    Sends a text message of the daily credit balance.
    .Notes
    Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
    Main code usually starts around line 185ish.
    If -Verbose is not passed (Default) and logfile is not defined, don't show messages on the screen and don't transcript the session.
    If -Verbose is not passed (Default) and logfile is defined, enable verbose for them and transcript the session.
    If -Verbose is passed and logfile is defined, show messages on the screen and transcript the session.
    If -Verbose is passed and logfile is not defined, show messages on the screen, but don't transcript the session.
    2018-06-17: v1.1 Updated template.
    2017-09-08: v1.0 Initial script 
    #>

    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Send-CreditBalance.log"
    )
    
    Begin
    {   
        <#######<Default Begin Block>#######>
        Function Write-ToString
        {
            <# 
        .Synopsis
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Description
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Parameter InputObject
        This can be any PSObject that will be converted to string.
        .Parameter Color
        The color in which to display the string on the screen.
        Valid options are: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, 
        Red, White, and Yellow.
        .Example 
        Write-ToString "Hello Hello"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen and the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen in default text colors.
        .Example 
        Write-ToString "Hello Hello" -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow and to the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Example 
        Write-ToString (cmd /c "ipconfig /all") -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow that shows the computer's IP information.
        The same copy will be in the logfile. 
        The whole point of converting to strings is this works best with tables and such that usually distort in logfiles.
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Notes
        2018-06-13: v1.0 Initial function
        #>
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color
            )
            
            $ConvertToString = Out-String -InputObject $InputObject -Width 100
            
            If ($($Color.Length -gt 0))
            {
                $previousForegroundColor = $Host.PrivateData.VerboseForegroundColor
                $Host.PrivateData.VerboseForegroundColor = $Color
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                $Host.PrivateData.VerboseForegroundColor = $previousForegroundColor
            }
            Else
            {
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
            }
            
        }
        If ($($Logfile.Length) -gt 1)
        {
            $Global:EnabledLogging = $True 
            Set-Variable -Name Logfile -Value $Logfile -Scope Global
            $VerbosePreference = "Continue"
            Function Start-Log
            {
                <#
                .Synopsis
                Function to write the opening part of the logfile.
                .Description
                Function to write the opening part of the logfil.
                It creates the directory if it doesn't exists and then the log file automatically.
                It checks the size of the file if it already exists and clears it if it is over 10 MB.
                If it exists, it creates a header. This function is best placed in the "Begin" block of a script.
                .Notes
                NOTE: The function requires the Write-ToString function.
                2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                2017-10-19: v1.0 Initial function
                #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
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
                [Double]$Sizemax = 10485760
                $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
                If ($($Size.Sum -ge $SizeMax))
                {
                    Get-Childitem $Logfile | Clear-Content
                    Write-ToString "Logfile has been cleared due to size"
                }
                Else
                {
                    Write-ToString "Logfile was less than 10 MB"   
                }
                # Start writing to logfile
                Start-Transcript -Path $Logfile -Append 
                Write-ToString "####################<Script>####################"
                Write-ToString "Script Started on $env:COMPUTERNAME"
            }
            Start-Log -Logfile $Logfile -Verbose

            Function Stop-Log
            {
                <# 
                    .Synopsis
                    Function to write the closing part of the logfile.
                    .Description
                    Function to write the closing part of the logfile.
                    This function is best placed in the "End" block of a script.
                    .Notes
                    NOTE: The function requires the Write-ToString function.
                    2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                    2017-10-19: v1.0 Initial function 
                    #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
                Write-ToString "Script Completed on $env:COMPUTERNAME"
                Write-ToString "####################</Script>####################"
                Stop-Transcript
            }
        }
        Else
        {
            $Global:EnabledLogging = $False
        }
        <#######</Default Begin Block>#######>
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
        Write-ToString "Found $($messages.count) messages to go through"
    
        ForEach ($message in $messages)
        {
            $a = $($message.id)
            $b = Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a" + "?access_token=$accesstoken") -Method Get | ConvertFrom-Json
            # Find emails from bank
            Write-ToString "Message Subject : $($b.snippet)"
            Write-ToString "Seeing if this message matches the automated email we are looking for"
            If ($($b.snippet) -match "2800")
            {
                Write-ToString "Matched"
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
                Write-ToString "Amount extracted from email: $j"
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
                Write-ToString "Card: $l"
                Write-ToString "Amount to add to total: `$$k"
                [single]$Results += $k
                # Move to trash so it won't confuse the script for the next day
                Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken") -Method Post
            }
            Else
            {
                Write-ToString "Didn't match"
                $Counter += 0
            }
        }
        Write-ToString "Total charged: `$$Results"

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
        Write-ToString "Budget: `$$Budget"
        
        
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
            Write-ToString "Sent email $From to $To"
        
            # Send me a text message as well
            $From = "me1@gmail.com"
            $To = "8170000000@txt.att.net"
            $Subject = "Budget"
            $Body = "Budget before payday: `$$Budget"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Write-ToString "Sent text message $From to $To"
		
		
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
            Write-ToString "Sent email $From to $To"
		
            $From = "me1@gmail.com"
            $To = "8170000000@txt.att.net"
            $Subject = "WilliamsBudget"
            $Body = "Email didn't arrive"
            $SMTPServer = "smtp.gmail.com"
            $SMTPPort = "587"
            Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Creds
            Write-ToString "Sent text message $From to $To"
		
        }
    
    }

    End
    {
        # Section 5: Clean up
        # Get all emails and put them in the trash so that we don't have the same messages to go through tomorrow.
        $Request = Invoke-WebRequest -Uri "https://www.googleapis.com/gmail/v1/users/me/messages?access_token=$accesstoken" -Method Get | ConvertFrom-Json
        $messages = $($Request.messages)
        Write-ToString "Found $($messages.count) messages to delete"

        ForEach ($message in $messages)
        {
            $a = $($message.id)
            $b = Invoke-WebRequest -Uri ("https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken") -Method POST | ConvertFrom-Json
        }
		
        If ($Global:EnabledLogging)
        {
            Stop-Log -Logfile $Logfile
        }
        Else
        {
            $Date = $(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt")
            Write-Output "Function completed at $Date"
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>