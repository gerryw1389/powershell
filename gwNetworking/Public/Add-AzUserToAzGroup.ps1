<#######<Script>#######>
<#######<Header>#######>
# Name: Add-UserToGroup
<#######</Header>#######>
<#######<Body>#######>
Function Add-AzUserToAzGroup
{
   <#
.SYNOPSIS
Given an email address of a user, it will add the user to one of the pre-defined groups in the function (modify lines 291+ to add as many groups as you want).
.DESCRIPTION
Given an email address of a user, it will add the user to one of the pre-defined groups in the function (modify lines 291+ to add as many groups as you want). I mainly wrote this function to be ran from a linux host that has the open source version of powershell so that I wouldn't have to do any importing of modules and could just use pure REST API. Requires that you setup an an application in your Azure tenant first - https://gerrywilliams.net/2020/01/azure-create-ps-app/
.PARAMETER UserEmail
Email address of a valid user.
.PARAMETER GroupName
Since Jenkins has an issue parsing an array for input, it is easier to just have Jenkins use a string and then extract out based on commas. All this to say this parameter will extract out into an array so pass as many groups as you want as an array.
.PARAMETER TenantID
.EXAMPLE
Add-AzUserToAzGroup -UserEmail "user@domain.com" -GroupID "Sandbox"
The above example adds the user 'user@domain.com' to group 'SBX-Users' in Azure using Graph API.
.EXAMPLE
Add-AzUserToAzGroup -UserEmail "user@domain.com" -GroupID "Sandbox", "Test"
The above example adds the user 'user@domain.com' to group 'SBX-Users' in Azure using Graph API and to the group "TST-Users" in Azure using Graph API. 
#>
   [Cmdletbinding()]
   Param
   (
      [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
      [String] $UserEmail,

      [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
      [String] $GroupName
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
         Param
         (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
            [PSObject]$InputObject,
                
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
        
      Function New-MSGraphAPIToken
      {
         <#
         .SYNOPSIS
         Acquire authentication token for MS Graph API
         .DESCRIPTION
         If you have a registered app in Azure AD, this function can help you get the authentication token
         from the MS Graph API endpoint. Each token is valid for 60 minutes.
         .PARAMETER ClientID
         This is the registered ClientID in AzureAD
         .PARAMETER ClientSecret
         This is the key of the registered app in AzureAD
         .PARAMETER TenantID
         This is your Office 365 Tenant Domain
         .EXAMPLE
         $graphToken = New-MSGraphAPIToken -ClientID <ClientID> -ClientSecret <ClientSecret> -TenantID <TenantID>
         The above example gets a new token using the ClientID, ClientSecret and TenantID combination
         .NOTES
         General notes
         #>
         param(
            [parameter(mandatory = $true)]
            [string]$ClientID,
            [parameter(mandatory = $true)]
            [string]$ClientSecret,
            [parameter(mandatory = $true)]
            [string]$TenantID
         )
         $body = @{grant_type = "client_credentials"; scope = "https://graph.microsoft.com/.default"; client_id = $ClientID; client_secret = $ClientSecret }
         $oauth = Invoke-RestMethod -Method Post -Uri https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token -Body $body
         $token = @{'Authorization' = "$($oauth.token_type) $($oauth.access_token)" }    
         Return $token
      }

      $ClientSecret = 'seeKeypass'
      $ClientID = 'seeKeypass'
      $tenantID = 'seeKeypass'

      
      Write-output "Jenkins var UserEmail: $env:UserEmail"
      Write-output "Jenkins var GroupName: $env:GroupName"

   }
   Process
   {
            
      $token = New-MSGraphAPIToken -clientID $clientID -clientSecret $clientSecret -tenantID $tenantID

      # example request
      $uri = "https://graph.microsoft.com/v1.0/users/$userEmail"
      $request = Invoke-RestMethod -Method GET -Uri $uri -Headers $token
      
      #get the ID of the user
      $userID = $($request.id)
      Write-output "UserID: $userID"
      

      Write-output "Jenkins var UserEmail: $env:UserEmail"
      Write-output "Jenkins var GroupName: $env:GroupName"

      $GroupNameList = [System.Collections.Generic.List[PSObject]]@()
      If ( $GroupName.Contains(',') )
      {
         Write-output "Groupname contains a comma, more than one group"
         $allgroups = $GroupName.Split(",").trim()

         foreach ( $listItem in $allgroups )
         {
            Write-output "Adding user to the group that will be parsed: $listItem"
            [void]$GroupNameList.Add($listItem)
         }
      }
      Else
      {
         Write-output "Groupname does not contain a comma, adding single user to group"
         Write-output "Adding user to group: $GroupName"
         [void]$GroupNameList.Add($GroupName)
      }

      Write-output "Group name list: $GroupNameList"

      foreach ( $group in $GroupNameList )
      {
         Write-output "Processing: $group"

         $groupID = $group
         # get the group you want to add the user to
         switch ($groupID)
         {
            "Sandbox" { $groupID = 'some Azure object ID for a group' }
            "Test" { $groupID = 'some Azure object ID for a group' }
            default { $groupID = '' }
         }
         
         Write-output "GroupID: $groupID"

         $posturi = "https://graph.microsoft.com/v1.0/groups/$groupID/members/" + '$ref'
         $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
         $headers.Add("Authorization", $token["Authorization"])
         $headers.Add("Content-Type", "application/json")
         $jsonBody = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/users/$userID" } | ConvertTo-Json
         Try
         {
            Invoke-RestMethod -Method Post -Uri $posturi -Headers $headers -Body $jsonBody
            Write-output "Adding user to group: Succeeded - $groupID"
         }
         Catch
         {
            Write-Output "Unable to complete the request"
         }

         Start-Sleep -Seconds 3
      }
   }
   End
   {
   }
}
<#######</Body>#######>
<#######</Script>#######>