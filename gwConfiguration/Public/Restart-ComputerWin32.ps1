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
Write-Outputs off Server01 and Server02 | TimeStamp
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
     
        Write-Output "Action set to $Action" | TimeStamp
    }
 
    Process
    {
        Try
        {
            ForEach ($Computer in $ComputerName)
            {
                Write-Output "Attempting to connect to $Computer" | TimeStamp
     
                If ($Pscmdlet.ShouldProcess($Computer, "$Action"))
                {
                    Get-Wmiobject Win32_Operatingsystem -Computername $Computer |
                        Invoke-Wmimethod -Name Win32shutdown -Argumentlist $_Action
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
        If ($EnableLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>