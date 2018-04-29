<#######<Script>#######>
<#######<Header>#######>
# Name: Restart-ComputerWin32
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Restart-ComputerWin32
{
    <#
    .SYNOPSIS
    Restart, Logoff, Shutdown, or Poweroff one or more computers using the WMI Win32_OperatingSystem method.
    .DESCRIPTION
    Restarts, shuts down, logs off, or powers down one or more computers. This relies on WMI's Win32_OperatingSystem class. Supports common parameters -verbose, -whatif, and -confirm.
    .Parameter Computername
    One or more computer names to operate against. Accepts pipeline input ByValue and ByPropertyName.
    .Parameter Action
    Can be Restart, LogOff, Shutdown, or PowerOff
    .Parameter Force
    $True or $False to force the action; defaults to $false
    .Parameter Logfile
    Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
    .Example
    Restart-ComputerWin32 -ComputerName "Server01", "Server02" -Action "Logoff" -Force
    Logs off Server01 and Server02
    .Example
    'localhost', 'server1' | Restart-ComputerWin32 -Action "LogOff" -Whatif
    This doesn't actually happen! It just shows what would: Pipelined in, the computers localhost and Server1 will be logged off of.
    .Notes
    2017-09-08: v1.0 Initial script 
    .Functionality
    Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param 
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][string[]]$computerName,
         
        [parameter(Mandatory = $true)][string]
        [ValidateSet("Restart", "LogOff", "Shutdown", "PowerOff")]
        $Action,
         
        [Switch]$Force,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-Template.Log"
         
    )
    
    Begin
    {
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Console
        Start-Log
        
        # Translate action to numeric value required by the method
        Switch ($Action)
        {
            "Restart"
            {
                $_action = 2
                break
            }
            "LogOff"
            {
                $_action = 0
                break
            }
            "Shutdown"
            {
                $_action = 2
                break
            }
            "PowerOff"
            {
                $_action = 8
                break
            }
        }
         
        # To force, add 4 to the value
        If ($Force)
        {
            $_action += 4
        }
         
        Log "Action set to $Action"
    }
 
    Process
    {
        Try
        {
            ForEach ($Computer in $ComputerName)
            {
                Log "Attempting to connect to $Computer"
         
                If ($Pscmdlet.ShouldProcess($Computer, "$Action"))
                {
                    Get-Wmiobject Win32_Operatingsystem -Computername $Computer |
                    Invoke-Wmimethod -Name Win32shutdown -Argumentlist $_Action
                }
            }
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