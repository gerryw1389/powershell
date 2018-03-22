<#######<Script>#######>
<#######<Header>#######>
# Name: Install-gwModules
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Install-Modules
{
    <#
.Synopsis
This function will copy all folders in this script's folder to a users $PSModulePath so that they will import automatically.
#>

    Begin
    {       

        Function Stop-Script 
        {
            Write-Output "Press Any Key To Continue ..."
            $X = $Host.Ui.Rawui.Readkey("Noecho,Includekeydown")
        }
		
        $VerbosePreference = "Continue"
        $Files = "$psscriptroot\*"
    }
    
    Process
    {   
        $UserModules = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "WindowsPowerShell\Modules"
        Get-Childitem -Path $Files -Recurse | Unblock-File
        Copy-Item -Path $Files -Destination $UserModules -Recurse -Verbose
        Stop-Script
        $Text = "Modules have been added to your PSModulePath.`n`nPlease add the following to your profile:`n`nImport-Module -Name gwActiveDirectory, gwApplications, gwConfiguration, gwFilesystem, gwMisc, gwNetworking, gwSecurity -Prefix gw"
        [void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
        [Microsoft.VisualBasic.Interaction]::MsgBox($Text, "OKOnly,SystemModal,Information", "Message")
        
        $Text = "This line has been copied to your clipboard. Just save your profile after it opens."
        [void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
        [Microsoft.VisualBasic.Interaction]::MsgBox($Text, "OKOnly,SystemModal,Information", "Message")
        
        $Clip = "Import-Module -Name gwActiveDirectory, gwApplications, gwConfiguration, gwFilesystem, gwMisc, gwNetworking, gwSecurity -Prefix gw" | Clip.exe
        Start-Process "$env:windir\system32\notepad.exe" -ArgumentList $Profile
        
        Stop-Script
        Start-Process "powershell.exe"
        
    }
    
    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>