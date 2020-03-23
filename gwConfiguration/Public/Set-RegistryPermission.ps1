<#######<Script>#######>
<#######<Header>#######>
# Name: Set-RegkeyPermissions
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-RegkeyPermissions
{
    <#
.Synopsis
This function will takeownership of a registry key as a specified user and set access rights to full control. 
Subkeys do not inherit these settings by default. See line 327. 
.Description
This function will takeownership of a registry key as a specified user and set them to full control. 
Subkeys do not inherit these settings by default. See line 327. 
.Parameter RegistryKey
The path of the key you want to take over.
It is mandatory that you use either:
HKLM - Local Machine; ex: "HKLM:\my\software"
HKCU - Current User; ex: "HKCU:\my\software"
HKU - Users; ex: "HKU:\my\software"
HKCR - Classes root; ex: "HKCR:\my\software"
.Parameter Username
This is the user you want to be the owner. Most common is "Administrators".
.Example
Set-RegkeyPermissions -RegistryKey "HKCR:\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\ShellFolder" -Username "gerry"
Gives the user "gerry" ownership and full control of the regkey only (not children).
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [String[]]$RegistryKey,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$Username
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
        
        Function Enable-Privilege
        {
            param(
                ## The privilege to adjust. This set is taken from
                ## http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
                [ValidateSet(
                    "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
                    "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
                    "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
                    "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege",
                    "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege",
                    "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege",
                    "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege",
                    "SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege",
                    "SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege",
                    "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
                    "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
                $Privilege,
                ## The process on which to adjust the privilege. Defaults to the current process.
                $ProcessId = $pid,
                ## Switch to disable the privilege, rather than enable it.
                [Switch] $Disable
            )
   
            ## Taken from P/Invoke.NET with minor adjustments.
            $definition = @'
    using System;
    using System.Runtime.InteropServices;
     
    public class AdjPriv
    {
     [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
     internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
      ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
     
     [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
     internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
     [DllImport("advapi32.dll", SetLastError = true)]
     internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
     [StructLayout(LayoutKind.Sequential, Pack = 1)]
     internal struct TokPriv1Luid
     {
      public int Count;
      public long Luid;
      public int Attr;
     }
     
     internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
     internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
     internal const int TOKEN_QUERY = 0x00000008;
     internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
     public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
     {
      bool retVal;
      TokPriv1Luid tp;
      IntPtr hproc = new IntPtr(processHandle);
      IntPtr htok = IntPtr.Zero;
      retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
      tp.Count = 1;
      tp.Luid = 0;
      if(disable)
      {
       tp.Attr = SE_PRIVILEGE_DISABLED;
      }
      else
      {
       tp.Attr = SE_PRIVILEGE_ENABLED;
      }
      retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
      retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
      return retVal;
     }
    }
'@
   
            $processHandle = (Get-Process -id $ProcessId).Handle
            $type = Add-Type $definition -PassThru
            $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)
        }

        New-PSDrive -name HKCR -PSProvider Registry -root HKEY_CLASSES_ROOT | Out-Null
        New-PSDrive -name HKU -PSProvider Registry -root HKEY_Users | Out-Null

        If (-not(Test-Path $RegistryKey))
        {
            Write-Error "Regkey does not exist, retry function! Exiting..."
            Exit
        }
    }
    
    Process
    {   
        Try
        {
            
            
            Enable-Privilege SeTakeOwnershipPrivilege 
        
            $PathList = $RegistryKey -split '\\'
            $Root = $PathList[0]

            $RestOfPath = [system.collections.arraylist]@()
            foreach ($p in $PathList)
            {
                [void]$RestOfPath.add($p)
            }
            $RestOfPath.RemoveAt(0)
            $RestOfPath = $RestOfPath -Join '\'
                
            If ($Root -eq "HKCU:")
            {
                $Key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($RestOfPath, 
                    [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, 
                    [System.Security.AccessControl.RegistryRights]::takeownership)
            }
            If ($Root -eq "HKLM:")
            {
                $Key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($RestOfPath, 
                    [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, 
                    [System.Security.AccessControl.RegistryRights]::takeownership)
            }
            If ($Root -eq "HKCR:")
            {
                $Key = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($RestOfPath, 
                    [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, 
                    [System.Security.AccessControl.RegistryRights]::takeownership)
            }
            If ($Root -eq "HKU:")
            {
                $Key = [Microsoft.Win32.Registry]::Users.OpenSubKey($RestOfPath, 
                    [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, 
                    [System.Security.AccessControl.RegistryRights]::takeownership)
            }
        
            Write-Log "Setting registry permission for $Root\$RestOfPath"
            # You must get a blank ACL for the Key b/c you do not currently have access
            $ACL = $Key.GetAccessControl([System.Security.AccessControl.AccessControlSections]::None)
            $User = [System.Security.Principal.NTAccount]$Username
            $ACL.SetOwner($User)
            $Key.SetAccessControl($ACL)
   
            # After you have set owner you need to get the ACL with the perms so you can modify it.
            $ACL = $Key.GetAccessControl()
            # Comment out the following line and uncomment the next one to enable children to inherit.
            # I wouldn't do this unless it's needed! 
            $Rule = New-Object System.Security.AccessControl.RegistryAccessRule ($Username, "FullControl", "Allow")
            #$Rule = New-Object System.Security.AccessControl.RegistryAccessRule ($Username, "ContainerInherit, ObjectInherit", "InheritOnly", "Allow")
            $ACL.SetAccessRule($Rule)
            $Key.SetAccessControl($ACL)
   
            $Key.Close()
            Write-Log "Successfully set registry permission for $Root\$RestOfPath"
    
        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }

    End
    {
        Stop-log
    }
}

<#######</Body>#######>
<#######</Script>#######>