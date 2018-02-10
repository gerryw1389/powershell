<#######<Script>#######>
<#######<Header>#######>
# Name: Set-VPN
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-VPN
{
    <#
.Synopsis
Sets up a L2TP connection in Windows 10. The script contains no parameters and expects you to change the information in it.
.Description
Sets up a L2TP connection in Windows 10. Uses MSChapv2 with Preshared key.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/

.Example
Set-VPN
Sets up a L2TP connection in Windows 10. The script contains no parameters and expects you to change the information in it.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-VPN.log"
    )
    
    Begin
    {       
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
		Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log 
    }
    
    Process
    {   
        
        
        
        $VpnName = "Datacenter"
        $Pre = Read-Host -Prompt "Enter Preshared Key"

        $VPN = Add-Vpnconnection -Name $VpnName -Serveraddress "server.domain.com" -Tunneltype L2tp -Encryptionlevel Required `
            -Authenticationmethod Mschapv2 -L2tppsk $Pre -Remembercredential -Passthru

        Start-Sleep 3

        Log "Setting Registry Entry required for L2TP connections"
        $Registrypath = "Hklm:\System\Currentcontrolset\Services\Policyagent"
        $Name = "AssumeUDPEncapsulationContextOnSendRule"
        $Value = "2"
        If (!(Test-Path $Registrypath))
        {
            New-Item -Path $Registrypath -Force | Out-Null
        }
        New-Itemproperty -Path $Registrypath -Name $Name -Value $Value -Propertytype Dword -Force | Out-Null

        If ($Vpn.Connectionstatus -Eq "Disconnected")
        {
            $Password = Read-Host -Prompt "Enter User Password For VPN"
            # Connect to the VPN using your user account and password
            Cmd /c "Rasdial $VpnName domain\user $Password"
    
            Start-Sleep 3

            # Connect To a host on the destination network
            If ( Test-Netconnection 10.0.0.81 -Informationlevel Quiet)
            {
                Log "Connected To Vpn"
            }
            Else
            {
                Log "Not Connected To Vpn"
            } 
        }
    }

    End
    {
        $Input = Read-Host "Would You Like To Disconnect The Vpn? (Y)Yes Or (N)No"
        If ($Input -Eq 'Y')
        {
            Cmd /c "Rasdial /Disconnect"
        }
        Else
        {
            Exit
        }
	
	
        Stop-Log  
    }

}

# Set-VPN

<#######</Body>#######>
<#######</Script>#######>