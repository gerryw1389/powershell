<#######<Script>#######>
<#######<Header>#######>
# Name: Set-PSProfile
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-PSProfile
{
    <#
.Synopsis
This function creates my PS profile.
.Description
This function creates my PS profile.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Set-PSProfile
This function creates my PS profile.
.Example
"Pc1" | Set-PSProfile
This function creates my PS profile.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>       
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-PSProfile.Log"
    )

    Begin
    {
        
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log   
    }
    
    Process
    {    
        
        

        $Files = @("$env:USERPROFILE\Documents\WindowsPowershell\Microsoft.Powershell_profile.ps1",
            "$env:USERPROFILE\Documents\WindowsPowershell\Microsoft.PowershellISE_profile.ps1",
            "$env:USERPROFILE\Documents\WindowsPowershell\Microsoft.VSCode_profile.ps1")
        
        ForEach ($F in $Files)
        {
            # Remember to use the escape character "`" before every dollar sign and ` character. For example `$myVar and ``r``n (new line)
            $val = 
            @"
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

Set-Location C:\scripts

Import-Module psColor
`$global:PSColor.File.Executable.Color = 'DarkGreen'

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
    
    `$Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    `$Principal = new-object System.Security.Principal.WindowsPrincipal(`${Identity})
    `$IsAdmin = `$Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Output -InputObject `$IsAdmin;
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
        
    `$console = `$host.UI.RawUI
    If (Test-IsAdmin)
    {
        `$console.WindowTitle = "Administrator: Powershell"
    }
    Else
    {
        `$console.WindowTitle = "Powershell"
    }
    `$Background = "Black"
    `$Foreground = "Green"
    `$Messages = "DarkCyan"
    `$Host.UI.RawUI.BackgroundColor = `$Background
    `$Host.UI.RawUI.ForegroundColor = `$Foreground
    `$Host.PrivateData.ErrorForegroundColor = `$Messages
    `$Host.PrivateData.ErrorBackgroundColor = `$Background
    `$Host.PrivateData.WarningForegroundColor = `$Messages
    `$Host.PrivateData.WarningBackgroundColor = `$Background
    `$Host.PrivateData.DebugForegroundColor = `$Messages
    `$Host.PrivateData.DebugBackgroundColor = `$Background
    `$Host.PrivateData.VerboseForegroundColor = `$Messages
    `$Host.PrivateData.VerboseBackgroundColor = `$Background
    `$Host.PrivateData.ProgressForegroundColor = `$Messages
    `$Host.PrivateData.ProgressBackgroundColor = `$Background
    Clear-Host
}
Set-Console

Function Get-Help2
{
    <# 
.Synopsis
Launches a window in SS64.com for a selected command.
.Description
Launches a window in SS64.com for a selected command.
.Example
Get-Help Get-Process
Opens a window in your default internet browser to ss64's page on get-process.
.Notes
2017-10-19: v1.0 Initial script 
#>
    param
    (
        [string]`$command
    )
    `$command = `$command.ToLower()
    Start-process -filepath "https://ss64.com/ps/`$command.html"
}

Function Show-VerbList
{
    Get-Verb | Sort-Object -Property Verb | Out-Gridview
}

Function Prompt
{
    <# 
.Synopsis
Function to set the prompt to the date and directory on one line and just a pound sign on the second line. 
If you are running as admin, it will also put an [Admin] in front on the first line.
.Description
Function to set the prompt to the date and directory on one line and just a pound sign on the second line. 
If you are running as admin, it will also put an [Admin] in front on the first line.
.Notes
2017-10-26: v1.0 Initial script 
#>

    `$CurPath = `$ExecutionContext.SessionState.Path.CurrentLocation.Path
    If (`$CurPath.ToLower().StartsWith(`$Home.ToLower()))
    {
        `$CurPath = "~" + `$CurPath.SubString(`$Home.Length)
    }

    `$Date = (Get-Date -Format "yyyy-MM-dd@hh:mm:sstt")
    
    If (Test-IsAdmin)
    {
    Write-Host "[`$((`$env:USERNAME.ToLower()))@`$((`$env:COMPUTERNAME.ToLower()))][`$Date][`$CurPath]" -NoNewLine 
    "`n`$('>' * (`$nestedPromptLevel + 1)) "
    # For a more Linux feel...
    #Write-Host "`$((`$env:USERNAME.ToLower()))@`$((`$env:COMPUTERNAME.ToLower())):`$curPath#" -NoNewline -ForegroundColor Darkgreen
    #Return " "
    }
    Else
    {
    Write-Host "[`$((`$env:USERNAME.ToLower()))@`$((`$env:COMPUTERNAME.ToLower()))][`$Date][`$CurPath]" -NoNewLine 
    "`n`$('>' * (`$nestedPromptLevel + 1)) "
    # For a more Linux feel...
    #Write-Host "`$((`$env:USERNAME.ToLower()))@`$((`$env:COMPUTERNAME.ToLower())):`$curPath`$" -NoNewline -ForegroundColor Darkgreen
    #Return " "
    }
}

<#######</Body>#######>
<#######</Script>#######>

"@
            Set-Content -Path $F -Value $val
            Log "Profile $F has been set"
        }
    }

    End
    {
        Stop-Log  
    }

}

# Set-PSProfile

<#######</Body>#######>
<#######</Script>#######>