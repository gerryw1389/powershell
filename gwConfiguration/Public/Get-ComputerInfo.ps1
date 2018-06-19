<#######<Script>#######>
<#######<Header>#######>
# Name: Get-ComputerInfo
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Get-ComputerInfo
{
    <#
    .Synopsis
    Retrieve basic system information for specified workstation(s) 
    .Description
    Retrieve basic system information for specified workstation(s) 
    .Parameter Logfile
    Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
    NOTE: If you wish to delete the Logfile, I have updated my scripts to where they should still run fine with no Logging.
    .Example
    $Cred = Get-Credential Domain01\User02 
    Get-ComputerInfo -ComputerName Server01, Server02 -Credential $Cred
    .Notes
    2017-09-08: v1.0 Initial script 
    .Functionality
    NOTE: I had an issue where my domain controller would only connect as DCOM even though WSMAN was running. The fix was to set it as the default DNS server and remove the secondary. YMMV.
    NOTE: If you have to, run "winrm quickconfig" to set computers up to use WSMAN.
    Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
    Main code usually starts around line 185ish.
    If -Verbose is not passed (Default) and logfile is not defined, don't show messages on the screen and don't transcript the session.
    If -Verbose is not passed (Default) and logfile is defined, enable verbose for them and transcript the session.
    If -Verbose is passed and logfile is defined, show messages on the screen and transcript the session.
    If -Verbose is passed and logfile is not defined, show messages on the screen, but don't transcript the session.
    2018-06-17: v1.1 Updated template.
    2017-09-08: v1.0 Initial script 
    #>

    param
    (
        [Parameter(Position = 0, Mandatory = $False, ValueFromPipeline = $True)][alias("CN")]
        [string[]]$ComputerName = $Env:COMPUTERNAME, 
        
        [Parameter(Position = 1, Mandatory = $True)][System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Get-ComputerInfo.Log" 
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

        # Initialize counters
        $i = 0
        $j = 0
        $ComputerObjects = [System.Collections.ArrayList]@()

        
    }
    Process
    {
        Try
        {
            Foreach ($Computer in $ComputerName)
            {
                If (!([String]::IsNullOrWhiteSpace($Computer)))
                {
                    If (Test-Connection -Quiet -Count 1 -Computer $Computer)
                    {
                        $Progress = @{}
                        $Progress.Activity = "Getting Sytem Information..." 
                        $Progress.Status = ("Percent Complete:" + "{0:N0}" -f ((($i++) / $ComputerName.count) * 100) + "%")
                        $Progress.CurrentOperation = "Processing $($Computer)..."
                        $Progress.PercentComplete = ((($j++) / $ComputerName.count) * 100)
                        Write-Progress @Progress
                        
                        Write-ToString "Connecting to computer: $Computer"
                        # Get a session to the remote computer using WSMAN, if it fails - use DCOM instead
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
                        
                        $computerSystem = Get-CimInstance CIM_ComputerSystem -CimSession $CimSession
                        $computerBIOS = Get-CimInstance CIM_BIOSElement -CimSession $CimSession
                        $computerOS = Get-CimInstance CIM_OperatingSystem -CimSession $CimSession
                        $computerCPU = Get-CimInstance CIM_Processor -CimSession $CimSession
                        $computerHDD = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID = 'C:'" -CimSession $CimSession

                        $ComputerObject = [Ordered]@{}
                        $ComputerObject.ComputerName = $computerSystem.Name
                        $ComputerObject.LastReboot = $computerOS.LastBootUpTime
                        $ComputerObject.OperatingSystem = $computerOS.OSArchitecture + " " + $computerOS.caption
                        $ComputerObject.Model = $computerSystem.Model
                        $ComputerObject.Bios = $computerBIOS.Name
                        $ComputerObject.CPU = $computerCPU.Name
                        $ComputerObject.RAM = "{0:N2}" -f [int]($computerSystem.TotalPhysicalMemory / 1GB) + "GB"
                        $ComputerObject.DiskCapacity = "{0:N2}" -f ($computerHDD.Size / 1GB) + "GB"
                        $ComputerObject.TotalDiskSpace = "{0:P2}" -f ($computerHDD.FreeSpace / $computerHDD.Size) + " Free (" + "{0:N2}" -f ($computerHDD.FreeSpace / 1GB) + "GB)"
                        $ComputerObject.CurrentUser = $computerSystem.UserName
                        

                        [Void]$ComputerObjects.Add($ComputerObject)
                        
                        Remove-CimSession -CimSession $CimSession 
                    }
                    Else
                    {
                        Write-ToString "Remote computer was not online."
                        $ComputerObject = [Ordered]@{}
                        $ComputerObject.ComputerName = $computer
                        $ComputerObject.LastReboot = "Unable to ping. Make sure the computer is turned on and ICMP inbound ports are opened."
                        $ComputerObject.OperatingSystem = "$null"
                        $ComputerObject.Model = "$null"
                        $ComputerObject.Bios = "$null"
                        $ComputerObject.CPU = "$null"
                        $ComputerObject.RAM = "$null"
                        $ComputerObject.DiskCapacity = "$null"
                        $ComputerObject.TotalDiskSpace = "$null"
                        $ComputerObject.CurrentUser = "$null"

                        [Void]$ComputerObjects.Add($ComputerObject)                     
                    }
                
                
                }
                Else
                {
                    Write-ToString "Computer name was not in a usable format"
                    $ComputerObject.ComputerName = "Value is null. Make sure computer name is not blank"
                    $ComputerObject.LastReboot = "$Null"
                    $ComputerObject.OperatingSystem = "$null"
                    $ComputerObject.Model = "$null"
                    $ComputerObject.Bios = "$null"
                    $ComputerObject.CPU = "$null"
                    $ComputerObject.RAM = "$null"
                    $ComputerObject.DiskCapacity = "$null"
                    $ComputerObject.TotalDiskSpace = "$null"
                    $ComputerObject.CurrentUser = "$null"

                    [Void]$ComputerObjects.Add($ComputerObject)   
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
        $ComputerObjects
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