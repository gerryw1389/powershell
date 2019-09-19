<#######<Script>#######>
<#######<Header>#######>
# Name: Get-BackupsSize
<#######</Header>#######>
<#######<Body>#######>
Function Get-BackupsSize
{
    <#
.Synopsis
Gets the current size of all of our backups.
.Description
Gets the current size of all of our backups.
Must be ran on the Veeam Server.
.Parameter Outfile
A path for the CSV to export to.
.Example
Get-BackupsSize
Gets the current size of all of our backups.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$OutFile
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
        
        if ((Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue) -eq $null)
        {
            Add-PsSnapin -Name VeeamPSSnapIn
        }

        $Objects = [System.Collections.Generic.List[PSObject]]@()
        $Intro = 'Jobname,BackupSize,DataSize' # Enter column names
        [void]$Objects.Add($Intro)
    }

    Process
    {
        Try
        {
            $VeeamVersion = ((Get-PSSnapin VeeamPSSnapin).Version.Major)
            $backupJobs = Get-VBRBackup

            foreach ($job in $backupJobs)
            {
                # get all restore points inside this backup job - use different function for Veeam B&R 9+
                if ($VeeamVersion -ge 9)
                {
                    $restorePoints = $job.GetAllStorages() | sort CreationTime -descending
                }
                else
                {
                    $restorePoints = $job.GetStorages() | sort CreationTime -descending
                }

                $jobBackupSize = 0
                $jobDataSize = 0

                $jobName = ($job | Select-Object -ExpandProperty JobName)

                Write-Output "Processing backup job: $jobName"

                # get list of VMs associated with this backup job
                $vmList = ($job | Select-Object @{name = "vm"; expression = { $_.GetObjectOibsAll() | ForEach-Object { @($_.name, "") } } } | Select-Object -ExpandProperty vm)
                $amountVMs = 0
                $vms = ""
                foreach ($vmName in $vmList)
                {
                    if ([string]::IsNullOrEmpty($vmName))
                    {
                        continue
                    }
                    $vms += "$vmName,"
                    $amountVMs = $amountVMs + 1
                }

                # cut last ,
                if (![string]::IsNullOrEmpty($vmName))
                {
                    $vms = $vms.Substring(0, $vms.Length - 1)
                }

                # go through restore points and add up the backup and data sizes
                foreach ($point in $restorePoints)
                {
                    $jobBackupSize += [long]($point | Select-Object -ExpandProperty stats | Select-Object -ExpandProperty BackupSize)
                    $jobDataSize += [long]($point | Select-Object -ExpandProperty stats | Select-Object -ExpandProperty DataSize)
                }

                # convert to GB
                $jobBackupSize = [math]::Round(($jobBackupSize / 1024 / 1024 / 1024), 2)
                $jobDataSize = [math]::Round(($jobDataSize / 1024 / 1024 / 1024), 2)

                $String = "$($Jobname.ToString()),$($jobBackupSize.Tostring()),$($jobDataSize.Tostring())"
                [void]$Objects.Add($String)
        
            }
        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }

    End
    {
        $Objects | Out-File $Outfile -Encoding ascii
        Stop-log
    }
}

<#######</Body>#######>
<#######</Script>#######>