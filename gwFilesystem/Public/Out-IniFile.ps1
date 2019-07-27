<#######<Script>#######>
<#######<Header>#######>
# Name: Out-IniFile
<#######</Header>#######>
<#######<Body>#######>
Function Out-IniFile
{
    <#  
.Synopsis  
Write hash content to INI file  
.Description  
Write hash content to INI file  
.Notes  
Author        : Oliver Lipkau <oliver@lipkau.net>  
Blog        : http://oliver.lipkau.net/blog/  
Source        : https://github.com/lipkau/PsIni 
    http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
Version        : 1.0 - 2010/03/12 - Initial release  
    1.1 - 2012/04/19 - Bugfix/Added example to help (Thx Ingmar Verheij)  
    1.2 - 2014/12/11 - Improved handling for missing output file (Thx SLDR) 
#Requires -Version 2.0  
.Inputs  
System.String  
System.Collections.Hashtable  
.Outputs  
System.IO.FileSystemInfo  
.Parameter Append  
Adds the output to the end of an existing file, instead of replacing the file contents.  
.Parameter InputObject  
Specifies the Hashtable to be written to the file. Enter a variable that contains the objects or type a command or expression that gets the objects.  
.Parameter FilePath  
Specifies the path to the output file.  
.Parameter Encoding  
Specifies the type of character encoding used in the file. Valid values are "Unicode", "UTF7",  
"UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", and "OEM". "Unicode" is the default.  
"Default" uses the encoding of the system's current ANSI code page.   
"OEM" uses the current original equipment manufacturer code page identifier for the operating   
system.  
.Parameter Force  
Allows the cmdlet to overwrite an existing read-only file. Even using the Force parameter, the cmdlet cannot override security restrictions.  
.Parameter PassThru  
Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.  
.Example  
Out-IniFile $IniVar "C:\myinifile.ini"  
-----------  
Description  
Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini  
.Example  
$IniVar | Out-IniFile "C:\myinifile.ini" -Force  
-----------  
Description  
Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present  
.Example  
$file = Out-IniFile $IniVar "C:\myinifile.ini" -PassThru  
-----------  
Description  
Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file  
.Example  
$Category1 = @{“Key1”=”Value1”;”Key2”=”Value2”}  
$Category2 = @{“Key1”=”Value1”;”Key2”=”Value2”}  
$NewINIContent = @{“Category1”=$Category1;”Category2”=$Category2}  
Out-IniFile -InputObject $NewINIContent -FilePath "C:\MyNewFile.INI"  
-----------  
Description  
Creating a custom Hashtable and saving it to C:\MyNewFile.INI  
.Link  
Get-IniContent  
#> 

    [CmdletBinding()]  
    Param(  
        [switch]$Append,  
        [ValidateSet("Unicode", "UTF7", "UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", "OEM")]  
        [Parameter()]  
        [string]$Encoding = "Unicode",  
        [ValidateNotNullOrEmpty()]  
        [ValidatePattern('^([a-zA-Z]\:)?.+\.ini$')]  
        [Parameter(Mandatory = $True)]  
        [string]$FilePath,  
        [switch]$Force,  
        [ValidateNotNullOrEmpty()]  
        [Parameter(ValueFromPipeline = $True, Mandatory = $True)]  
        [Hashtable]$InputObject,  
        [switch]$Passthru  
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
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"  
            if ($append) {$outfile = Get-Item $FilePath}  
            else {$outFile = New-Item -ItemType file -Path $Filepath -Force:$Force}  
            if (!($outFile)) {Throw "Could not create File"}  
            foreach ($i in $InputObject.keys)  
            {  
                if (!($($InputObject[$i].GetType().Name) -eq "Hashtable"))  
                {  
                    #No Sections  
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"  
                    Add-Content -Path $outFile -Value "$i=$($InputObject[$i])" -Encoding $Encoding  
                }
                else
                {  
                    #Sections  
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"  
                    Add-Content -Path $outFile -Value "[$i]" -Encoding $Encoding  
                    Foreach ($j in $($InputObject[$i].keys | Sort-Object))  
                    {  
                        if ($j -match "^Comment[\d]+")
                        {  
                            Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $j"  
                            Add-Content -Path $outFile -Value "$($InputObject[$i][$j])" -Encoding $Encoding  
                        }
                        else
                        {  
                            Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $j"  
                            Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])" -Encoding $Encoding  
                        }  
                    }  
                    Add-Content -Path $outFile -Value "" -Encoding $Encoding  
                }  
            }  
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $path"  
            if ($PassThru) {Return $outFile}   
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