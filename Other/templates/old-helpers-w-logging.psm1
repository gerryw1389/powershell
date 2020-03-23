<#######<Module>#######>
<#######<Header>#######>
# Name: Helpers
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
# This file contains helper functions to be used by public functions      
<#######<Body>#######>

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
    $Messages = "Cyan"
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

# Logging

Function Start-Log
{
    <#
        .Synopsis
        Function to write the opening part of the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        .Description
        Function to write the opening part of the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        It creates the directory if it doesn't exists and then the log file automatically.
        It checks the size of the file if it already exists and clears it if it is over 10 MB.
        If it exists, it creates a header. This function is best placed in the "Begin" block of a script.
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
    [Cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $True)]
        [String]$Logfile
    )

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
    
    $Sizemax = 10
    $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
    $Sizemb = "{0:N2}" -F ($Size.Sum / 1mb) + "Mb"
    If ($Sizemb -Ge $Sizemax)
    {
        Get-Childitem $Logfile | Clear-Content
        Write-Verbose "Logfile has been cleared due to size"
    }

    "####################<Script>####################" | Out-File -Encoding ASCII -FilePath $Logfile -Append
    ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "Script Started on $env:COMPUTERNAME ") | Out-File -Encoding ASCII -FilePath $Logfile -Append
           
}

Function Write-Log
{
    <# 
        .Synopsis
        Function to write to a log file at $PSScriptRoot\..\Logs\scriptname.log. Colors can be displayed for console view as well.
        .Description
        Function to write to the console with colors specified with the "Color" parameter and a logfile at $PSScriptRoot\..\Logs\scriptname.log.
        .Parameter Message
        The string to be displayed to the screen and in the logfile. 
        .Parameter Color
        The color in which to display the input string on the screen
        Default is DarkGreen
        Valid options are: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, 
        Red, White, and Yellow.
        .Example 
        Write-Log "Hello Hello"
        This will write "Hello Hello" to the console in DarkGreen text and to the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        .Example 
        Write-Log -Message "Hello Hello Again" -Color Magenta
        .Example 
        Same as above but with Magenta color instead of dark green.
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
        
    [Cmdletbinding(Supportsshouldprocess = $True, Confirmimpact = 'Low')]       
    Param
    (
        [Parameter(Mandatory = $True, Valuefrompipeline = $True, Valuefrompipelinebypropertyname = $True, Position = 0)]
        [String]$Message, 
                
        [Parameter(Mandatory = $False, Position = 1)]
        [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
        [String]$Color = "Darkgreen",

        [Parameter(Mandatory = $True)]
        [String]$Logfile          
    )
    
    Write-Host $Message -Foregroundcolor $Color 
    ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "$Message") | Out-File -Encoding ASCII -FilePath $Logfile -Append
}
New-Alias -Name "Log" -Value Write-Log

Function Write-ErrorLog 
{
    <# 
        .Synopsis
        Function to write an error to the log file.
        .Description
        Function to write an error to the log file. This function is usually used in the catch block.
        .Parameter Message
        What to write after the word "ERROR:" in the logfile.
        .Parameter ExitGracefully
        Allows the logfile to wrap up before exiting.
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
        
    Param (

        [Parameter(Mandatory = $True, Valuefrompipeline = $True, Valuefrompipelinebypropertyname = $True, Position = 0)]
        [String]$Message,

        [Parameter(Mandatory = $false, Position = 1)]
        [switch]$ExitGracefully,

        [Parameter(Mandatory = $True)]
        [String]$Logfile

    )

    If ( $ExitGracefully)
    {
        Write-Error "$Message" 
        ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "ERROR: " + "$Message") | Out-File -Encoding ASCII -FilePath $Logfile -Append
        ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "ERROR: " + "Exiting early / breaking out!") | Out-File -Encoding ASCII -FilePath $Logfile -Append
        Stop-Log
        Break
    }
    Else
    {
        Write-Error "$Message" 
        ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "ERROR: " + "$Message") | Out-File -Encoding ASCII -FilePath $Logfile -Append
    }
}

Function Stop-Log
{
    <# 
        .Synopsis
        Function to write the closing part of the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        .Description
        Function to write the closing part of the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        This function is best placed in the "End" block of a script.
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [String]$Logfile
    )
    ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "Script Completed on $env:COMPUTERNAME") | Out-File -Encoding ASCII -FilePath $Logfile -Append
    "####################</Script>####################" | Out-File -Encoding ASCII -FilePath $Logfile -Append
}

# Admin

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
    Write-Output -InputObject $IsAdmin;
}

Function Set-RegEntry
{
    <#
        .Synopsis
        Writes a registry entry.
        .Description
        Writes a registry entry by checking if it exists first.
        .Parameter Path
        This is the path to the container for a key.
        .Parameter Name
        This is the name of the key.
        .Parameter Value
        This is the value of the key.
        .Parameter Type
        This is the type of key the function is to write. Default is "Dword", but also accepts "String", "Multistring", and "ExpandString".
        Have only tested with Dword and String
        .Parameter Binary
        You will need to export the key you are about to change first (from a machine that has it how you want it) and then copy and paste the results into the read-host part.
        For example, if I want OneDrive to not run on startup I would export the keys from [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run]
        on a machine that I already have OneDrive disabled on startup and then copy the key "03,00,00,00,cd,9a,36,38,64,0b,d2,01" into the read-host prompt.
    #>
    
    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Path,
    
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Name,
    
        [Parameter(Position = 2, Mandatory = $true)]
        [String]$Value,

        [Parameter(Position = 3, Mandatory = $false)]
        [String]$Type = "Dword",

        [Parameter(Position = 4, Mandatory = $false)]
        [Switch]$Binary
        
    )
    
    If ($Binary)
    {
        If (!(Test-Path $Path))
        {
            New-Item -Path $Path -Force | Out-Null
        }
        $Test = (((Get-Item -Path $Path).GetValue($Name) -eq $Value)) 
        If ($Test)
        {
            # If the registry already has this value... Do nothing!
            Write-Log "Key already exists: $name at $Path" -Color Gray -Logfile $Logfile
        }
        Else
        {
            If (!($($Bin.length -gt 0)))
            {
                $Bin = Read-Host "Paste the =hex: here"
            }
            # Example: $Bin = "03,00,00,00,cd,9a,36,38,64,0b,d2,01"
            $Hex = $Bin.Split(',') | ForEach-Object -Process { "0x$_" }
            New-ItemProperty -Path $Path -Name $Name -PropertyType Binary -Value ([byte[]]$Hex) -Force | Out-Null
            Write-Log "Added Key: $Name at $Path" -Color Gray -Logfile $Logfile
        }
    
    }

    If (!(Test-Path $Path))
    {
        New-Item -Path $Path -Force | Out-Null
    }
    $Test = (((Get-Item -Path $Path).GetValue($Name) -eq $Value)) 
    If ($Test)
    {
        Write-Log "Key already exists: $Name at $Path" -Color Gray -Logfile $Logfile
    }
    Else
    {
        New-Itemproperty -Path $Path -Name $Name -Value $Value -Propertytype $Type -Force | Out-Null
        Write-Log "Added Key: $Name at $Path" -Color Gray -Logfile $Logfile
    }
}
New-Alias -Name "SetReg" -Value Set-Regentry

Export-ModuleMember -Function * -Alias *

<#######</Body>#######>
<#######</Module>#######>