<#######<Script>#######>
<#######<Header>#######>
# Name: Send-BitcoinEmail
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Send-BitcoinEmail
{
   <#
.Synopsis
Gets the current price of Bitcoin using Alpha Vantage API and sends an email if it is below a certain price.
.Description
Gets the current price of Bitcoin using Alpha Vantage API and sends an email if it is below a certain price.
.Example
Send-BitcoinEmail
Gets the current price of Bitcoin using Alpha Vantage API and sends an email if it is below a certain price.
#>

   [CmdletBinding()]
   PARAM()
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
      
      function Send-Email
      {
         [CmdletBinding()]
         Param 
         (
            [string]$fundName
         )
         $usernameXML = Import-Clixml -Path "$PSScriptRoot\username.xml"
         $username = $usernameXML.GetNetworkCredential().Password

         $passwordXML = Import-Clixml -Path "$PSScriptRoot\password.xml"
         $password = $passwordXML.GetNetworkCredential().Password

         # Creds for sending email
         $pw = ConvertTo-SecureString -String $password -AsPlainText -Force
         $Creds = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $username, $pw

         $From = "me@gmail.com"
         $To = "me@gmail.com"
         $Subject = "Buy Fund: $fund"
         $Body = "Records indicate this fund is on decline for more than 3 days"
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
      }
   }
   
   Process
   {
      [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"  
      $funds = @( "VFIFX", "VWUSX", "VTSAX", "BTC-USD")

      foreach ($fund in $funds)
      {
         Write-Log "fund: $fund"

         $uri = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=" + $fund + "&apikey=PNFmyKey"
         $response = Invoke-RestMethod $uri -Method 'GET' -Headers $headers -Body $body
         #$response | ConvertTo-Json

         $last3 = $response.'Time Series (Daily)'.PSObject.Properties | Sort-Object -Descending | Select-Object -First 5 
         $first = $last3[0].name
         $firstvalue = $last3[0].value.'5. adjusted close'
         $second = $last3[1].name
         $secondvalue = $last3[1].value.'5. adjusted close'
         $third = $last3[2].name
         $thirdvalue = $last3[2].value.'5. adjusted close'
         $fourth = $last3[3].name
         $fourthvalue = $last3[3].value.'5. adjusted close'
         $fifth = $last3[4].name
         $fifthvalue = $last3[4].value.'5. adjusted close'

         Write-Log "$first - $firstvalue"
         Write-Log "$second - $secondvalue"
         Write-Log "$third - $thirdvalue"
         Write-Log "$fourth - $fourthvalue"
         Write-Log "$fifth - $fifthvalue"

         $count = 0
         if ($firstvalue -lt $secondvalue)
         {
            $count += 1
         }
         if ($secondvalue -lt $thirdvalue)
         {
            $count += 1
         }
         if ($thirdvalue -lt $fourthvalue)
         {
            $count += 1
         }
         if ($fourthvalue -lt $fifthvalue)
         {
            $count += 1
         }
         Write-Log "Value of count: $count"
         If ( $count -lt 4)
         {
            Write-Log "Dont buy: $fund"
            #Send-Email -fundName $fund
         }
         Else
         {
            Write-Log "Buy $fund"
            Send-Email -fundName $fund
         }
         Start-Sleep -Seconds 3
      }

   }
   End
   {
      Stop-log
   }
}

<#######</Body>#######>
<#######</Script>#######>