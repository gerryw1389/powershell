<#######<Script>#######>
<#######<Header>#######>
# Name: Set-IESettings
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-IESettings
{
    <#
.Synopsis
Resets IE and adds your site(s) to trusted site and pop up blocker.
.Description
Resets IE and adds your site(s) to trusted site and pop up blocker.
Additionally, it opens trusted zones for those crappy enterprise portals that need "full allow" settings.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
.Example
Set-OutlookAutodiscover
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>
    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String[]]$TrustedSites,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-IESettings.log"
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
        # Load the required module(s) 
        If (-not(Get-module helpers)) 
        {
            Import-Module "$Psscriptroot\..\Private\helpers.psm1"
        }
        Else
        {
            Write-Output "Module was not found, please make sure the module exists! Exiting function." | Timestamp
            Exit 1
        }
    }

    Process
    {
        Write-Output "Configuring Internet Settings" | TimeStamp

        # Reset IE to defaults, you don't have to click, just wait and it will for you.
        Write-Output "Resetting to defaults" | TimeStamp
        Add-Type -Assemblyname Microsoft.Visualbasic
        Add-Type -Assemblyname System.Windows.Forms
        rundll32.exe inetcpl.cpl ResetIEtoDefaults
        Start-Sleep -Milliseconds 500
        [Microsoft.Visualbasic.Interaction]::Appactivate("Reset Internet Explorer Settings")
        [System.Windows.Forms.Sendkeys]::Sendwait("%R")
        Start-Sleep -Seconds 2
        [System.Windows.Forms.Sendkeys]::Sendwait("%C")

        Write-Output "Setting Homepage to Google" | TimeStamp
        SetReg -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -Name "Start Page" -Value "https://google.com" -PropertyType "String"

        ForEach ($Site in $TrustedSites)
        {
            Write-Output "Adding $Site To Trusted Sites" | TimeStamp
            $Substring = $Site.Replace('http://', '').replace('https://', '').replace('www.', '')
            SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\$Substring" -Name "*" -Value "2"
            Write-Output "Adding $Site to Pop Up Blocker list..." | TimeStamp
            SetReg -Path "HKCU:\Software\Microsoft\Internet Explorer\New Windows\Allow" -Name "*.$Substring" -Value "00,00" -PropertyType "Binary"
        }

        # Basically full open the trusted sites zone.
        Write-Output "Configuring zones" | TimeStamp
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1001" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1004" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1200" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1201" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1206" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1208" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1209" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "120A" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "120B" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1400" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1402" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1405" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1607" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1609" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1803" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "1809" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "2000" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "2201" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "2702" -Value "0"
        SetReg -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\zones\2" -Name "270C" -Value "0"
    
        Write-Output "Launching IE" | TimeStamp
        Invoke-Item "C:\Program Files (x86)\Internet Explorer\iexplore.exe" 
 
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