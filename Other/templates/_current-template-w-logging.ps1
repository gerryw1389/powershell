<#######<Script>#######>
<#######<Header>#######>
# Name: Set-Template
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
<#######</Header>#######>
<#######<Body>#######>
Function Set-Template
{
   <#
.Synopsis
Light description
.Description
More thorough description.
.Example
Set-Template
Light description
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
            #Write-Verbose "Logfile was less than 10 MB"   
         }
         Start-Transcript -Path $Logfile -Append 
         Write-Log "##########<Start Function>##########"
         Write-Log "Function started on $env:COMPUTERNAME"

      }

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
                
            [Parameter(Mandatory = $False, Position = 1)]
            [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                  "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
            [String]$Color = ""
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

      Function Stop-Log
      {
         <#
            .Synopsis
            Stops transcribing the session and cleans the transcript file by removing the fluff.
            .Notes
            2018-06-24: Initial script
            #>
            
         Write-Log "Function completed on $env:COMPUTERNAME"
         Write-Log "###########<End Function>###########"
         Stop-Transcript
       
         # Now we will clean up the transcript file as it contains filler info that needs to be removed...

         # Remove Start-Transcript auto generated stuff
         $LogfileContent = get-content $Logfile -Raw
         $splat = @{
            'InputObject' = $LogfileContent
            'Pattern'     = '(?smi)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*([\S\s]*?)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*'
            'AllMatches'  = $true
         }
         $allRegex = Select-String @splat
         $matchingStrings = $($allRegex.Matches)
         foreach ($m in $matchingStrings)
         {
            $transcriptText = $($m.Value)
            $currentRead = get-content $Logfile -Raw
            $newText = $currentRead.Replace($transcriptText, "")
            Set-Content -Path $Logfile -Value $newText -Force
         }

         # Remove 'VERBOSE: '
         $currentRead = get-content $Logfile -Raw
         $newText = $currentRead.Replace("VERBOSE: ", "")
         Set-Content -Path $Logfile -Value $newText -Force

         # Remove 'Transcript started line'
         $pattern = "Transcript started, output file is " + $Logfile
         $currentRead = get-content $Logfile -Raw
         $newText = $currentRead.Replace($pattern, "")
         Set-Content -Path $Logfile -Value $newText -Force

         # Remove blank lines
         $currentRead = Get-Content $Logfile
         $newText = $currentRead | Where-Object { $_ -notmatch "^$" }
         Set-Content -Path $Logfile -Value $newText -Force            
      }
        
      Start-Log

      ####################</Default Begin Block>####################
        
   }

   Process
   {
      Try
      {
         
         # Your script goes here
         
         # Write-Log "hello world"
         # Write-Log (cmd /c "ipconfig /all") -Color Magenta
         # Write-Log (get-process | format-table)

      }
      Catch
      {
         Write-Error $($_.Exception.Message)
      }
   }

   End
   {
      Stop-log
   }
}

<#######</Body>#######>
<#######</Script>#######>