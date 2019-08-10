<#######<Script>#######>
<#######<Header>#######>
# Name: Send-ADHealthReport
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Send-ADHealthReport
{
<#
.Synopsis
This function is best placed a scheduled task to run daily on the domain controller. 
It will send an email showing results of ad health checks.
.Description
This function is best placed a scheduled task to run daily on the domain controller. 
It will send an email showing results of ad health checks.
You will need to setup the from address, to address, smtp server, $logfile" variables.
.Example
Send-ADHealthReport
Sends a report to the email you specify of ad health check tests that run will run on the domain controller.
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
                ForEach-Object {$_.Matches} | 
                ForEach-Object {$_.Value} | 
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

        
        Function Send-Email ([String]$Body)
        {
            $Mailmessage = New-Object System.Net.Mail.Mailmessage
            $Mailmessage.From = "Email@Domain.Com"
            $Mailmessage.To.Add("Administratoremail@Domain.Com")
            $Mailmessage.Subject = "Ad Daily Replication Summary"
            $Mailmessage.Body = $Body
            #$Mailmessage.Priority = "High"
            $Mailmessage.Isbodyhtml = $True

            $Smtpclient = New-Object System.Net.Mail.Smtpclient
            $Smtpclient.Host = "Smtp.Server.Hostname"
            $Smtpclient.Send($Mailmessage)
        }
    }
    
    Process
    {
        # Get The Replication Info.
        $Myrepinfo = @(Repadmin /Replsum * /Bysrc /Bydest /Sort:Delta)
 
        # Initialize Our Array.
        $Cleanrepinfo = @()
        # Start @ #10 Because All The Previous Lines Are Junk Formatting
        # And Strip Off The Last 4 Lines Because They Are Not Needed.
        For ($I = 10; $I -Lt ($Myrepinfo.Count - 4); $I++)
        {
            If ($Myrepinfo[$I] -Ne "")
            {
                # Remove Empty Lines From Our Array.
                $Myrepinfo[$I] -Replace 'S+', " "   
                $Cleanrepinfo += $Myrepinfo[$I]    
            }
        }   
        $Finalrepinfo = @()  
        Foreach ($Line In $Cleanrepinfo)
        {
            $Splitrepinfo = $Line -Split 'S+', 8
            If ($Splitrepinfo[0] -Eq "Source")
            {
                $Reptype = "Source" 
            }
            If ($Splitrepinfo[0] -Eq "Destination")
            {
                $Reptype = "Destination" 
            }
   
            If ($Splitrepinfo[1] -Notmatch "Dsa")
            {  
                # Create An Object And Populate It With Our Values.
                $Objrepvalues = New-Object System.Object
                $Objrepvalues | Add-Member -Type Noteproperty -Name Dsatype -Value $Reptype # Source Or Destination Dsa
                $Objrepvalues | Add-Member -Type Noteproperty -Name Hostname  -Value $Splitrepinfo[1] # Hostname
                $Objrepvalues | Add-Member -Type Noteproperty -Name Delta  -Value $Splitrepinfo[2] # Largest Delta
                $Objrepvalues | Add-Member -Type Noteproperty -Name Fails -Value $Splitrepinfo[3] # Failures
                #$Objrepvalues | Add-Member -Type Noteproperty -Name Slash  -Value $Splitrepinfo[4] # Slash Char
                $Objrepvalues | Add-Member -Type Noteproperty -Name Total -Value $Splitrepinfo[5] # Totals
                $Objrepvalues | Add-Member -Type Noteproperty -Name Pcterror  -Value $Splitrepinfo[6] # % Errors  
                $Objrepvalues | Add-Member -Type Noteproperty -Name Errormsg  -Value $Splitrepinfo[7] # Error Code
  
                # Add The Object As A Row To Our Array   
                $Finalrepinfo += $Objrepvalues
   
            }
        }
        $Html = $Finalrepinfo|Convertto-Html -Fragment   
   
        $Xml = [Xml]$Html

        $Attr = $Xml.Createattribute("Id")
        $Attr.Value = 'Disktbl'
        $Xml.Table.Attributes.Append($Attr)


        $Rows = $Xml.Table.Selectnodes('//Tr')
        For ($I = 1; $I -Lt $Rows.Count; $I++)
        {
            $Value = $Rows.Item($I).Lastchild.'#Text'
            If ($Value -Ne $Null)
            {
                $Attr = $Xml.Createattribute('Style')
                $Attr.Value = 'Background-Color: Red;'
                [Void]$Rows.Item($I).Attributes.Append($Attr)
            }
   
            Else
            {
                $Value
                $Attr = $Xml.Createattribute('Style')
                $Attr.Value = 'Background-Color: #7bce73;'
                [Void]$Rows.Item($I).Attributes.Append($Attr)
            }
        }

        #Embed A Css Stylesheet In The Html Header
        $Html = $Xml.Outerxml|Out-String
        $Style = '<Style Type=Text/Css>#Disktbl { Background-Color: White; } 
    Td, Th { Border:1px Solid Black; Border-Collapse:Collapse; }
    Th { Color:White; Background-Color:Black;Font-Family:Verdana;Font-Size:9pt; }
    Table, Tr, Td { Font-Family:Verdana;Font-Size:9pt;Padding: 1px 5px; }, Th { Padding: 2px 5px; Margin: 0px } Table { Margin-Left:50px; }</Style>'

        #Convertto-Html -Head $Style -Body $Html -Title "Replication Report"|Out-File Replicationreport.Htm

        $Bodyhtml = Convertto-Html -Head $Style -Body $Html -Title "Replication Report" | Out-String

        Send-Email $Bodyhtml
        Write-Log "Email Sent"
    }

    End
    {
        Stop-log
        
    }

}

<#######</Body>#######>
<#######</Script>#######>