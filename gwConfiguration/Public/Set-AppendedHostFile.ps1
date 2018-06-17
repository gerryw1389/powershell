<#######<Script>#######>
<#######<Header>#######>
# Name: Set-AppendedHostFile
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
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
    .Parameter Logfile
    Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
    NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
    .Example
    Set-AppendedHostFile
    Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
    .Example
    "Pc2", "Pc1" | Set-AppendedHostFile
    Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
    .Notes
    Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
    Main code usually starts around line 185ish.
    If -Verbose is not passed (Default) and logfile is not defined, don't show messages on the screen and don't transcript the session.
    If -Verbose is not passed (Default) and logfile is defined, enable verbose for them and transcript the session.
    If -Verbose is passed and logfile is defined, show messages on the screen and transcript the session.
    If -Verbose is passed and logfile is not defined, show messages on the screen, but don't transcript the session.
    2018-06-17: v1.1 Updated template.
    2017-09-08: v1.0 Initial script 
    #>
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-AppendedHostFile.Log"
    )

    Begin
    {
        <#######<Default Begin Block>#######>
        Function Write-ToString
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
        Write-ToString "Hello Hello"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen and the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen in default text colors.
        .Example 
        Write-ToString "Hello Hello" -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow and to the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Example 
        Write-ToString (cmd /c "ipconfig /all") -Color "Yellow"
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
                NOTE: The function requires the Write-ToString function.
                2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                2017-10-19: v1.0 Initial function
                #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
                # Create parent path and logfile if it doesn't exist
                $Regex = '([^\\]*)$'
                $Logparent = $Logfile -Replace $Regex
                If (!(Test-Path $Logparent))
                {
                    New-Item -Itemtype Directory -Path $Logparent -Force | Out-Null
                }
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
                    Write-ToString "Logfile has been cleared due to size"
                }
                Else
                {
                    Write-ToString "Logfile was less than 10 MB"   
                }
                # Start writing to logfile
                Start-Transcript -Path $Logfile -Append 
                Write-ToString "####################<Script>####################"
                Write-ToString "Script Started on $env:COMPUTERNAME"
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
                    NOTE: The function requires the Write-ToString function.
                    2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                    2017-10-19: v1.0 Initial function 
                    #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
                Write-ToString "Script Completed on $env:COMPUTERNAME"
                Write-ToString "####################</Script>####################"
                Stop-Transcript
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
        # Get Hostfile Values From Winhelp2002.Mvps.Org, Github, And Someonewhocares.Org And Store Them In Separate Text Files
        $Hfv = Invoke-Webrequest "http://winhelp2002.mvps.org/hosts.txt"
        New-Item -Itemtype File -Path "$PSScriptRoot\Hfv.txt" -Value $Hfv.Content  | Out-Null
        Write-ToString "Created $PSScriptRoot hfv.txt from winhelp2002"
        $Hfv2 = Invoke-Webrequest "https://raw.githubusercontent.com/stevenblack/hosts/master/hosts"
        New-Item -Itemtype File -Path "$PSScriptRoot\Hfv2.txt" -Value $Hfv2.Content  | Out-Null
        Write-ToString "Created $PSScriptRoot hfv2.txt from Github"
        $Hfv3 = Invoke-Webrequest "http://someonewhocares.org/hosts/"
        New-Item -Itemtype File -Path "$PSScriptRoot\Hfv3.txt" -Value $Hfv3.Content  | Out-Null
        Write-ToString "Created $PSScriptRoot hfv3.txt from someonewhocares.org"
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
        Write-ToString "Cleaning The File By Removing Anything That Is Not A 0 Or 1"
        $B = Get-Content "$PSScriptRoot\combined.txt" | Where-Object { $_ -Match "^0" -Or $_ -Match "^1"}
        $C = -Join $A, $B
        Write-ToString "Replace All 127.0.0.1 With 0.0.0.0"
        $D = $C.Replace("127.0.0.1", "0.0.0.0")

        Write-ToString "Sort Alphabetically And Remove Duplicates"
        $E = $D | Sort-Object | Get-Unique
        $E | Out-File "$PSScriptRoot\host.txt"

        Write-ToString "Appending To The Current Windows Host File"
        Add-Content -Value $E -Path "$($Env:Windir)\System32\Drivers\Etc\Hosts"

        # Clean Up
        Write-ToString "Deleting Txt Files Created By Script"
        Remove-Item -Path "$PSScriptRoot\combined.txt"
        Remove-Item -Path "$PSScriptRoot\Hfv.txt"
        Remove-Item -Path "$PSScriptRoot\Hfv2.txt"
        Remove-Item -Path "$PSScriptRoot\Hfv3.txt"
        Remove-Item -Path "$PSScriptRoot\host.txt"
    }

    End
    {
        If ($Global:EnabledLogging)
        {
            Stop-Log -Logfile $Logfile
        }
        Else
        {
            $Date = $(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt")
            Write-Output "Function completed at $Date"
        }
    
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