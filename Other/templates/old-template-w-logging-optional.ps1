<#######<Script>#######>
<#######<Header>#######>
# Name: Copy-Module
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-Template
{
    <#
.Synopsis
Light description.
.Description
More thorough description.
.Parameter Logfile
Specifies A Logfile. Default is YYYY-MM-DD-Scriptname.Log in the current directory and is created for every script automatically.
NOTE: See below for logging options.
.Example
Set-Template
Usually same as synopsis.
.Notes
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
Main code usually starts around line 261ish.
2018-08-30: v1.2 Updated template.
2018-06-17: v1.1 Updated template.
2017-09-08: v1.0 Initial script 
.Functionality
All my functions follow 4 ways you can run them. By default, they will log to a logfile in the current directory.
1. If -Verbose is not passed (Default) and logfile is zero length (''), don't show messages on the screen and don't transcript the session.
Example: 
PS>. .\my-function.ps1
PS>My-Function -Logfile ''
# Result: Function is called and executed, but there is no log file and almost all output is suppressed.

2. If -Verbose is not passed (Default) and logfile is defined, enable verbose for them and transcript the session. NOTE: This is the default
 if you don't modify the script!
Example: 
PS>. .\my-function.ps1
PS>My-Function
# Result: Function is called and executed, all messages show on the screen and are recorded in a logfile in the current directory.

3. If -Verbose is passed and logfile is defined, show messages on the screen and transcript the session.
Example: 
PS>. .\my-function.ps1
PS>My-Function -Verbose
# Result: Function is called and executed, all messages show on the screen and are recorded in a logfile in the current directory.

4. If -Verbose is passed and logfile is zero length (''), show messages on the screen, but don't transcript the session.
Example: 
PS>. .\my-function.ps1
PS>My-Function -Verbose -Logfile ''
# Result: Function is called and executed, all messages show on the screen BUT ARE NOT recorded in a logfile in the current directory.

#>

    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = $MyInvocation.MyCommand.Path.DirectoryName + (Get-Date -Format "yyyy-MM-dd") +
         "-" + $MyInvocation.MyCommand.Name + ".log"
		
    )
    
    Begin
    {       
        
        <#######<Default Begin Block>#######>
        Function Write-Output
        {
            <# 
        .Synopsis
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Description
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Parameter InputObject
        This can be any PSObject that will be converted to string.
        .Parameter Color
        The color in which to display the string on the screen.
        Valid options are: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, 
        Red, White, and Yellow.
        .Example 
        Write-Output "Hello Hello"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen and the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen in default text colors.
        .Example 
        Write-Output "Hello Hello" -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow and to the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Example 
        Write-Output (cmd /c "ipconfig /all") -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow that shows the computer's IP information.
        The same copy will be in the logfile. 
        The whole point of converting to strings is this works best with tables and such that usually distort in logfiles.
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Notes
        2018-06-13: v1.0 Initial function
        #>
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color
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
        Set-Alias -Name Log -Value Write-Output

        If ($($Logfile.Length) -gt 1)
        {
            $Global:EnabledLogging = $True 
            Set-Variable -Name Logfile -Value $Logfile -Scope Global
            $VerbosePreference = "Continue"
            Function Start-Log
            {
                <#
                .Synopsis
                Function to write the opening part of the logfile.
                .Description
                Function to write the opening part of the logfil.
                It creates the directory if it doesn't exists and then the log file automatically.
                It checks the size of the file if it already exists and clears it if it is over 10 MB.
                If it exists, it creates a header. This function is best placed in the "Begin" block of a script.
                .Notes
                NOTE: The function requires the Write-Output function.
                2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                2017-10-19: v1.0 Initial function
                #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
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
                    Write-Output "Logfile has been cleared due to size"
                }
                Else
                {
                    Write-Output "Logfile was less than 10 MB"   
                }
                # Start writing to logfile
                Start-Transcript -Path $Logfile -Append 
                Write-Output "####################<Script>####################"
                Write-Output "Script Started on $env:COMPUTERNAME"
            }
            Start-Log -Logfile $Logfile -Verbose

            Function Stop-Log
            {
                <# 
                    .Synopsis
                    Function to write the closing part of the logfile.
                    .Description
                    Function to write the closing part of the logfile.
                    This function is best placed in the "End" block of a script.
                    .Notes
                    NOTE: The function requires the Write-Output function.
                    2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                    2017-10-19: v1.0 Initial function 
                    #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
                Write-Output "Script Completed on $env:COMPUTERNAME"
                Write-Output "####################</Script>####################"
                Stop-Transcript
            }
			
            Function Publish-Log 
            {
                <# 
                    .Synopsis
                    Function the removes most of the fluff from Powershell Transcript files.
                    .Description
                    Function the removes most of the fluff from Powershell Transcript files.
                    .Example
                    Publish-Log -Logfile "c:\scripts\mylog.log"
                    Will remove much of the fluff from the log file and present only information between the dots.
                    #>
                    [CmdletBinding()]
                    Param
                    (
                        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                        [String]$Logfile
                    )
                # Get log file
                $Transcript = Get-Content $Logfile -raw

                # Create a tempfile
                $TempFile = $MyInvocation.MyCommand.Path.DirectoryName + "temp.txt"
                New-Item -Path $TempFile -ItemType File | Out-Null
			
                # Get all the matches for PS Headers and dump to a file
                $Transcript | 
                Select-String '(?smi)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*([\S\s]*?)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*' -AllMatches | 
                ForEach-Object {$_.Matches} | 
                ForEach-Object {$_.Value} | 
                Out-File -FilePath $TempFile -Append

                #compare the two and put the differences in a third file
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

                $Array | Out-File $Logfile -Append -Encoding ASCII
            }
        }
        Else
        {
            $Global:EnabledLogging = $False
        }
        <#######</Default Begin Block>#######>

        
    }
    
    Process
    {   
        Try
        {
               
            

        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }

    End
    {
        If ($Global:EnabledLogging)
        {
            Stop-Log -Logfile $Logfile
            Publish-Log -Logfile $Logfile
        }
        Else
        {
            $Date = $(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt")
            Write-Output "Function completed at $Date"
        }
    }
}

<#######</Body>#######>
<#######</Script>#######>