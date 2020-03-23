<#######<Script>#######>
<#######<Header>#######>
# Name: Set-AppendedHostFile
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-AppendedHostFile
{
    <#
    .Synopsis
    Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
    .Description
    Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
    # http://winhelp2002.mvps.org/hosts.txt
    # https://raw.githubusercontent.com/stevenblack/hosts/master/hosts
    # http://someonewhocares.org/hosts/
    .Example
    Set-AppendedHostFile
    Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
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

        
    }
    
    Process
    {    
        # Get Hostfile Values From Winhelp2002.Mvps.Org, Github, And Someonewhocares.Org And Store Them In Separate Text Files
        $Hfv = Invoke-Webrequest "http://winhelp2002.mvps.org/hosts.txt"
        New-Item -Itemtype File -Path "$PSScriptRoot\Hfv.txt" -Value $Hfv.Content  | Out-Null
        Write-Log "Created $PSScriptRoot hfv.txt from winhelp2002"
        $Hfv2 = Invoke-Webrequest "https://raw.githubusercontent.com/stevenblack/hosts/master/hosts"
        New-Item -Itemtype File -Path "$PSScriptRoot\Hfv2.txt" -Value $Hfv2.Content  | Out-Null
        Write-Log "Created $PSScriptRoot hfv2.txt from Github"
        $Hfv3 = Invoke-Webrequest "http://someonewhocares.org/hosts/"
        New-Item -Itemtype File -Path "$PSScriptRoot\Hfv3.txt" -Value $Hfv3.Content  | Out-Null
        Write-Log "Created $PSScriptRoot hfv3.txt from someonewhocares.org"
        # Combine The Files

        $Merged = Get-Content "$PSScriptRoot\Hfv.txt"
        $Merged2 = Get-Content "$PSScriptRoot\Hfv2.txt" | Select-Object -Skip 67
        $Merged3 = Get-Content "$PSScriptRoot\Hfv3.txt" | Select-Object -Skip 117
        $Total = $Merged + $Merged2 + $Merged3
        $Total | Out-File "$PSScriptRoot\combined.txt"

        # Modify The File
        $A = @"
# Please See:
# http://winhelp2002.mvps.org/hosts.txt
# https://raw.githubusercontent.com/stevenblack/hosts/master/hosts
# http://someonewhocares.org/hosts/
# Follow Their Rules In Regards To Licensing And Copyright
# Entries Below
"@
        Write-Log "Cleaning The File By Removing Anything That Is Not A 0 Or 1"
        $B = Get-Content "$PSScriptRoot\combined.txt" | Where-Object { $_ -Match "^0" -Or $_ -Match "^1"}
        $C = -Join $A, $B
        Write-Log "Replace All 127.0.0.1 With 0.0.0.0"
        $D = $C.Replace("127.0.0.1", "0.0.0.0")

        Write-Log "Sort Alphabetically And Remove Duplicates"
        $E = $D | Sort-Object | Get-Unique
        $E | Out-File "$PSScriptRoot\host.txt"

        Write-Log "Appending To The Current Windows Host File"
        Add-Content -Value $E -Path "$($Env:Windir)\System32\Drivers\Etc\Hosts"

        # Clean Up
        Write-Log "Deleting Txt Files Created By Script"
        Remove-Item -Path "$PSScriptRoot\combined.txt"
        Remove-Item -Path "$PSScriptRoot\Hfv.txt"
        Remove-Item -Path "$PSScriptRoot\Hfv2.txt"
        Remove-Item -Path "$PSScriptRoot\Hfv3.txt"
        Remove-Item -Path "$PSScriptRoot\host.txt"
    }

    End
    {
        Stop-log
        $Input = Read-Host "Would You Like To See Your Windows Host File? (Y)Yes Or (N)No"
        If ($Input -Eq "Y")
        {
            Invoke-Item "$($Env:Windir)\System32\Drivers\Etc\Hosts"
        }
        Else
        {
            Exit
        }
    }
}

<#######</Body>#######>
<#######</Script>#######>