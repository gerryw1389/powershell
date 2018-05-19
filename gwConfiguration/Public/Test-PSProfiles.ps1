<#######<Script>#######>
<#######<Header>#######>
# Name: Test-PSProfiles
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Test-PSProfiles
{
    <#
.Synopsis
This function tests your system to see if you have the six Powershell profiles created. If you don't, it creates them with just one command: Set-Location (root). 
.Description
This function tests your system to see if you have the six Powershell profiles created. If you don't, it creates them with just one command: Set-Location (root). 
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Test-PSProfiles
This function tests your system to see if you have Powershell profiles loaded. If not, it creates them for you based on my Github template.
.Notes
2018-05-15: v1.1 Added font options and Github download 
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>   
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Test-PSProfiles.Log"
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
        
        If ($DeleteExisting)
        {
            $CurrentUserCurrentHost = "$env:userprofile\Documents\WindowsPowershell\Microsoft.Powershell_profile.ps1"
            Remove-Item $CurrentUserCurrentHost -Force
            $CurrentUserAllHost = "$env:userprofile\Documents\WindowsPowershell\profile.ps1"
            Remove-Item $CurrentUserAllHost  -Force
            $AllUsersCurrentHost = "$env:windir\System32\WindowsPowershell\v1.0\Microsoft.Powershell_profile.ps1"
            Remove-Item $AllUsersCurrentHost -Force
            $AllUsersAllHost = "$env:windir\System32\WindowsPowershell\v1.0\profile.ps1"
            Remove-Item $AllUsersAllHost  -Force
            $ISECurrentUserCurrentHost = "$env:userprofile\Documents\Microsoft.PowerShellISE_profile.ps1"
            Remove-Item $ISECurrentUserCurrentHost -Force
            $ISEAllUserAllHosts = "$env:userprofile\Documents\WindowsPowershell\Microsoft.PowerShellISE_profile.ps1"
            Remove-Item $ISEAllUserAllHosts -Force
        }

        
    }
    Process
    {   
        Try
        {
            Write-Output "Creating Powershell Profiles" | Timestamp
            $Root = $env:userprofile

            $CurrentUserCurrentHost = "$env:userprofile\Documents\WindowsPowershell\Microsoft.Powershell_profile.ps1"
            If (-not(Test-Path $CurrentUserCurrentHost))
            {
                
                New-Item -Path $CurrentUserCurrentHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $CurrentUserCurrentHost" | Timestamp
            }
            Else
            {
                Write-Output "File Already exists: $CurrentUserCurrentHost" | Timestamp
            }

            $CurrentUserAllHost = "$env:userprofile\Documents\WindowsPowershell\profile.ps1"
            If (-not(Test-Path $CurrentUserAllHost))
            {
                New-Item -Path $CurrentUserAllHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $CurrentUserAllHost" | Timestamp
            }
            Else
            {
                Write-Output "File Already exists: $CurrentUserAllHost" | Timestamp
            }

            $AllUsersCurrentHost = "$env:windir\System32\WindowsPowershell\v1.0\Microsoft.Powershell_profile.ps1"
            If (-not(Test-Path $AllUsersCurrentHost))
            {
                New-Item -Path $AllUsersCurrentHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $AllUsersCurrentHost" | Timestamp
            }
            Else
            {
                Write-Output "File Already exists: $AllUsersCurrentHost" | Timestamp
            }


            $AllUsersAllHost = "$env:windir\System32\WindowsPowershell\v1.0\profile.ps1"
            If (-not(Test-Path $AllUsersAllHost))
            {
                New-Item -Path $AllUsersAllHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $AllUsersAllHost" | Timestamp
            }
            Else
            {
                Write-Output "File Already exists: $AllUsersAllHost" | Timestamp
            }

            $ISECurrentUserCurrentHost = "$env:userprofile\Documents\Microsoft.PowerShellISE_profile.ps1"
            If (-not(Test-Path $ISECurrentUserCurrentHost))
            {
                New-Item -Path $ISECurrentUserCurrentHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $ISECurrentUserCurrentHost" | Timestamp
            }
            Else
            {
                Write-Output "File Already exists: $ISECurrentUserCurrentHost" | Timestamp
            }

            $ISEAllUserAllHosts = "$env:userprofile\Documents\WindowsPowershell\Microsoft.PowerShellISE_profile.ps1"
            If (-not(Test-Path $ISEAllUserAllHosts))
            {
                New-Item -Path $ISEAllUserAllHosts -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $ISEAllUserAllHosts" | Timestamp
            }
            Else
            {
                Write-Output "File Already exists: $ISEAllUserAllHosts" | Timestamp
            }
        
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