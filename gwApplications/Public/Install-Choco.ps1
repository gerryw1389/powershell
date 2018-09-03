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
    .EXAMPLE
    Install-Choco
    Installs Chocolatey
    .EXAMPLE
    Install-Choco
    Installs Chocolatey
    #>    
    [CmdletBinding()]

    PARAM
    (
        
    )

    Begin
    {
        # Load the required module(s) 
        Try
        {
            Import-Module PackageManagement -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'PackageManagement' was not found, stopping script"
            Exit 1
        }
    }
    
    Process
    {   
        # Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
        Install-PackageProvider NuGet -MinimumVersion '2.8.5.201' -Force
        Install-PackageProvider Chocolatey
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Write-Output "Setting up repos"

        # Install Packages
        Write-Output "Installing packages..."
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
        Write-Output "Installing packages...completed"
        
        Write-Output "Creating Daily Task To Automatically Upgrade Chocolatey Packages"
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
        
    }

}

<#######</Body>#######>
<#######</Script>#######>