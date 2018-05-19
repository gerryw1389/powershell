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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
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
                Write-Output "Checking For The Required Paths Before Attempting Changes." | TimeStamp
                Continue
            }
    
            # Takes Ownership Of The File, Then Changes The Ntfs Permissions To Allow Us To Rename It. 
            Set-Ownership $Notepad
            Set-Permissions $Notepad
    
            Write-Output "Replacing Notepad File: $Notepad `R`N" | TimeStamp
            Rename-Item -Path $Notepad -Newname "Notepad.Exe.Bak" -Erroraction Silentlycontinue
    
            # Copies The Notepad++ File And The Dependant Dll File To The Current Path. 
            Copy-Item -Path $Notepadplus -Destination $Notepad
            Copy-Item -Path $Notepadplusdll -Destination $(Split-Path $Notepad -Parent)
        }
        # Run Notepad++ Once To Avoid Xml Error.
        & $Notepadplus
        Write-Output "Notepad Successfully Replaced With Notepad++" | TimeStamp
    
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

# Switch-NotepadInstall

<#######</Body>#######>
<#######</Script>#######>