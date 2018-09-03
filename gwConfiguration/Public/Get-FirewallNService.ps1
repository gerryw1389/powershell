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
    .Example
    Get-FirewallNServiceStatus
    Displays the status of the RDS Service and the firewall status on the screen.
    #>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $True)][String]
        $ComputerName = $env:Hostname
    )
    
    Begin
    {   
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
                    Write-Output $osName; $Counter = 1; Break
                }
                # Had to put R2 first because if it matches 2008, it would just break and not keep the correct counter. Nested elseif's could be another option.
                '2008 R2'
                {
                    Write-Output $osName; $Counter = 3; Break
                }
                '2008'
                {
                    Write-Output $osName; $Counter = 2; Break
                }
                '2012 R2'
                {
                    Write-Output $osName; $Counter = 5; Break
                }
                '2012'
                {
                    Write-Output $osName; $Counter = 4; Break
                }
                '10'
                {
                    Write-Output $osName; $Counter = 6; Break
                }
                '2016'
                {
                    Write-Output $osName; $Counter = 7; Break
                }
            }

            $Status = $((Get-Service -Name TermService).Status)
            If ($Status -Like "Running")
            {
                Write-Output "RDS Service is running"
            }
            Else
            {
                Write-Output "RDS Service is not running"
            }
		
            If ($Counter -le 4)
            {
                $net = cmd /c "netsh advfirewall show all state"
                Write-Output $net
            }
            Else
            {
                $Gnp = Get-NetFirewallProfile | Select-Object -Property Name, Enabled
                $Gnp | ForEach-Object { $_ } | Out-File $Logfile -Encoding Ascii -Append
                Write-Output $Gnp
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
    }

}

<#######</Body>#######>
<#######</Script>#######>