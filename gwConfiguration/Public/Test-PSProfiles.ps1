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
    This function tests your system to see if you have the six Powershell profiles created. If they don't exist, it creates them. 
    .Description
    This function tests your system to see if you have the six Powershell profiles created. If they don't exist, it creates them. 
    .Example
    Test-PSProfiles
    This function tests your system to see if you have Powershell profiles loaded. If not, it creates them for you based on my Github template.
    #>   
    [Cmdletbinding()]

    Param
    (
        [Switch]$DeleteExisting
    )

    Begin
    {
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
            Write-Output "Creating Powershell Profiles"
            $Root = $env:userprofile

            $CurrentUserCurrentHost = "$env:userprofile\Documents\WindowsPowershell\Microsoft.Powershell_profile.ps1"
            If (-not(Test-Path $CurrentUserCurrentHost))
            {
                
                New-Item -Path $CurrentUserCurrentHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $CurrentUserCurrentHost"
            }
            Else
            {
                Write-Output "File Already exists: $CurrentUserCurrentHost"
            }

            $CurrentUserAllHost = "$env:userprofile\Documents\WindowsPowershell\profile.ps1"
            If (-not(Test-Path $CurrentUserAllHost))
            {
                New-Item -Path $CurrentUserAllHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $CurrentUserAllHost"
            }
            Else
            {
                Write-Output "File Already exists: $CurrentUserAllHost"
            }

            $AllUsersCurrentHost = "$env:windir\System32\WindowsPowershell\v1.0\Microsoft.Powershell_profile.ps1"
            If (-not(Test-Path $AllUsersCurrentHost))
            {
                New-Item -Path $AllUsersCurrentHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $AllUsersCurrentHost"
            }
            Else
            {
                Write-Output "File Already exists: $AllUsersCurrentHost"
            }


            $AllUsersAllHost = "$env:windir\System32\WindowsPowershell\v1.0\profile.ps1"
            If (-not(Test-Path $AllUsersAllHost))
            {
                New-Item -Path $AllUsersAllHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $AllUsersAllHost"
            }
            Else
            {
                Write-Output "File Already exists: $AllUsersAllHost"
            }

            $ISECurrentUserCurrentHost = "$env:userprofile\Documents\Microsoft.PowerShellISE_profile.ps1"
            If (-not(Test-Path $ISECurrentUserCurrentHost))
            {
                New-Item -Path $ISECurrentUserCurrentHost -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $ISECurrentUserCurrentHost"
            }
            Else
            {
                Write-Output "File Already exists: $ISECurrentUserCurrentHost"
            }

            $ISEAllUserAllHosts = "$env:userprofile\Documents\WindowsPowershell\Microsoft.PowerShellISE_profile.ps1"
            If (-not(Test-Path $ISEAllUserAllHosts))
            {
                New-Item -Path $ISEAllUserAllHosts -ItemType "File" -Value "Set-Location $Root\" -Force | Out-Null
                Write-Output "Created file: $ISEAllUserAllHosts"
            }
            Else
            {
                Write-Output "File Already exists: $ISEAllUserAllHosts"
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