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
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Console
        Start-Log

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
                    Log $osName; $Counter = 1; Break 
                }
                # Had to put R2 first because if it matches 2008, it would just break and not keep the correct counter. Nested elseif's could be another option.
                '2008 R2'
                {
                    Log $osName; $Counter = 3; Break 
                }
                '2008'
                {
                    Log $osName; $Counter = 2; Break 
                }
                '2012 R2'
                {
                    Log $osName; $Counter = 5; Break 
                }
                '2012'
                {
                    Log $osName; $Counter = 4; Break 
                }
                '10'
                {
                    Log $osName; $Counter = 6; Break 
                }
                '2016'
                {
                    Log $osName; $Counter = 7; Break 
                }
            }

            $Status = $((Get-Service -Name TermService).Status)
            If ($Status -Like "Running")
            {
                Log "RDS Service is running"
            }
            Else
            {
                Log "RDS Service is not running"
            }
		
            If ($Counter -le 4)
            {
                $net = cmd /c "netsh advfirewall show all state"
                Log $net
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
            Log $($_.Exception.Message) -Error -ExitGracefully
        }
    }

    End
    {
        Stop-Log  
    }

}


<#######</Body>#######>
<#######</Script>#######>