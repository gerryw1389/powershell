<#######<Script>#######>
<#######<Header>#######>
# Name: Start-ScriptFromGitlabRemotely
<#######</Header>#######>
<#######<Body>#######>
Function Start-ScriptFromGitlabRemotely
{
    <#
.Synopsis
Downloads a script from public Gitlab on a remote machine and runs it.
No longer works since repo's are private now. Works fine for public repos
.Description
Downloads a script from public Gitlab on a remote machine and runs it.
No longer works since repo's are private now. Works fine for public repos
.Parameter Filepath
The source text file to read servers from.
.Parameter URI
The URI of the resource you are wanting to download and run.
.Example
Start-ScriptFromGitlabRemotely -Filepath c:\scripts\servers.txt -URI 'https://something.domain.com/install-splunk.ps1'
Downloads a script from public Gitlab on a remote machine and runs it.
.Notes
Haven't tested, but since it uses jobs, you are supposed to get the results from the jobs like so:
PS>$j = Get-Job
PS>$j | Format-List -Property *
PS>$results = $j | Receive-Job
PS>$results
Job 1
------
Blah

#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateScript({
            if(-Not ($_ | Test-Path) )
			{
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Leaf) )
			{
                throw "The Path argument must be a file. Folder paths are not allowed."
            }
            if($_ -notmatch "(\.txt)")
			{
                throw "The file specified in the path argument must be a text file"
            }})]
        [string]$Filepath,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [int]$Port
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
        
        $servers = Get-Content -Path $Filepath
    }

    Process
    {
        # split the URI and grab the last section
        $parts = $URI -split '/'
        $filename = $parts[-1]
        
        Try
        {
            foreach ($server in $servers)
            {
                Write-Output "Testing connection to server: $server"
                $a = Test-Connection -Count 2 -ComputerName $server -Quiet
                If ($a)
                {
                    Try
                    {
                        Write-Output "Establishing a session: $server"
                        $Session = New-PSSession -ComputerName $server -ErrorAction Stop
                        Invoke-Command -Session $session -ScriptBlock {
                            # Download the script
                            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                            $r = Invoke-WebRequest -UseBasicParsing $URI
                            if (-not(test-path 'C:\scripts'))
                            { 
                                new-item -ItemType directory -Path 'c:\scripts' | out-null 
                            }
                            $Outfile = 'c:\scripts\' + $filename
                            $r.Content | Out-File $Outfile
                            Start-Sleep -Seconds 1
                            
                            <#
                            # Script has been downloaded to the machine at this point. You may need to modify it for something.

                            # For example, if it contains a generic password, you can replace the password by doing something like:
                            
                            (Get-Content "C:\scripts\Install-Splunk.ps1").replace('LookMeUp', 'pa$$word') | Set-Content "C:\scripts\Install-Splunk.ps1"
                            
                            # Or if the script is an advanced function like all of mine are, you can add the call of the function to the end of the file so that
                            # it behaves like a script.

                            Add-Content -Value 'Install-Splunk' -Path $Outfile
                            
                            # Where $Outfile is "c:\scripts\Install-Splunk.ps1"
                            #>
                            
                            # Starts the script
                            Start-Process "powershell.exe" -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File $Outfile -Verb RunAs' -Wait
                        } -AsJob
                        $Session | Remove-PSSession
                    }
                    Catch
                    {
                        Write-Output "Unable to establish a remote connection: $server"
                        Continue
                    }
                }
                Else
                {
                    Write-output "connection to computer too slow: $server"
                    Continue
                }
            }
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