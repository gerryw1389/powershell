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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging..Example
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
        $VpnName = "Datacenter"
        $Pre = Read-Host -Prompt "Enter Preshared Key"

        $Params = @{}
        $Params.Name = $VpnName
        $Params.ServerAddress = "server.domain.com"
        $Params.TunnelType = "L2TP"
        $Params.EncryptionLevel = "Required"
        $Params.AuthenicationMethod = "MSChapv2"
        $Params.L2tppsk = $Pre
        
        $VPN = Add-Vpnconnection @Params -Remembercredential -Passthru

        Start-Sleep 3

        Write-Output "Setting Registry Entry required for L2TP connections" | Timestamp
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
                Write-Output "Connected To Vpn" | Timestamp
            }
            Else
            {
                Write-Output "Not Connected To Vpn" | Timestamp
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