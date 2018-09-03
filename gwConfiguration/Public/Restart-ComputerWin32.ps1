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
    Restarts, shuts down, logs off, or powers down one or more computers. This relies on WMI's Win32_OperatingSystem class. 
    Supports common parameters -verbose, -whatif, and -confirm.
    .Parameter Computername
    One or more computer names to operate against. Accepts pipeline input ByValue and ByPropertyName.
    .Parameter Action
    Can be Restart, LogOff, Shutdown, or PowerOff
    .Parameter Force
    $True or $False to force the action; defaults to $false
    .Example
    Restart-ComputerWin32 -ComputerName "Server01", "Server02" -Action "Logoff" -Force
    Log off Server01 and Server02
    .Example
    'localhost', 'server1' | Restart-ComputerWin32 -Action "LogOff" -Whatif
    This doesn't actually happen! It just shows what would: Pipelined in, the computers localhost and Server1 will be logged off of.
    #>
    
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    
    Param 
    (
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$computerName,

        [Parameter(Position = 1, Mandatory = $true)][System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,
     
        [parameter(Position = 2, Mandatory = $true)][string]
        [ValidateSet("Restart", "LogOff", "Shutdown", "PowerOff")]
        $Action,
     
        [Switch]$Force
    )
    
    Begin
    {
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
     
        Write-Output "Action set to $Action"
    }
 
    Process
    {
        Try
        {
            ForEach ($Computer in $ComputerName)
            {
                If (!([String]::IsNullOrWhiteSpace($Computer)))
                {
                    If (Test-Connection -Quiet -Count 1 -Computer $Computer)
                    {
                        Write-Output "Attempting to connect to $Computer"
    
                        If ($Pscmdlet.ShouldProcess($Computer, "$Action"))
                        {
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
                            Invoke-CimMethod -MethodName Win32Shutdown -ClassName Win32_OperatingSystem -Arguments @{ Flags = $_action } -CimSession $CimSession
                            Remove-CimSession -CimSession $CimSession  
                        }
        
                    }
                    Else
                    {
                        Write-Output "Computer was not online"
                    }
                }
                Else
                {
                    Write-Output "Computer name was in an invalid format"
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
        
    }

}

<#######</Body>#######>
<#######</Script>#######>