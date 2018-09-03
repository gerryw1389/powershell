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
    .Example
    Set-VPN
    Sets up a L2TP connection in Windows 10. The script contains no parameters and expects you to change the information in it.
    #>

    [Cmdletbinding()]
    
    Param
    (
    )
    
    Begin
    {   
    }
    
    Process
    {   
        $VpnName = "Datacenter"
        $Pre = Read-Host -Prompt "Enter Preshared Key"

        $Params = @{
            Name                = $VpnName
            ServerAddress       = "server.domain.com"
            TunnelType          = "L2TP"
            EncryptionLevel     = "Required"
            AuthenicationMethod = "MSChapv2"
            L2tppsk             = $Pre
        }
        
        $VPN = Add-Vpnconnection @Params -Remembercredential -Passthru

        Start-Sleep 3

        Write-Output "Setting Registry Entry required for L2TP connections"
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
                Write-Output "Connected To Vpn"
            }
            Else
            {
                Write-Output "Not Connected To Vpn"
            } 
        }
    }

    End
    {
        $Input = Read-Host "Would You Like To Disconnect The Vpn? (Y)Yes Or (N)No"
        If ($Input -Eq 'Y')
        {
            cmd /c "Rasdial /Disconnect"
        }
        Else
        {
            Exit
        }
	}
}

<#######</Body>#######>
<#######</Script>#######>