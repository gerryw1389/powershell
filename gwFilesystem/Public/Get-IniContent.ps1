<#######<Script>#######>
<#######<Header>#######>
# Name: Get-IniContent
<#######</Header>#######>
<#######<Body>#######>
Function Get-IniContent
{
    <#
.Synopsis  
Gets the content of an INI file  
.Description  
Gets the content of an INI file and returns it as a hashtable  
.Notes  
Author        : Oliver Lipkau <oliver@lipkau.net>  
Blog        : http://oliver.lipkau.net/blog/  
Source        : https://github.com/lipkau/PsIni 
http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
Version        : 1.0 - 2010/03/12 - Initial release  
1.1 - 2014/12/11 - Typo (Thx SLDR) 
Typo (Thx Dave Stiff) 
#Requires -Version 2.0  
.Inputs  
System.String  
.Outputs  
System.Collections.Hashtable  
.Parameter FilePath  
Specifies the path to the input file.  
.Example  
$FileContent = Get-IniContent "C:\myinifile.ini"  
-----------  
Description  
Saves the content of the c:\myinifile.ini in a hashtable called $FileContent  
.Example  
$inifilepath | $FileContent = Get-IniContent  
-----------  
Description  
Gets the content of the ini file passed through the pipe into a hashtable called $FileContent  
.Example  
C:\PS>$FileContent = Get-IniContent "c:\settings.ini"  
C:\PS>$FileContent["Section"]["Key"]  
-----------  
Description  
Returns the key "Key" of the section "Section" from the C:\settings.ini file  
.Link  
Out-IniFile  
#>

    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript( {(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
        [Parameter(ValueFromPipeline = $True, Mandatory = $True)]  
        [string]$FilePath  
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
        
    }

    Process
    {
        Try
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
            $ini = @{}  
            switch -regex -file $FilePath  
            {  
                "^\[(.+)\]$" # Section  
                {  
                    $section = $matches[1]  
                    $ini[$section] = @{}  
                    $CommentCount = 0  
                }  
                "^(;.*)$" # Comment  
                {  
                    if (!($section))  
                    {  
                        $section = "No-Section"  
                        $ini[$section] = @{}  
                    }  
                    $value = $matches[1]  
                    $CommentCount = $CommentCount + 1  
                    $name = "Comment" + $CommentCount  
                    $ini[$section][$name] = $value  
                }   
                "(.+?)\s*=\s*(.*)" # Key  
                {  
                    if (!($section))  
                    {  
                        $section = "No-Section"  
                        $ini[$section] = @{}  
                    }  
                    $name, $value = $matches[1..2]  
                    $ini[$section][$name] = $value  
                }  
            }  
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
            Return $ini  
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