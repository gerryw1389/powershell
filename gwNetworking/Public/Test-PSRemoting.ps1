<#######<Script>#######>
<#######<Header>#######>
# Name: Test-PSRemoting
<#######</Header>#######>
<#######<Body>#######>
Function Test-PSRemoting
{
    <#
.Synopsis
Given a text file with a list of servers, this will see if remoting is PS remoting with SSL is enabled.
.Description
Given a text file with a list of servers, this will see if remoting is PS remoting with SSL is enabled.
.Parameter FilePath
Required parameter which is a text file listing servers one per line.
.Parameter OutFile
An optional CSV to export the results to. If not, they will be in the log file.
.Example
Test-PSRemoting -FilePath c:\oitadmins\servers.txt
Given a text file with a list of servers, this will see if remoting is PS remoting with SSL is enabled.
.Notes
Version history:
2018-11-01: version 1
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateScript( {(Test-Path $_) -and ((Get-Item $_).Extension -eq ".txt")})]
        [String]$FilePath,

        [Parameter(Mandatory = $false, Position = 1)]
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
        
        $servers = Get-Content -Path $FilePath

        $csv = [System.Collections.Generic.List[PSObject]]@()
        #$csv_header = "ServerName,ICMPTest,TCPTest,WinRMTest"
        $csv_header = '"ServerName","ICMPTest","TCPTest","WinRMTest"'
        [void]$csv.Add($csv_header)
    }
    
    Process
    {
        Try
        {
            Foreach ($server in $servers)
            {
                
                $Global:WarningPreference = 'SilentlyContinue'         
                $Global:ProgressPreference = 'SilentlyContinue'
                $a = test-netconnection $server -port 5986
                
                If ($a.PingSucceeded -eq $false)
                {
                    $Ping = 'False'
                }
                Else
                {
                    $Ping = 'True'
                }
                
                If ($a.TcpTestSucceeded -eq $false)
                {
                    $Tcp = 'False'
                }
                Else
                {
                    $Tcp = 'True'
                }
                
                Try
                {
                    $Params = @{
                        'ComputerName' = $Server
                        'UseSSL'       = $true
                        'ErrorAction'  = 'Stop'
                    }
                    [void](Invoke-Command @Params -ScriptBlock { Write-Output $env:COMPUTERNAME })
                    $WinRM = 'True'
                }
                Catch
                {
                    $WinRM = 'False'
                }

                $ThisServer = [ordered] @{
                    'ServerName: ' = $server
                    'ICMP Test: '  = $Ping
                    'TCP Test: '   = $Tcp
                    'WinRM Test: ' = $WinRM
                }
                $ThisServer
                $string = '"' + $server +'","' + $Ping +'","' + $Tcp +'","' + $WinRM + '"'
                #$string = $server,$Ping,$Tcp,$WinRM
                [void]$csv.add($string)

                Clear-Variable -Name server,ping,tcp,winrm
            }
        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }
    End
    {
        $Global:WarningPreference = 'Continue'         
        $Global:ProgressPreference = 'Continue'
                
        Write-Log "Summary"
        Write-Log "==========================="
        $csv
        
        If ($Outfile -ne '')
        {
            $csv | Out-File -FilePath $OutFile -Force
        }

        Stop-log
        
        <#
        Another way:
        $jobs = Invoke-Command -Computername $servers -ScriptBlock { 
                (Get-Process | Sort-Object -Property ws -Descending | Select-Object -First 1 | Select-Object -Property processname).processname
            } -AsJob

        foreach ($j in $($jobs.childjobs))
        {
            $JobName = $j.Name
            $server = $j.Location
            $result = Receive-Job -Name $JobName -Keep
            If ($Result -ne '')
            {
                Write-output "Successful PS Remoting on : $server"
            }
        }
        #>
    
    }
}
<#######</Body>#######>
<#######</Script>#######>