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
    Clears temp files from the system. It does Windows temp, user temp, browsers, runs Diskcleanup, and emptys the recycle bin.
    .Description
    Clears temp files from the system. It does Windows temp, user temp, browsers, runs Diskcleanup, and emptys the recycle bin.
    .Example
    Clear-TempFiles
    Clears temp files from the system. It does Windows temp, user temp, browsers, runs Diskcleanup, and empties the recycle bin.
    #>

    [Cmdletbinding()]

    Param
    (
    )

    Begin
    {
        Function Get-Diskspace
        {
            Get-Wmiobject Win32_Logicaldisk | 
            Where-Object { $_.Drivetype -Eq "3" } | 
            Select-Object Systemname,
            @{ Name = "Drive" ; Expression = { ( $_.Deviceid ) } },
            @{ Name = "Size (Gb)" ; Expression = {"{0:N1}" -F ( $_.Size / 1gb)}},
            @{ Name = "Freespace (Gb)" ; Expression = {"{0:N1}" -F ( $_.Freespace / 1gb ) } },
            @{ Name = "Percentfree" ; Expression = {"{0:P1}" -F ( $_.Freespace / $_.Size ) } } |
            Format-Table -Autosize
        }

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
        Write-Output "Space before: $Before"
        Write-Output "Cleaning Windows temp files, Mozilla Firefox, Chrome, and IE temp files"

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
                Write-Output "Cleaning: $Path"
                Remove-Item $Path -Recurse -Force -Erroraction Silentlycontinue
            }
            Else
            {
                Write-Output "Does not exist: $Path"
            }
        }

        Write-Output "Running Windows Disk Clean Up Tool"
        cmd /c "cleanmgr /sagerun:1" | Out-Null 
        $([Char]7)
        Start-Sleep -Seconds 1 
        $([Char]7)
        Start-Sleep -Seconds 1	

        Write-Output "Emptying the Recycle Bin"
        $Objshell = New-Object -Comobject Shell.Application 
        $Objfolder = $Objshell.Namespace(0xa)
        $Objfolder.Items() | Foreach-Object { Remove-Item $_.Path -Recurse -Force -Erroraction Ignore }

        $SpaceAfter = [Math]::Round(((Get-Wmiobject Win32_Logicaldisk | Where-Object { $_.Drivetype -Eq "3" -And $_.Deviceid -Eq "C:" }).Freespace / 1gb), 4)
        $After = Get-Diskspace | Out-String 
        Write-Output "Space after: $After"
    
        $SpaceCleared = $SpaceAfter - $SpaceBefore
        Write-Output "Cleared $SpaceCleared GB"

        # To Create a temp file for testing:
        # $path = "c:\scripts\testfile.txt"
        # $file = [io.file]::Create($path)
        # $file.SetLength(1gb)
        # $file.Close()

    }

    End
    {
    }
}   

<#######</Body>#######>
<#######</Script>#######>