<#######<Script>#######>
<#######<Header>#######>
# Name: Install-ClickOnceApplication
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Install-ClickOnceApplication
{
    <#
    .Synopsis
    This function uninstalls a clickonce application and then re-downloads and installs it for you. 
    You will need to provide the application name and download path.
    .Description
    This function uninstalls a clickonce application and then re-downloads and installs it for you. 
    You will need to provide the application name and download path.
    .Example
    Install-ClickOnceApplication
    This Function Uninstalls A Clickonce Application And Then Re-Downloads And Installs It For You. 
    You Will Need To Provide The Application Name And Download Path.
    #>

    [Cmdletbinding()]

    Param
    (
        
    )

    Begin
    {       
        ####################<Default Begin Block>####################
        # Force verbose because Write-Output doesn't look well in transcript files
        $VerbosePreference = "Continue"
        
        [String]$Logfile = $PSScriptRoot + '\PSLogs\' + (Get-Date -Format "yyyy-MM-dd") +
        "-" + $MyInvocation.MyCommand.Name + ".log"
        
        Function Write-Log
        {
            <#
            .Synopsis
            This writes objects to the logfile and to the screen with optional coloring.
            .Parameter InputObject
            This can be text or an object. The function will convert it to a string and verbose it out.
            Since the main function forces verbose output, everything passed here will be displayed on the screen and to the logfile.
            .Parameter Color
            Optional coloring of the input object.
            .Example
            Write-Log "hello" -Color "yellow"
            Will write the string "VERBOSE: YYYY-MM-DD HH: Hello" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Example
            Write-Log (cmd /c "ipconfig /all")
            Will write the string "VERBOSE: YYYY-MM-DD HH: ****ipconfig output***" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Notes
            2018-06-24: Initial script
            #>
            
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                # I usually set this to = "Green" since I use a black and green theme console
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color = "Green"
            )
            
            $ConvertToString = Out-String -InputObject $InputObject -Width 100
            
            If ($($Color.Length -gt 0))
            {
                $previousForegroundColor = $Host.PrivateData.VerboseForegroundColor
                $Host.PrivateData.VerboseForegroundColor = $Color
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                $Host.PrivateData.VerboseForegroundColor = $previousForegroundColor
            }
            Else
            {
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
            }
            
        }

        Function Start-Log
        {
            <#
            .Synopsis
            Creates the log file and starts transcribing the session.
            .Notes
            2018-06-24: Initial script
            #>
            
            # Create transcript file if it doesn't exist
            If (!(Test-Path $Logfile))
            {
                New-Item -Itemtype File -Path $Logfile -Force | Out-Null
            }
        
            # Clear it if it is over 10 MB
            [Double]$Sizemax = 10485760
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            If ($($Size.Sum -ge $SizeMax))
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            Else
            {
                Write-Verbose "Logfile was less than 10 MB"   
            }
            Start-Transcript -Path $Logfile -Append 
            Write-Log "####################<Function>####################"
            Write-Log "Function started on $env:COMPUTERNAME"

        }
        
        Function Stop-Log
        {
            <#
            .Synopsis
            Stops transcribing the session and cleans the transcript file by removing the fluff.
            .Notes
            2018-06-24: Initial script
            #>
            
            Write-Log "Function completed on $env:COMPUTERNAME"
            Write-Log "####################</Function>####################"
            Stop-Transcript
       
            # Now we will clean up the transcript file as it contains filler info that needs to be removed...
            $Transcript = Get-Content $Logfile -raw

            # Create a tempfile
            $TempFile = $PSScriptRoot + "\PSLogs\temp.txt"
            New-Item -Path $TempFile -ItemType File | Out-Null
			
            # Get all the matches for PS Headers and dump to a file
            $Transcript | 
                Select-String '(?smi)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*([\S\s]*?)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*' -AllMatches | 
                ForEach-Object {$_.Matches} | 
                ForEach-Object {$_.Value} | 
                Out-File -FilePath $TempFile -Append

            # Compare the two and put the differences in a third file
            $m1 = Get-Content -Path $Logfile
            $m2 = Get-Content -Path $TempFile
            $all = Compare-Object -ReferenceObject $m1 -DifferenceObject $m2 | Where-Object -Property Sideindicator -eq '<='
            $Array = [System.Collections.Generic.List[PSObject]]@()
            foreach ($a in $all)
            {
                [void]$Array.Add($($a.InputObject))
            }
            $Array = $Array -replace 'VERBOSE: ', ''

            Remove-Item -Path $Logfile -Force
            Remove-Item -Path $TempFile -Force
            # Finally, put the information we care about in the original file and discard the rest.
            $Array | Out-File $Logfile -Append -Encoding ASCII
            
        }
        
        Start-Log

        Function Set-Console
        {
            <# 
        .Synopsis
        Function to set console colors just for the session.
        .Description
        Function to set console colors just for the session.
        This function sets background to black and foreground to green.
        Verbose is DarkCyan which is what I use often with logging in scripts.
        I mainly did this because darkgreen does not look too good on blue (Powershell defaults).
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
        
            Function Test-IsAdmin
            {
                <#
                .Synopsis
                Determines whether or not the user is a member of the local Administrators security group.
                .Outputs
                System.Bool
                #>

                [CmdletBinding()]
    
                $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $Principal = new-object System.Security.Principal.WindowsPrincipal(${Identity})
                $IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
                Write-Output -InputObject $IsAdmin
            }

            $console = $host.UI.RawUI
            If (Test-IsAdmin)
            {
                $console.WindowTitle = "Administrator: Powershell"
            }
            Else
            {
                $console.WindowTitle = "Powershell"
            }
            $Background = "Black"
            $Foreground = "Green"
            $Messages = "DarkCyan"
            $Host.UI.RawUI.BackgroundColor = $Background
            $Host.UI.RawUI.ForegroundColor = $Foreground
            $Host.PrivateData.ErrorForegroundColor = $Messages
            $Host.PrivateData.ErrorBackgroundColor = $Background
            $Host.PrivateData.WarningForegroundColor = $Messages
            $Host.PrivateData.WarningBackgroundColor = $Background
            $Host.PrivateData.DebugForegroundColor = $Messages
            $Host.PrivateData.DebugBackgroundColor = $Background
            $Host.PrivateData.VerboseForegroundColor = $Messages
            $Host.PrivateData.VerboseBackgroundColor = $Background
            $Host.PrivateData.ProgressForegroundColor = $Messages
            $Host.PrivateData.ProgressBackgroundColor = $Background
            Clear-Host
        }
        Set-Console

        ####################</Default Begin Block>####################

        
        Function Open-Internetexplorer
        {
            Param
            (
                [Parameter(Mandatory = $True)]
                [String]$Url,
                [Switch] $Inforeground,
                [Switch] $Fullscreen
            )
            If ($Inforeground)
            {
                Add-Nativehelpertype
            }

            $Internetexplorer = New-Object -Com "Internetexplorer.Application"
            $Internetexplorer.Navigate($Url)
            $Internetexplorer.Visible = $True
            $Internetexplorer.Fullscreen = $Fullscreen
            If ($Inforeground)
            {
                [Nativehelper]::Setforeground($Internetexplorer.Hwnd)
            }
            Return $Internetexplorer
        }

        Function Add-Nativehelpertype
        {
            $Nativehelpertypedefinition = 
            @"
    Using System;
    Using System.Runtime.Interopservices;

    Public Static Class Nativehelper
    {
    [Dllimport("User32.Dll")]
    [Return: Marshalas(Unmanagedtype.Bool)]
    Private Static Extern Bool Setforegroundwindow(Intptr Hwnd);

    Public Static Bool Setforeground(Intptr Windowhandle)
    {
   Return Nativehelper.Setforegroundwindow(Windowhandle);
    }

    }
"@
            If (-Not ([System.Management.Automation.Pstypename] "Nativehelper").Type)
            {
                Add-Type -Typedefinition $Nativehelpertypedefinition
            }
        }
        
    }
    
    Process
    {   
        Write-Log "Uninstalling App"
        $Installedapplicationnotmsi = Get-Childitem "Hkcu:\Software\Microsoft\Windows\Currentversion\Uninstall" | 
            Foreach-Object {Get-Itemproperty $_.Pspath}
        $Uninstallstring = $Installedapplicationnotmsi | 
            Where-Object { $_.Displayname -Match "App" } | 
            Select-Object Uninstallstring 
        $Wshell = New-Object -Com Wscript.Shell
        $Selecteduninstallstring = $Uninstallstring.Uninstallstring
        $Wshell.Run("Cmd /C $Selecteduninstallstring")
        Start-Sleep -Seconds 5
        $Wshell.Sendkeys("Ok")
        $Wshell.Sendkeys("{Enter}")
        Write-Log "Uninstalling App... Completed"
    
        Write-Log "Renaming Localappdata-Apps-2.0 Folder..."
        Set-Location "C:\Users\$Env:Username\Appdata\Local\Apps"
        Rename-Item -Path .\2.0 -Newname 2.0.Old -Force
        If (Test-Path "C:\Users\$Env:Username\Appdata\Local\Apps\2.0.Old") 
        {
   
            Write-Log "Renaming Localappdata-Apps-2.0 Folder...Completed"
        }
        Else 
        { 

            Write-Log "Renaming Localappdata-Apps-2.0 Folder...Failed!"
        }

        Write-Log "Reinstalling Application..."
  
        Open-Internetexplorer -Url Http://Example.Com/Install.Application -Fullscreen -Inforeground

        $Wshell = New-Object -Com Wscript.Shell
        Start-Sleep -Seconds 5
        $Wshell.Sendkeys("{Left}")
        $Wshell.Sendkeys("{Enter}")	
    
    }

    End
    {
        Stop-log
        
    }
}

<#######</Body>#######>
<#######</Script>#######>