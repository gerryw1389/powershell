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
    .Example
    $Cred = Get-Credential Domain01\User02 
    Get-ComputerInfo -ComputerName Server01, Server02 -Credential $Cred
    .Functionality
    NOTE: I had an issue where my domain controller would only connect as DCOM even though WSMAN was running. The fix was to set it as the default DNS server and remove the secondary. YMMV.
    NOTE: If you have to, run "winrm quickconfig" to set computers up to use WSMAN.
    #>

    Param
    (
        [Parameter(Position = 0, Mandatory = $False, ValueFromPipeline = $True)][alias("CN")]
        [string[]]$ComputerName = $Env:COMPUTERNAME, 
        
        [Parameter(Position = 1, Mandatory = $True)][System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty

    )
    
    Begin
    {
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
                        $Progress = @{
                            'Activity' = "Getting Sytem Information..." 
                            'Status' = ("Percent Complete:" + "{0:N0}" -f ((($i++) / $ComputerName.count) * 100) + "%")
                            'CurrentOperation' = "Processing $($Computer)..."
                            'PercentComplete' = ((($j++) / $ComputerName.count) * 100)
                        }
                        
                        Write-Progress @Progress
                        
                        Write-Output "Connecting to computer: $Computer"
                        # Get a session to the remote computer using WSMAN, if it fails - use DCOM instead
                        Try
                        {
                            $Options = New-CimSessionOption -Protocol WSMAN
                            $CimSession = New-CimSession -ComputerName $Computer -Credential $Credential -SessionOption $Options -ErrorAction Stop
                            Write-Output "Using protocol: WSMAN" 
                        }
                        Catch
                        {
                            $Options = New-CimSessionOption -Protocol DCOM
                            $CimSession = New-CimSession -ComputerName $Computer -Credential $Credential -SessionOption $Options
                            Write-Output "Using protocol: DCOM" 
                        }
                        
                        $computerSystem = Get-CimInstance CIM_ComputerSystem -CimSession $CimSession
                        $computerBIOS = Get-CimInstance CIM_BIOSElement -CimSession $CimSession
                        $computerOS = Get-CimInstance CIM_OperatingSystem -CimSession $CimSession
                        $computerCPU = Get-CimInstance CIM_Processor -CimSession $CimSession
                        $computerHDD = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID = 'C:'" -CimSession $CimSession

                        $ComputerObject = [Ordered]@{
                        'ComputerName' = $computerSystem.Name
                        'LastReboot' = $computerOS.LastBootUpTime
                        'OperatingSystem' = $computerOS.OSArchitecture + " " + $computerOS.caption
                        'Model' = $computerSystem.Model
                        'Bios' = $computerBIOS.Name
                        'CPU' = $computerCPU.Name
                        'RAM' = "{0:N2}" -f [int]($computerSystem.TotalPhysicalMemory / 1GB) + "GB"
                        'DiskCapacity' = "{0:N2}" -f ($computerHDD.Size / 1GB) + "GB"
                        'TotalDiskSpace' = "{0:P2}" -f ($computerHDD.FreeSpace / $computerHDD.Size) +
                         " Free (" + "{0:N2}" -f ($computerHDD.FreeSpace / 1GB) + "GB)"
                        'CurrentUser' = $computerSystem.UserName
                        }

                        [Void]$ComputerObjects.Add($ComputerObject)
                        
                        Remove-CimSession -CimSession $CimSession 
                    }
                    Else
                    {
                        Write-Output "Remote computer was not online."
                        $ComputerObject = [Ordered]@{
                            'ComputerName' = "Value is null. Make sure computer name is not blank"
                            'LastReboot' = "Unable to ping. Make sure the computer is turned on and ICMP inbound ports are opened."
                            'OperatingSystem' = "$null"
                            'Model' = "$null"
                            'Bios' = "$null"
                            '.CPU' = "$null"
                            'RAM' = "$null"
                            'DiskCapacity' = "$null"
                            'TotalDiskSpace' = "$null"
                            'CurrentUser' = "$null"
                        }
                        [Void]$ComputerObjects.Add($ComputerObject)                     
                    }
                }
                Else
                {
                    Write-Output "Computer name was not in a usable format"
                    $ComputerObject = [Ordered]@{
                    'ComputerName' = "Value is null. Make sure computer name is not blank"
                    'LastReboot' = "$Null"
                    'OperatingSystem' = "$null"
                    'Model' = "$null"
                    'Bios' = "$null"
                    '.CPU' = "$null"
                    'RAM' = "$null"
                    'DiskCapacity' = "$null"
                    'TotalDiskSpace' = "$null"
                    'CurrentUser' = "$null"
                    }
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
    }
}

<#######</Body>#######>
<#######</Script>#######>