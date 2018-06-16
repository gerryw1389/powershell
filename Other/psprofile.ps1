<#######<Script>#######>
<#######<Header>#######>
# Name: PS Profile Script
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Set-Location -Path $env:SystemDrive\

# Stop the annoying bell sound
Set-PSReadlineOption -BellStyle None

# Import Modules
Try
{
    Import-Module gwActiveDirectory, gwApplications, gwConfiguration, gwFilesystem, gwMisc, gwNetworking, gwSecurity -Prefix gw -ErrorAction Stop
}
Catch
{
    Write-ToString "Module gw* was not found, moving on."
}

Try
{
    Import-Module PSColor -ErrorAction Stop
    $global:PSColor.File.Executable.Color = 'DarkGreen'
}
Catch
{
    Write-ToString "Module gw* was not found, moving on."
}

# Helper
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
    Write-ToString -InputObject $IsAdmin;
}

Function Set-Console
{
    <# 
        .Synopsis
        Function to set console colors just for the session.
        .Description
        Function to set console colors just for the session.
        I mainly did this because darkgreen does not look too good on blue (Powershell defaults).
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
        
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

    If (-not ("Windows.Native.Kernel32" -as [type]))
    {
        Add-Type -TypeDefinition @"
    namespace Windows.Native
    {
      using System;
      using System.ComponentModel;
      using System.IO;
      using System.Runtime.InteropServices;

      public class Kernel32
      {
        // Constants
        ////////////////////////////////////////////////////////////////////////////
        public const uint FILE_SHARE_READ = 1;
        public const uint FILE_SHARE_WRITE = 2;
        public const uint GENERIC_READ = 0x80000000;
        public const uint GENERIC_WRITE = 0x40000000;
        public static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);
        public const int STD_ERROR_HANDLE = -12;
        public const int STD_INPUT_HANDLE = -10;
        public const int STD_OUTPUT_HANDLE = -11;

        // Structs
        ////////////////////////////////////////////////////////////////////////////
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public class CONSOLE_FONT_INFOEX
        {
          private int cbSize;
          public CONSOLE_FONT_INFOEX()
          {
            this.cbSize = Marshal.SizeOf(typeof(CONSOLE_FONT_INFOEX));
          }

          public int FontIndex;
          public short FontWidth;
          public short FontHeight;
          public int FontFamily;
          public int FontWeight;
          [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
          public string FaceName;
        }

        public class Handles
        {
          public static readonly IntPtr StdIn = GetStdHandle(STD_INPUT_HANDLE);
          public static readonly IntPtr StdOut = GetStdHandle(STD_OUTPUT_HANDLE);
          public static readonly IntPtr StdErr = GetStdHandle(STD_ERROR_HANDLE);
        }

        // P/Invoke function imports
        ////////////////////////////////////////////////////////////////////////////
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool CloseHandle(IntPtr hHandle);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern IntPtr CreateFile
          (
          [MarshalAs(UnmanagedType.LPTStr)] string filename,
          uint access,
          uint share,
          IntPtr securityAttributes, // optional SECURITY_ATTRIBUTES struct or IntPtr.Zero
          [MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,
          uint flagsAndAttributes,
          IntPtr templateFile
          );

        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern bool GetCurrentConsoleFontEx
          (
          IntPtr hConsoleOutput, 
          bool bMaximumWindow, 
          // the [In, Out] decorator is VERY important!
          [In, Out] CONSOLE_FONT_INFOEX lpConsoleCurrentFont
          );

        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern IntPtr GetStdHandle(int nStdHandle);

        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool SetCurrentConsoleFontEx
          (
          IntPtr ConsoleOutput, 
          bool MaximumWindow,
          // Again, the [In, Out] decorator is VERY important!
          [In, Out] CONSOLE_FONT_INFOEX ConsoleCurrentFontEx
          );


        // Wrapper functions
        ////////////////////////////////////////////////////////////////////////////
        public static IntPtr CreateFile(string fileName, uint fileAccess, 
          uint fileShare, FileMode creationDisposition)
        {
          IntPtr hFile = CreateFile(fileName, fileAccess, fileShare, IntPtr.Zero, 
            creationDisposition, 0U, IntPtr.Zero);
          if (hFile == INVALID_HANDLE_VALUE)
          {
            throw new Win32Exception();
          }

          return hFile;
        }

        public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx()
        {
          IntPtr hFile = IntPtr.Zero;
          try
          {
            hFile = CreateFile("CONOUT$", GENERIC_READ,
            FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);
            return GetCurrentConsoleFontEx(hFile);
          }
          finally
          {
            CloseHandle(hFile);
          }
        }

        public static void SetCurrentConsoleFontEx(CONSOLE_FONT_INFOEX cfi)
        {
          IntPtr hFile = IntPtr.Zero;
          try
          {
            hFile = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE,
              FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);
            SetCurrentConsoleFontEx(hFile, false, cfi);
          }
          finally
          {
            CloseHandle(hFile);
          }
        }

        public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx
          (
          IntPtr outputHandle
          )
        {
          CONSOLE_FONT_INFOEX cfi = new CONSOLE_FONT_INFOEX();
          if (!GetCurrentConsoleFontEx(outputHandle, false, cfi))
          {
            throw new Win32Exception();
          }

          return cfi;
        }
      }
    }
"@
    }

    Function Set-ConsoleFont
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("Consolas", "Lucida Console")]
            [string] $Name,
            [Parameter(Mandatory = $true, Position = 1)]
            [ValidateRange(5, 72)]
            [int] $Height
        )

        $cfi = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx()
        $cfi.FontIndex = 0
        $cfi.FontFamily = 0
        $cfi.FaceName = $Name
        $cfi.FontWidth = [int]($Height / 2)
        $cfi.FontHeight = $Height
        [Windows.Native.Kernel32]::SetCurrentConsoleFontEx($cfi)
    }

    Set-ConsoleFont -Name Consolas -Height 20

}
Set-Console

Function Prompt
{
    <# 
.Synopsis
Sets the prompt to one of three choices. See comments.
.Description
Sets the prompt to one of three choices. See comments.
.Notes
2018-01-02: Added Linux comment
2017-10-26: v1.0 Initial script
#>

    $CurPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    If ($CurPath.ToLower().StartsWith($Home.ToLower()))
    {
        $CurPath = "~" + $CurPath.SubString($Home.Length)
    }

    # Option 1: Full brackets
    # $Date = (Get-Date -Format "yyyy-MM-dd@hh:mm:sstt")
    # Write-Host "[$(($env:USERNAME.ToLower()))@$(($env:COMPUTERNAME.ToLower()))][$Date][$CurPath]" 
    # "$('>' * ($nestedPromptLevel + 1)) "
    # Return " "
    
    # Option 2: For a more Linux feel
    # Write-Host "$(($env:USERNAME.ToLower()))" -ForegroundColor Cyan -NoNewLine
    # Write-Host "@" -ForegroundColor Gray -NoNewLine
    # Write-Host "$(($env:COMPUTERNAME.ToLower()))" -ForegroundColor Red -NoNewLine
    # Write-Host ":$curPath#" -ForegroundColor Gray -NoNewLine
    # Return " "
	
    # Option 3: For a minimalistic feel
    Write-Host "[$curPath]"
    "$('>' * ($nestedPromptLevel + 1)) "
    Return " "
	
}

Clear-Host

<#######</Body>#######>
<#######</Script>#######>