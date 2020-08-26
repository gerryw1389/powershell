<#######<Script>#######>
<#######<Header>#######>
# Name: Send-CreditBalance
# Copyright: Gerry Williams (https://automationadmin.com)
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
    194 - Client ID
    195 - Secret
    197 - Refresh Token
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
      ####################<Default Begin Block>####################
      # Force verbose because Write-Output doesn't look well in transcript files
      $VerbosePreference = "Continue"
        
      [String]$Logfile = $PSScriptRoot + '\PSLogs\' + (Get-Date -Format "yyyy-MM-dd") +
      "-" + $MyInvocation.MyCommand.Name + ".log"
        
      Function Write-Log
      {
         <#
            .Synopsis
            This writes objects to the logfile and to the screen with optional coloring.
            .Parameter InputObject
            This can be text or an object. The function will convert it to a string and verbose it out.
            Since the main function forces verbose output, everything passed here will be displayed on the screen and to the logfile.
            .Parameter Color
            Optional coloring of the input object.
            .Example
            Write-Log "hello" -Color "yellow"
            Will write the string "VERBOSE: YYYY-MM-DD HH: Hello" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Example
            Write-Log (cmd /c "ipconfig /all")
            Will write the string "VERBOSE: YYYY-MM-DD HH: ****ipconfig output***" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Notes
            2018-06-24: Initial script
            #>
            
         Param
         (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
            [PSObject]$InputObject,
                
            # I usually set this to = "Green" since I use a black and green theme console
            [Parameter(Mandatory = $False, Position = 1)]
            [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                  "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
            [String]$Color = "Green"
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

      Function Start-Log
      {
         <#
            .Synopsis
            Creates the log file and starts transcribing the session.
            .Notes
            2018-06-24: Initial script
            #>
            
         # Create transcript file if it doesn't exist
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
            Write-Verbose "Logfile has been cleared due to size"
         }
         Else
         {
            Write-Verbose "Logfile was less than 10 MB"   
         }
         Start-Transcript -Path $Logfile -Append 
         Write-Log "####################<Function>####################"
         Write-Log "Function started on $env:COMPUTERNAME"

      }
        
      Function Stop-Log
      {
         <#
            .Synopsis
            Stops transcribing the session and cleans the transcript file by removing the fluff.
            .Notes
            2018-06-24: Initial script
            #>
            
         Write-Log "Function completed on $env:COMPUTERNAME"
         Write-Log "####################</Function>####################"
         Stop-Transcript
       
         # Now we will clean up the transcript file as it contains filler info that needs to be removed...
         $Transcript = Get-Content $Logfile -raw

         # Create a tempfile
         $TempFile = $PSScriptRoot + "\PSLogs\temp.txt"
         New-Item -Path $TempFile -ItemType File | Out-Null
			
         # Get all the matches for PS Headers and dump to a file
         $Transcript | 
         Select-String '(?smi)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*([\S\s]*?)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*' -AllMatches | 
         ForEach-Object { $_.Matches } | 
         ForEach-Object { $_.Value } | 
         Out-File -FilePath $TempFile -Append

         # Compare the two and put the differences in a third file
         $m1 = Get-Content -Path $Logfile
         $m2 = Get-Content -Path $TempFile
         $all = Compare-Object -ReferenceObject $m1 -DifferenceObject $m2 | Where-Object -Property Sideindicator -eq '<='
         $Array = [System.Collections.Generic.List[PSObject]]@()
         foreach ($a in $all)
         {
            [void]$Array.Add($($a.InputObject))
         }
         $Array = $Array -replace 'VERBOSE: ', ''

         Remove-Item -Path $Logfile -Force
         Remove-Item -Path $TempFile -Force
         # Finally, put the information we care about in the original file and discard the rest.
         $Array | Out-File $Logfile -Append -Encoding ASCII
            
      }
        
      Start-Log

      Function Set-Console
      {
         <# 
        .Synopsis
        Function to set console colors just for the session.
        .Description
        Function to set console colors just for the session.
        This function sets background to black and foreground to green.
        Verbose is DarkCyan which is what I use often with logging in scripts.
        I mainly did this because darkgreen does not look too good on blue (Powershell defaults).
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
        
         Function Test-IsAdmin
         {
            <#
                .Synopsis
                Determines whether or not the user is a member of the local Administrators security group.
                .Outputs
                System.Bool
                #>

            [CmdletBinding()]
    
            $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $Principal = new-object System.Security.Principal.WindowsPrincipal(${Identity})
            $IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            Write-Output -InputObject $IsAdmin
         }

         $console = $host.UI.RawUI
         If (Test-IsAdmin)
         {
            $console.WindowTitle = "Administrator: Powershell"
         }
         Else
         {
            $console.WindowTitle = "Powershell"
         }
         $Background = "Black"
         $Foreground = "Green"
         $Messages = "DarkCyan"
         $Host.UI.RawUI.BackgroundColor = $Background
         $Host.UI.RawUI.ForegroundColor = $Foreground
         $Host.PrivateData.ErrorForegroundColor = $Messages
         $Host.PrivateData.ErrorBackgroundColor = $Background
         $Host.PrivateData.WarningForegroundColor = $Messages
         $Host.PrivateData.WarningBackgroundColor = $Background
         $Host.PrivateData.DebugForegroundColor = $Messages
         $Host.PrivateData.DebugBackgroundColor = $Background
         $Host.PrivateData.VerboseForegroundColor = $Messages
         $Host.PrivateData.VerboseBackgroundColor = $Background
         $Host.PrivateData.ProgressForegroundColor = $Messages
         $Host.PrivateData.ProgressBackgroundColor = $Background
         Clear-Host
      }
      Set-Console

      ####################</Default Begin Block>####################

           
   }
    
   Process
   {   
      
      # Section 1: Get the current balance of my credit cards from credit balance alerts sent to me from my bank daily

      # Please see https://automationadmin.com/2018/01/using-powershell-to-access-gmail-api/ on how to do this section
      
      #############################
      # Sensitive Info - Get these from keyfile, Azure Key Vault, ect.
      # https://automationadmin.com/2016/05/using-passwords-with-powershell/
      $clientId = "312628475357-m60affgncf6n6metjv42tf5qkbhipuu5.apps.googleusercontent.com"
      $clientSecret = "RRQuq0rPDzUUGWjbn2s983ak"
      $refreshToken = '1//04dniS7-UZUZoCgYIARAAGAQSNQF-L9Ir-7hmXdf_HVhCOf4iEMisleNs6N2eZ8KpbgiImODrDd6uMu4qGmrN4GdT9DXqtu2S'

      # Creds for sending email
      $username = "me@gmail.com"
      $password = "hunter2"
      $pw = ConvertTo-SecureString -String $password -AsPlainText -Force
      $Creds= New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $username, $pw
      #############################
      
      $headers = @{ 
         "Content-Type" = "application/x-www-form-urlencoded" 
      } 
      $body = @{
         client_id     = $clientId
         client_secret = $clientSecret
         refresh_token = $refreshToken
         grant_type    = 'refresh_token'
      }
      $params = @{
         'Uri'         = 'https://accounts.google.com/o/oauth2/token'
         'ContentType' = 'application/x-www-form-urlencoded'
         'Method'      = 'POST'
         'Headers'     = $headers
         'Body'        = $body
         'Verbose'     = $true
      }
      $accessTokenResponse = Invoke-RestMethod @params
      $accesstoken = $($accessTokenResponse.access_token)
         
      $headers = @{ 
         "Content-Type" = "application/json" 
      }
      $params = @{
         'Uri'         = "https://www.googleapis.com/gmail/v1/users/me/messages?access_token=$accesstoken"
         'ContentType' = 'application/json'
         'Method'      = 'GET'
         'Headers'     = $headers
         'Verbose'     = $true
      }
      $getMessagesResponse = Invoke-RestMethod @params
      $messages = $($getMessagesResponse.messages)

      # Initialize counter variables
      $Results = 0
      # Create a counter variable that if, equals 0, means no emails matched.
      $Counter = 0
    
      # Get all emails
      # $Request = Invoke-WebRequest -Uri "https://www.googleapis.com/gmail/v1/users/me/messages?access_token=$accesstoken" -Method Get | ConvertFrom-Json
      # $messages = $($Request.messages)
      Write-Log "Found $($messages.count) messages to go through"
    
      ForEach ($message in $messages)
      {
         $a = $($message.id)
         $headers = @{ 
            "Content-Type" = "application/json" 
         }
         $params = @{
            'Uri'         = "https://www.googleapis.com/gmail/v1/users/me/messages/$a" + "?access_token=$accesstoken"
            'ContentType' = 'application/json'
            'Method'      = 'GET'
            'Headers'     = $headers
            'Verbose'     = $true
         }
         $b = Invoke-RestMethod @params
         # Find emails from bank
         Write-Log "Message Subject : $($b.snippet)"
         Write-Log "Seeing if this message matches the automated email we are looking for"
         If ($($b.snippet) -match "2800")
         {
            Write-Log "Matched"
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
            Write-Log "Amount extracted from email: $j"
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
            Write-Log "Card: $l"
            Write-Log "Amount to add to total: `$$k"
            [single]$Results += $k
            # Move to trash so it won't confuse the script for the next day
            $headers = @{ 
               "Content-Type" = "application/json" 
            }
            $params = @{
               'Uri'         = "https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken"
               'ContentType' = 'application/json'
               'Method'      = 'POST'
               'Headers'     = $headers
               'Verbose'     = $true
            }
            Invoke-RestMethod @params
         }
         Else
         {
            Write-Log "Didn't match"
            $Counter += 0
         }
      }
      Write-Log "Total charged: `$$Results"

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
      Write-Log "Budget: `$$Budget"
      
      # Section 4: Send email with all these results 
      
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
         $params = @{
            "From"       = $From
            "To"         = $To
            "Subject"    = $Subject
            "Body"       = $Body
            "SmtpServer" = $SMTPServer
            "Port"       = $SMTPPort
            "Credential" = $Creds
            "BodyAsHTML" = $true
            "UseSsl"     = $true
            "Verbose"    = $true
         }
         [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
         Send-MailMessage @params
         Write-Log "Sent email $From to $To"
        
         # Send me a text message as well
         $From = "me1@gmail.com"
         $To = "8170000000@txt.att.net"
         $Subject = "Budget"
         $Body = "Budget before payday: `$$Budget"
         $SMTPServer = "smtp.gmail.com"
         $SMTPPort = "587"
         $params = @{
            "From"       = $From
            "To"         = $To
            "Subject"    = $Subject
            "Body"       = $Body
            "SmtpServer" = $SMTPServer
            "Port"       = $SMTPPort
            "Credential" = $Creds
            "BodyAsHTML" = $true
            "UseSsl"     = $true
            "Verbose"    = $true
         }
         [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
         Send-MailMessage @params
         Write-Log "Sent text message $From to $To"
		
		
      }
      Else
      {
         $From = "me1@gmail.com"
         $To = "me2@gmail.com"
         $Subject = "Daily Budget Automated Task"
         $Body = "Email didn't arrive"
         $SMTPServer = "smtp.gmail.com"
         $SMTPPort = "587"
         $params = @{
            "From"       = $From
            "To"         = $To
            "Subject"    = $Subject
            "Body"       = $Body
            "SmtpServer" = $SMTPServer
            "Port"       = $SMTPPort
            "Credential" = $Creds
            "BodyAsHTML" = $true
            "UseSsl"     = $true
            "Verbose"    = $true
         }
         [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
         Send-MailMessage @params
         Write-Log "Sent email $From to $To"
		
         $From = "me1@gmail.com"
         $To = "8170000000@txt.att.net"
         $Subject = "WilliamsBudget"
         $Body = "Email didn't arrive"
         $SMTPServer = "smtp.gmail.com"
         $SMTPPort = "587"
         $params = @{
            "From"       = $From
            "To"         = $To
            "Subject"    = $Subject
            "Body"       = $Body
            "SmtpServer" = $SMTPServer
            "Port"       = $SMTPPort
            "Credential" = $Creds
            "BodyAsHTML" = $true
            "UseSsl"     = $true
            "Verbose"    = $true
         }
         [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
         Send-MailMessage @params
         Write-Log "Sent text message $From to $To"
		
      }
    
   }

   End
   {
      # Get all emails and put them in the trash so that we don't have too many messages to go through tomorrow
      $headers = @{ 
         "Content-Type" = "application/json" 
      }
      $params = @{
         'Uri'         = "https://www.googleapis.com/gmail/v1/users/me/messages?access_token=$accesstoken"
         'ContentType' = 'application/json'
         'Method'      = 'GET'
         'Headers'     = $headers
         'Verbose'     = $true
      }
      $getMessagesResponse = Invoke-RestMethod @params
      $messages = $($getMessagesResponse.messages)
      Write-Log "Found $($messages.count) messages to delete"

      ForEach ($message in $messages)
      {
         $a = $($message.id)
         $headers = @{ 
            "Content-Type" = "application/json" 
         }
         $params = @{
            'Uri'         = "https://www.googleapis.com/gmail/v1/users/me/messages/$a/trash" + "?access_token=$accesstoken"
            'ContentType' = 'application/json'
            'Method'      = 'POST'
            'Headers'     = $headers
            'Verbose'     = $true
         }
         $b = Invoke-RestMethod @params
      }

   }

}

<#######</Body>#######>
<#######</Script>#######>