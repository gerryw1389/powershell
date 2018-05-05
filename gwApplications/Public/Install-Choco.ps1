<#######<Script>#######>
<#######<Header>#######>
# Name: Install-Choco
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Install-Choco
{

    <#
.Synopsis
Installs Chocolatey packages. To be used after "iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex"
.DESCRIPTION
Installs Chocolatey packages. To be used after "iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex"
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.EXAMPLE
Install-Choco
Installs Chocolatey
.EXAMPLE
"PC1", "PC2" | Install-Choco
Installs Chocolatey
.NOTES
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>    
    [CmdletBinding()]

    PARAM
    (
        [string]$LogFile = "$PSScriptRoot\..\Logs\Install-Choco.log"
    )

    Begin
    {
        Import-Module PackageManagement
    
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

    }
    
    Process
    {   
        # Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
        Install-PackageProvider NuGet -MinimumVersion '2.8.5.201' -Force
        Install-PackageProvider Chocolatey
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Write-Output "Setting up repos" | TimeStamp | TimeStamp

        # Install Packages
        Write-Output "Installing packages..." | TimeStamp | TimeStamp
        # choco install googlechrome --confirm --limitoutput
        # choco install flashplayeractivex --confirm --limitoutput
        # choco install flashplayerplugin --confirm --limitoutput
        # choco install 7zip.install --confirm --limitoutput
        # choco install adobeair --confirm --limitoutput
        # choco install jre8 --confirm --limitoutput
        # choco install dotnet3.5 --confirm --limitoutput
        # choco install python2 -y --confirm --limitoutput
        # choco install bleachbit -y --confirm --limitoutput
        # choco install notepadplusplus.install -y --confirm --limitoutput
        # choco install atom -y --confirm --limitoutput
        # choco install firefox -y --confirm --limitoutput
        # choco install vim -y --confirm --limitoutput
        # Set-Alias vim -Value "C:\Program Files (x86)\vim\vim80\gvim.exe"
        # choco install procexp -y --confirm --limitoutput
        # choco install putty -y --confirm --limitoutput
        # choco install virtualbox -y --confirm --limitoutput
        # choco install winscp.install -y --confirm --limitoutput
        # choco install sysinternals -y --confirm --limitoutput
        Clear-Host
        Write-Output "Installing packages...completed" | TimeStamp
        
        Write-Output "Creating Daily Task To Automatically Upgrade Chocolatey Packages" | TimeStamp
        $Taskname = "ChocolateyDailyUpgrade"
        $Taskaction = New-Scheduledtaskaction -Execute C:\Programdata\Chocolatey\Choco.Exe -Argument "Upgrade All -Y"
        $Tasktrigger = New-Scheduledtasktrigger -At 2am -Daily
        # Note about TaskUser, I noticed that you have to put the account name. 
        # If domain account, don't include the domain. int.domain.com\bob.domain would just be bob.domain
        $Taskuser = "ReplaceMe"
        Register-Scheduledtask -Taskname $Taskname -Action $Taskaction -Trigger $Tasktrigger -User $Taskuser
    
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

# Install-Choco

<#######</Body>#######>
<#######</Script>#######>