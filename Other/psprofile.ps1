<#######<Script>#######>
<#######<Header>#######>
# Name: PS Profile Script
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

# Import Modules

# Import-Module -Name gwActiveDirectory, gwApplications, gwConfiguration, gwFilesystem, gwMisc, gwNetworking, gwSecurity -Prefix gw

Set-Location -Path "c:\_gwill\temp"

Import-Module PSColor
$global:PSColor.File.Executable.Color = 'DarkGreen'

Set-PSReadlineOption -BellStyle None

# Preferences

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

    $Date = (Get-Date -Format "yyyy-MM-dd@hh:mm:sstt")
    
    # Option 1: Full brackets
	# Write-Host "[$(($env:USERNAME.ToLower()))@$(($env:COMPUTERNAME.ToLower()))][$Date][$CurPath]" 
    # "$('>' * ($nestedPromptLevel + 1)) "
	# Return " "
    
	# Option 2: For a more Linux feel...
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