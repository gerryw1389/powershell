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
#>

    param
    (
        [Parameter(Position = 0, Mandatory = $False, ValueFromPipeline = $True)][alias("CN")][string[]]$ComputerName = $Env:COMPUTERNAME, 
        
        [Parameter(Position = 1, Mandatory = $True)][System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Get-ComputerInfo.Log" 
    )
    
    Begin
    {
        
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        If ($($Logfile.Length) -gt 1)
        {
            $EnabledLogging = $True
        }
        Else
        {
            $EnabledLogging = $False
        }
        
        Filter Timestamp
        {
            "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $_"
        }

        If ($EnabledLogging)
        {
            # Create parent path and Logfile if it doesn't exist
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
            $Sizemax = 10
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            $Sizemb = "{0:N2}" -F ($Size.Sum / 1mb) + "Mb"
            If ($Sizemb -Ge $Sizemax)
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            # Start writing to Logfile
            Start-Transcript -Path $Logfile -Append 
            Write-Output "####################<Script>####################"
            Write-Output "Script Started on $env:COMPUTERNAME" | TimeStamp
        }

        # Initialize counters
        $i = 0
        $j = 0
        $ComputerObjects = @()

        
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
                        
                        Write-Output "Connecting to computer: $Computer" | Timestamp
                        # Get a session to the remote computer using WSMAN, if it fails - use DCOM instead
                        Try
                        {
                            $Options = New-CimSessionOption -Protocol WSMAN
                            $CimSession = New-CimSession -ComputerName $Computer -Credential $Credential -SessionOption $Options -ErrorAction Stop
                            Write-Output "Using protocol: WSMAN" | Timestamp 
                        }
                        Catch
                        {
                            $Options = New-CimSessionOption -Protocol DCOM
                            $CimSession = New-CimSession -ComputerName $Computer -Credential $Credential -SessionOption $Options
                            Write-Output "Using protocol: DCOM" | Timestamp 
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
                        $ComputerObject.RAM = "{0:N2}" -f [int]($computerSystem.TotalPhysicalMemory / 1GB) + "GB"
                        $ComputerObject.DiskCapacity = "{0:N2}" -f ($computerHDD.Size / 1GB) + "GB"
                        $ComputerObject.TotalDiskSpace = "{0:P2}" -f ($computerHDD.FreeSpace / $computerHDD.Size) + " Free (" + "{0:N2}" -f ($computerHDD.FreeSpace / 1GB) + "GB)"
                        $ComputerObject.CurrentUser = $computerSystem.UserName
 
                        $ComputerObjects += $ComputerObject
                        
                        Remove-CimSession -CimSession $CimSession 
                    }
                    Else
                    {
                        Write-Output "Remote computer was not online." | Timestamp
                        $ComputerObject = [Ordered]@{}
                        $ComputerObject.ComputerName = $computer
                        $ComputerObject.LastReboot = "Unable to ping. Make sure the computer is turned on and ICMP inbound ports are opened."
                        $ComputerObject.OperatingSystem = "$null"
                        $ComputerObject.Model = "$null"
                        $ComputerObject.RAM = "$null"
                        $ComputerObject.DiskCapacity = "$null"
                        $ComputerObject.TotalDiskSpace = "$null"
                        $ComputerObject.CurrentUser = "$null"

                        $ComputerObjects += $ComputerObject                     
                    }
                
                
                }
                Else
                {
                    Write-Output "Computer name was not in a usable format" | Timestamp
                    $ComputerObject.ComputerName = "Value is null. Make sure computer name is not blank"
                    $ComputerObject.LastReboot = "$Null"
                    $ComputerObject.OperatingSystem = "$null"
                    $ComputerObject.Model = "$null"
                    $ComputerObject.RAM = "$null"
                    $ComputerObject.DiskCapacity = "$null"
                    $ComputerObject.TotalDiskSpace = "$null"
                    $ComputerObject.CurrentUser = "$null"

                    $ComputerObjects += $ComputerObject   
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
        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }
}

<#######</Body>#######>
<#######</Script>#######>