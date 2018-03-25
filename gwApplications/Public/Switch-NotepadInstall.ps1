<#######<Script>#######>
<#######<Header>#######>
# Name: Switch-NotepadInstall
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Switch-NotepadInstall
{

    <#
.Synopsis
Installs Notepad++ And Replaces Default Notepad.Exe With Notepad++ Executable In System Folders.
.Description
Installs Notepad++ And Replaces Default Notepad.Exe With Notepad++ Executable In System Folders.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Switch-NotepadInstall
Installs Notepad++ And Replaces Default Notepad.Exe With Notepad++ Executable In System Folders.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>

    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Switch-NotepadInstall.Log"
    )

    Begin
    {
        # Function To Take Ownership Of The Notepad Files.
        Function Set-Ownership($File)
        {
            # The Takeown.Exe File Should Already Exist In Win7 - Win10 
            Try
            {
                & Takeown /F $File 
            }
            Catch
            {
                Write-Output "Failed To Take Ownership Of $File" 
            }
        }

        # This Function Gives Us Permission To Change The Notepad.Exe Files.
        Function Set-Permissions($File)
        {
            $Acl = Get-Acl $File
            $Accessrule = New-Object System.Security.Accesscontrol.Filesystemaccessrule("Everyone", "Fullcontrol", "Allow")
            $Acl.Setaccessrule($Accessrule)
            $Acl | Set-Acl $File
        }
        
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    }
    
    Process
    {   
        # Installs The Latest Version Of Notepad++ From Chocolatey Repo. 
        # Comment Out If You Already Have Notepad++ Installed.
        Install-Package -Name Notepadplusplus -Force

        # Paths To Various Required Files
        $Notepads = "$($Env:Systemroot)\Notepad.Exe", "$($Env:Systemroot)\System32\Notepad.Exe", "$($Env:Systemroot)\Syswow64\Notepad.Exe"
        $Notepadplus = Resolve-Path "$($Env:Systemdrive)\Program Files*\Notepad++\Notepad++.Exe"
        $Notepadplusdll = Resolve-Path "$($Env:Systemdrive)\Program Files*\Notepad++\Scilexer.Dll"

        # Loops Through Each Notepad Path.
        Foreach ($Notepad In $Notepads)
        {
            # Checks For The Required Paths Before Attempting Changes.
            If (!$(Test-Path $Notepad) -Or !$(Test-Path $Notepadplus))
            {
                Log "Checking For The Required Paths Before Attempting Changes." 
                Continue
            }
        
            # Takes Ownership Of The File, Then Changes The Ntfs Permissions To Allow Us To Rename It. 
            Set-Ownership $Notepad
            Set-Permissions $Notepad
        
            Log "Replacing Notepad File: $Notepad `R`N" -Color Cyan 
            Rename-Item -Path $Notepad -Newname "Notepad.Exe.Bak" -Erroraction Silentlycontinue
        
            # Copies The Notepad++ File And The Dependant Dll File To The Current Path. 
            Copy-Item -Path $Notepadplus -Destination $Notepad
            Copy-Item -Path $Notepadplusdll -Destination $(Split-Path $Notepad -Parent)
        }
        # Run Notepad++ Once To Avoid Xml Error.
        & $Notepadplus
        Log "Notepad Successfully Replaced With Notepad++" 
            
    }

    End
    {
        Stop-Log  
    }

}

# Switch-NotepadInstall

<#######</Body>#######>
<#######</Script>#######>