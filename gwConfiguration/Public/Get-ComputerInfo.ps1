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
.Example
$Cred = Get-Credential Domain01\User02 
Get-ComputerInfo -ComputerName Server01, Server02 -Credsential $Cred
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    param
    (
        [Parameter(Position = 0, Mandatory = $False, ValueFromPipeline = $True)][alias("CN")][string[]]$ComputerName = $Env:COMPUTERNAME, 
    
        [Parameter(Position = 1, Mandatory = $True)][System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Get-ComputerInfo.log" 
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
            $Sizemax = 10
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            $Sizemb = "{0:N2}" -F ($Size.Sum / 1mb) + "Mb"
            If ($Sizemb -Ge $Sizemax)
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            # Start writing to logfile
            Start-Transcript -Path $Logfile -Append 
            Write-Output "####################<Script>####################"
            Write-Output "Script Started on $env:COMPUTERNAME" | TimeStamp
        }

        Function Get-LHSCimSession  
        { 
            <# 
.SYNOPSIS 
    Create CIMSessions to retrieve WMI data. 
.DESCRIPTION 
    The Get-CimInstance cmdlet in PowerShell V3 can be used to retrieve WMI information 
    from a remote computer using the WSMAN protocol instead of the legacy WMI service 
    that uses DCOM and RPC. However, the remote computers must be running PowerShell 
    3 and WSMAN protocol version 3. When querying a remote computer, 
    Get-CIMInstance setups a temporary CIMSession. However, if the remote computer is 
    running PowerShell 2.0 this will fail. You have to manually create a CIMSession 
    with a CIMSessionOption to use the DCOM protocol. This Script does it for you 
    and creates a CimSession depending on the remote Computer capabilities. 
.PARAMETER ComputerName 
    The computer name(s) to connect to.  
    Default to local Computer 
.PARAMETER Credential 
    [Optional] alternate Credential to connect to remote computer. 
.EXAMPLE 
    $CimSession = Get-LHSCimSession -ComputerName PC1 
    $BIOS = Get-CimInstance -ClassName Win32_BIOS -CimSession $CimSession 
    Remove-CimSession -CimSession $CimSession 
.EXAMPLE 
    $cred = Get-Credential Domain01\User02  
    $CimSession = Get-LHSCimSession -ComputerName PC1 -Credential $cred 
    $Volume = Get-CimInstance -ClassName Win32_Volume -Filter "Name = 'C:\\'" -CimSession $CimSession 
    Remove-CimSession -CimSession $CimSession  
.INPUTS 
    System.String, you can pipe ComputerNames to this Function 
.OUTPUTS 
    Microsoft.Management.Infrastructure.CimSession 
.NOTES 
    to get rid of CimSession because of testing use the following to remove all CimSessions 
    Get-CimSession | Remove-CimSession -whatif 
    Most of the CIM Cmdlets do not have a -Credential parameter. The only way to specify  
    alternate credentials is to manually build a new CIM session object, and pass that  
    into the -CimSession parameter on the other cmdlets. 
    AUTHOR: Pasquale Lantella  
    LASTEDIT:  
    KEYWORDS: CIMSession 
.LINK 
    http://jdhitsolutions.com/blog/2013/04/get-ciminstance-from-powershell-2-0/ 
#Requires -Version 3.0 
#> 
            [cmdletbinding()]   
            [OutputType('Microsoft.Management.Infrastructure.CimSession')]  
    
            Param
            ( 
                [Parameter(Position = 0, Mandatory = $False, ValueFromPipeline = $True)][alias("CN")][string[]]$ComputerName = $Env:COMPUTERNAME, 
    
                [Parameter()][System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty 
            ) 
    
            Begin
            { 
                Set-StrictMode -Version Latest 
                ${CmdletName} = $Pscmdlet.MyInvocation.MyCommand.Name 
                Function Test-IsWsman3
                { 
                    # Test if WSMan is greater or eqaul Version 3.0 
                    # Tested against Powershell 4.0 
                    [cmdletbinding()] 
                    Param( 
                        [Parameter(Position = 0, ValueFromPipeline)] 
                        [string]$Computername = $env:computername 
                    ) 
                    Begin
                    { 
                        #a regular expression pattern to match the ending 
                        [regex]$rx = "\d\.\d$" 
                    } 
                    Process
                    { 
                        $result = $Null 
                        Try
                        { 
                            $result = Test-WSMan -ComputerName $Computername -ErrorAction Stop 
                        } 
                        Catch
                        { 
                            $False 
                        } 
                        if ($result)
                        { 
                            $m = $rx.match($result.productversion).value 
                            if ($m -ge '3.0')
                            { 
                                $True 
                            } 
                            else
                            { 
                                $False 
                            } 
                        } 
                    } 
                    End
                    {
                    } 
                } 
            } 
    
            Process
            { 
                Write-Verbose "${CmdletName}: Starting Process Block" 
                Write-Debug ("PROCESS:`n{0}" -f ($PSBoundParameters | Out-String)) 
                ForEach ($Computer in $ComputerName)  
                { 
                    IF (Test-Connection -ComputerName $Computer -count 2 -quiet)
                    {  
                        $SessionParams = @{ 
                            ComputerName = $Computer 
                            ErrorAction  = 'Stop' 
                        }  
                        if ($PSBoundParameters['Credential'])   
                        { 
                            Write-Verbose "Adding alternate credential for CIMSession" 
                            $SessionParams.Add("Credential", $Credential) 
                        } 
                        If (Test-IsWsman3 –ComputerName $Computer) 
                        { 
                            $option = New-CimSessionOption -Protocol WSMan  
                            $SessionParams.SessionOption = $Option   
                        } 
                        Else 
                        { 
                            $option = New-CimSessionOption -Protocol DCOM 
                            $SessionParams.SessionOption = $Option  
                        } 
                        New-CimSession @SessionParams 
                    }
                    Else
                    { 
                        Write-Warning "\\$computer DO NOT reply to ping"  
                    }
                }
            }
    
            End
            {
                Write-Verbose "Function ${CmdletName} finished." 
            } 
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
    
                        $CimSession = Get-LHSCimSession -ComputerName $Computer -Credential $Credential

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
        
                        Write-Output "ComputerName: $($ComputerObject.ComputerName.ToString())" | Timestamp
                        Write-Output "LastReboot: $($ComputerObject.LastReboot.ToString())" | Timestamp
                        Write-Output "OperatingSystem: $($ComputerObject.OperatingSystem.ToString())" | Timestamp
                        Write-Output "Ram: $($ComputerObject.RAM.ToString())" | Timestamp
                        Write-Output "TotalDiskSpace: $($ComputerObject.TotalDiskSpace.ToString())" | Timestamp
                        Write-Output "CurrentUser: $($ComputerObject.CurrentUser.ToString())" | Timestamp
                        Write-Output "####################<Break>####################" | Timestamp

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
        # I prefer to check the log file instead of showing the output on the screen so I commented out. My log command outputs to screen and log file.
        # Write-Output $ComputerObjects
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