<#######<Script>#######>
<#######<Header>#######>
# Name: Clear-TempFiles
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Clear-TempFiles
{
     <#
.Synopsis
Clears temp files from the system. It does Windows temp, user temp, browsers, runs Diskcleanup, and empties the recycle bin.
.Description
Clears temp files from the system. It does Windows temp, user temp, browsers, runs Diskcleanup, and empties the recycle bin.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Clear-TempFiles
Clears temp files from the system. It does Windows temp, user temp, browsers, runs Diskcleanup, and empties the recycle bin.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Clear-TempFiles.Log"
    )

    
    Begin
    {
        Function Get-Diskspace
        {
            Get-Wmiobject Win32_Logicaldisk | Where-Object { $_.Drivetype -Eq "3" } | Select-Object Systemname,
            @{ Name = "Drive" ; Expression = { ( $_.Deviceid ) } },
            @{ Name = "Size (Gb)" ; Expression = {"{0:N1}" -F ( $_.Size / 1gb)}},
            @{ Name = "Freespace (Gb)" ; Expression = {"{0:N1}" -F ( $_.Freespace / 1gb ) } },
            @{ Name = "Percentfree" ; Expression = {"{0:P1}" -F ( $_.Freespace / $_.Size ) } } |
                Format-Table -Autosize
        }

        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log

    }
    
    Process
    {   
        
                
        
        # Get free space before cleaning
        $SpaceBefore = [Math]::Round(((Get-Wmiobject Win32_Logicaldisk | Where-Object { $_.Drivetype -Eq "3" -And $_.Deviceid -Eq "C:" }).Freespace / 1gb), 4)
        # Essentially:
        # $B = Get-Wmiobject Win32_Logicaldisk | Where-Object { $_.Drivetype -Eq "3" -And $_.Deviceid -Eq "C:" }
        # $C = $B.Freespace / 1gb
        # $D = [Math]::Round($C, 2)

        $Before = Get-DiskSpace | Out-String                      
        Log "Space before: $Before" 
        Log "Cleaning Windows temp files, Mozilla Firefox, Chrome, and IE temp files" 

        $Paths = @(
            "C:\Inetpub\Logs\Logfiles\*",
            "C:\Windows\Temp\*",
            "$env:userprofile\Appdata\Local\Temp\*",
            "$env:userprofile\Appdata\Local\Google\Chrome\User Data\Default\Cache\*",
            "$env:userprofile\Appdata\Local\Microsoft\Windows\Temporary Internet Files\*",
            "$env:userprofile\Appdata\Local\Mozilla\Firefox\Profiles\*.Default\Cache2\Entries\*",
            "$env:userprofile\Appdata\Local\Mozilla\Firefox\Profiles\*.Default\Thumbnails\*"
        )

        ForEach ($Path in $Paths)
        {
            If (Test-Path $Path)
            {
                Log "Cleaning: $Path" 
                Remove-Item $Path -Recurse -Force -Erroraction Silentlycontinue
            }
            Else
            {
                Log "Does not exist: $Path"  
            }
        }

        Log "Running Windows Disk Clean Up Tool" 
        cmd /c "cleanmgr /sagerun:1" | Out-Null 
        $([Char]7)
        Start-Sleep -Seconds 1 
        $([Char]7)
        Start-Sleep -Seconds 1	

        Log "Emptying the Recycle Bin" 
        $Objshell = New-Object -Comobject Shell.Application 
        $Objfolder = $Objshell.Namespace(0xa)
        $Objfolder.Items() | Foreach-Object { Remove-Item $_.Path -Recurse -Force -Erroraction Ignore }

        $SpaceAfter = [Math]::Round(((Get-Wmiobject Win32_Logicaldisk | Where-Object { $_.Drivetype -Eq "3" -And $_.Deviceid -Eq "C:" }).Freespace / 1gb), 4)
        $After = Get-Diskspace | Out-String     
        Log "Space after: $After" 
        
        $SpaceCleared = $SpaceAfter - $SpaceBefore
        Log "Cleared $SpaceCleared GB" 

        # To Create a temp file for testing:
        # $path = "c:\scripts\testfile.txt"
        # $file = [io.file]::Create($path)
        # $file.SetLength(1gb)
        # $file.Close()
        # Then delete so it is sitting in Recycle Bin

    }

    End
    {
        Stop-Log  
    }
    
}   

# Clear-TempFiles

<#######</Body>#######>
<#######</Script>#######>