<#######<Script>#######>
<#######<Header>#######>
# Name: Get-FirewallNServiceStatus
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Get-FirewallNServiceStatus
{
    <#
.Synopsis
Gets the status of the Windows Firewall and the "Remote Desktop Services" service for a given server.
.Description
Gets the status of the Windows Firewall and the "Remote Desktop Services" service for a given server and displays it on the screen.
.Parameter Computername
Mandatory parameter that specifies the comptuer name. Local computer can be be ".".
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
.Example
Get-FirewallNServiceStatus
Displays the status of the RDS Service and the firewall status on the screen.
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $True)][String]$ComputerName = $env:Hostname,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Get-FirewallNServiceStatus.log"
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

    }
    
    Process
    {   
        Try
        {

            $Counter = 0
    
            [string]$OsName = Get-WmiObject -Query 'SELECT Caption FROM Win32_OperatingSystem' -Namespace ROOT\Cimv2 | Select-Object -ExpandProperty Caption
            Switch -Regex ($osName)
            {
                '7'
                {
                    Write-Output $osName | Timestamp; $Counter = 1; Break
                }
                # Had to put R2 first because if it matches 2008, it would just break and not keep the correct counter. Nested elseif's could be another option.
                '2008 R2'
                {
                    Write-Output $osName | Timestamp; $Counter = 3; Break
                }
                '2008'
                {
                    Write-Output $osName | Timestamp; $Counter = 2; Break
                }
                '2012 R2'
                {
                    Write-Output $osName | Timestamp; $Counter = 5; Break
                }
                '2012'
                {
                    Write-Output $osName | Timestamp; $Counter = 4; Break
                }
                '10'
                {
                    Write-Output $osName | Timestamp; $Counter = 6; Break
                }
                '2016'
                {
                    Write-Output $osName | Timestamp; $Counter = 7; Break
                }
            }

            $Status = $((Get-Service -Name TermService).Status)
            If ($Status -Like "Running")
            {
                Write-Output "RDS Service is running" | Timestamp
            }
            Else
            {
                Write-Output "RDS Service is not running" | Timestamp
            }
		
            If ($Counter -le 4)
            {
                $net = cmd /c "netsh advfirewall show all state"
                Write-Output $net | Timestamp
            }
            Else
            {
                $Gnp = Get-NetFirewallProfile | Select-Object -Property Name, Enabled
                $Gnp | ForEach-Object { $_ } | Out-File $Logfile -Encoding Ascii -Append
                Write-Host $Gnp
            }

            <# Option 2:
    $RegPath = "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile"
		$Value = (Get-Item $RegPath | ForEach-Object { Get-ItemProperty -Path $_.PSPath }).EnableFirewall
		If ($Value -eq 0)
		{
		Log "Firewall is disabled"
		}
		Elseif ($Value -eq 1)
		{
		Log "Firewall is enabled"
		}
		Else
		{
		Log "Unable to determine state of firewall"
		}
		#>
    

        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }

    End
    {
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