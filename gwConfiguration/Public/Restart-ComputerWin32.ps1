<#######<Script>#######>
<#######<Header>#######>
# Name: Restart-ComputerWin32
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Restart-ComputerWin32
{
    <#
    .SYNOPSIS
    Restart, Logoff, Shutdown, or Poweroff one or more computers using the WMI Win32_OperatingSystem method.
    .DESCRIPTION
    Restarts, shuts down, logs off, or powers down one or more computers. This relies on WMI's Win32_OperatingSystem class. 
    Supports common parameters -verbose, -whatif, and -confirm.
    .Parameter Computername
    One or more computer names to operate against. Accepts pipeline input ByValue and ByPropertyName.
    .Parameter Action
    Can be Restart, LogOff, Shutdown, or PowerOff
    .Parameter Force
    $True or $False to force the action; defaults to $false
    .Parameter Logfile
    Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
    .Example
    Restart-ComputerWin32 -ComputerName "Server01", "Server02" -Action "Logoff" -Force
    Log off Server01 and Server02
    .Example
    'localhost', 'server1' | Restart-ComputerWin32 -Action "LogOff" -Whatif
    This doesn't actually happen! It just shows what would: Pipelined in, the computers localhost and Server1 will be logged off of.
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
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param 
    (
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$computerName,

        [Parameter(Position = 1, Mandatory = $true)][System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,
     
        [parameter(Position = 2, Mandatory = $true)][string]
        [ValidateSet("Restart", "LogOff", "Shutdown", "PowerOff")]
        $Action,
     
        [Switch]$Force,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-Template.Log"
     
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
    
        # Translate action to numeric value required by the method
        Switch ($Action)
        {
            "Restart"
            {
                $_action = 2
                break
            }
            "LogOff"
            {
                $_action = 0
                break
            }
            "Shutdown"
            {
                $_action = 2
                break
            }
            "PowerOff"
            {
                $_action = 8
                break
            }
        }
     
        # To force, add 4 to the value
        If ($Force)
        {
            $_action += 4
        }
     
        Write-ToString "Action set to $Action"
    }
 
    Process
    {
        Try
        {
            ForEach ($Computer in $ComputerName)
            {
                If (!([String]::IsNullOrWhiteSpace($Computer)))
                {
                    If (Test-Connection -Quiet -Count 1 -Computer $Computer)
                    {
                        Write-ToString "Attempting to connect to $Computer"
    
                        If ($Pscmdlet.ShouldProcess($Computer, "$Action"))
                        {
                            Try
                            {
                                $Options = New-CimSessionOption -Protocol WSMAN
                                $CimSession = New-CimSession -ComputerName $Computer -Credential $Credential -SessionOption $Options -ErrorAction Stop
                                Write-ToString "Using protocol: WSMAN"
                            }
                            Catch
                            {
                                $Options = New-CimSessionOption -Protocol DCOM
                                $CimSession = New-CimSession -ComputerName $Computer -Credential $Credential -SessionOption $Options
                                Write-ToString "Using protocol: DCOM"
                            }
                            Invoke-CimMethod -MethodName Win32Shutdown -ClassName Win32_OperatingSystem -Arguments @{ Flags = $_action } -CimSession $CimSession
                            Remove-CimSession -CimSession $CimSession  
                        }
        
                    }
                    Else
                    {
                        Write-ToString "Computer was not online"
                    }
                }
                Else
                {
                    Write-ToString "Computer name was in an invalid format"
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
        If ($Global:EnabledLogging)
        {
            Stop-Log -Logfile $Logfile
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