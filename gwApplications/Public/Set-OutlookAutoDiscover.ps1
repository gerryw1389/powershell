<#######<Script>#######>
<#######<Header>#######>
# Name: Set-OutlookAutodiscover
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-OutlookAutodiscover
{
    <#
    .Synopsis
    Configures autodiscover keys for MS Outlook so adding accounts takes 5 seconds instead of 5 minutes.
    .Description
    Configures autodiscover keys for MS Outlook so adding accounts takes 5 seconds instead of 5 minutes.
    .Parameter Logfile
    Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
    .Example
    Set-OutlookAutodiscover
    #>
    
    [Cmdletbinding()]
    
    Param
    (
    )

    Begin
    {
        # Load the required module(s) 
        Try
        {
            Import-Module "$Psscriptroot\..\Private\helpers.psm1" -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'Helpers' was not found, stopping script"
            Exit 1
        }
        
        Function Set-2013Old
        {
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\AutoDiscover"
            $Name = "ExcludeHttpsRootDomain"
            $value = "1"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            $registryPath = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\AutoDiscover"
            $Name = "ExcludeHttpsAutoDiscoverDomain"
            $value = "1"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            # Allow adding up to 14 accounts, can adjust to 99 I believe
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Exchange"
            $Name = "MaxNumExchange"
            $value = "19"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            $registryPath = "HKCU:\Software\Policies\Microsoft\Exchange"
            $Name = "MaxNumExchange"
            $value = "19"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
        }

        Function Set-2016Old
        {
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover"
            $Name = "ExcludeHttpsRootDomain"
            $value = "1"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null


            $registryPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover"
            $Name = "ExcludeHttpsAutoDiscoverDomain"
            $value = "1"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            # Allow adding up to 14 accounts, can adjust to 99 I believe
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Exchange"
            $Name = "MaxNumExchange"
            $value = "19"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            $registryPath = "HKCU:\Software\Policies\Microsoft\Exchange"
            $Name = "MaxNumExchange"
            $value = "19"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
        }

        Function Set-2013
        {
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\AutoDiscover" -Name "ExcludeHttpsRootDomain" -Value "1"
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\AutoDiscover" -Name "ExcludeHttpsAutoDiscoverDomain" -Value "1"
            # Allow adding up to 14 accounts, can adjust to 99 I believe
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Exchange" -Name "MaxNumExchange" -Value "14"
            SetReg -Path "HKCU:\Software\Policies\Microsoft\Exchange" -Name "MaxNumExchange" -Value "14"
        }

        Function Set-2016
        {
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover" -Name "ExcludeHttpsRootDomain" -Value "1"
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover" -Name "ExcludeHttpsAutoDiscoverDomain" -Value "1"
            # Allow adding up to 14 accounts, can adjust to 99 I believe
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Exchange" -Name "MaxNumExchange" -Value "14"
            SetReg -Path "HKCU:\Software\Policies\Microsoft\Exchange" -Name "MaxNumExchange" -Value "14"
        }

    }
    
    Process
    {
        Write-Output "Getting the version of Operating System"
        $WMI = Get-WmiObject -Class win32_operatingsystem | Select-Object -Property Version
        $String = $WMI.Version.tostring()
        $OS = $String.Substring(0, 4)

        Write-Output "Getting the version of Office"
        $Version = 0
        $Reg = [Microsoft.Win32.Registrykey]::Openremotebasekey('Localmachine', $Env:Computername)
        $Reg.Opensubkey('Software\Microsoft\Office').Getsubkeynames() |Foreach-Object {
            If ($_ -Match '(\d+)\.') 
            {
                If ([Int]$Matches[1] -Gt $Version) 
                {
                    $Version = $Matches[1] 
                }
            }   
        }
        
        If ($OS -match "10.0" -and $Version -match "15")
        {
            Write-Output "Creating settings for Windows 10 and Office 2013"
            Set-2013
        }

        ElseIf ($OS -match "10.0" -and $Version -match "16")
        {
            Write-Output "Creating settings for Windows 10 and Office 2016"
            Set-2016
        }

        ElseIf ($OS -match "6.3." -and $Version -match "15")
        {
            Write-Output "Creating settings for Windows 8.1 and Office 2013"
            Set-2013Old
        }

        ElseIf ($OS -match "6.3." -and $Version -match "16")
        {
            Write-Output "Creating settings for Windows 8.1 and Office 2016"
            Set-2016Old
        }

        ElseIf ($OS -match "6.1." -and $Version -match "15")
        {
            Write-Output "Creating settings for Windows 7 and Office 2013"
            Set-2013Old
        }
    
        ElseIf ($OS -match "6.1." -and $Version -match "16")
        {
            Write-Output "Creating settings for Windows 7 and Office 2016"
            Set-2016Old
        }

        Else
        {
            Write-Output "Either the OS is unsupported or Office is not installed/ unsupported."
        }
    
        Write-Output "Sending OWA Link to Desktop"
        # Send OWA Link to desktop
        $TargetFile = "https://your.owa.com"
        $ShortcutFile = "$env:userprofile\Desktop\OWA.url"
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
        $Shortcut.TargetPath = $TargetFile
        $Shortcut.Save()

        # Clear Credential Manager manually (pick and choose)
        rundll32.exe keymgr.dll, KRShowKeyMgr

        <# 
        To Clear Completely (untested but should work):
        $creds = cmd /c "cmdkey /list"
        foreach ($c in $creds)
        {
            if ($c -like "*Target:*")
            {
                cmdkey /del:($c -replace " ", "" -replace "Target:", "")
            }
        }
        #> 
    }

    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>