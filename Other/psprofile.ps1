<#######<Script>#######>
<#######<Header>#######>
# Name: PS Profile Script
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
###############################################################################################################################################
# Set Readline and colors:
###############################################################################################################################################
If ( $((get-module PSReadline).version.Major) -eq 1 )
{
    $Background = 'Black'
    Set-PSReadLineOption -TokenKind Comment -ForegroundColor 'DarkGray' -BackgroundColor $Background
    Set-PSReadLineOption -TokenKind Keyword -ForegroundColor 'DarkGray' -BackgroundColor $Background
    Set-PSReadLineOption -TokenKind String -ForegroundColor 'Green' -BackgroundColor $Background
    Set-PSReadLineOption -TokenKind Operator -ForegroundColor 'Magenta' -BackgroundColor $Background
    Set-PSReadLineOption -TokenKind Variable -ForegroundColor 'Red' -BackgroundColor $Background
    Set-PSReadLineOption -TokenKind Command -ForegroundColor 'Cyan' -BackgroundColor $Background
    Set-PSReadLineOption -TokenKind Parameter -ForegroundColor 'DarkCyan' -BackgroundColor $Background
    Set-PSReadLineOption -TokenKind Type -ForegroundColor 'White' -BackgroundColor $Background
    Set-PSReadLineOption -TokenKind Number -ForegroundColor 'Magenta' -BackgroundColor $Background
    Set-PSReadLineOption -TokenKind Member -ForegroundColor 'White' -BackgroundColor $Background
    Set-PSReadLineOption -BellStyle "None"
    Set-PSReadLineOption -EditMode "Vi"
    Set-PSReadLineOption -ViModeIndicator "Prompt"
    # Set-PSReadlineKeyHandler -Key Tab -Function Complete
}
Else
{
    $PSReadLineOptions = @{
        BellStyle                     = "None"
        EditMode                      = "Vi"
        ViModeIndicator               = "Prompt"
        HistoryNoDuplicates           = $true
        HistorySearchCursorMovesToEnd = $true
        Colors                        = @{
            Command            = 'Cyan'
            Comment            = 'DarkGray'
            ContinuationPrompt = 'Magenta'
            Default            = 'Green'
            Emphasis           = 'White'
            Error              = 'Red'
            Member             = 'White'
            Number             = 'Magenta'
            Operator           = 'Magenta'
            Parameter          = 'DarkCyan'
            String             = 'Green'
            Type               = 'White'
            Variable           = 'Red'
        }
    }
    Set-PSReadLineOption @PSReadLineOptions
    #Set-PSReadlineKeyHandler -Key Tab -Function Complete
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

# Set function for VSCode to open workspaces
# I also have '"window.newWindowDimensions": "maximized"' in my user settings so that when vscode starts, 
# I just type 'ctrl+`' and then one time type 'start-workspaces' to open all of my workspaces
Function Start-Workspaces
{
    code c:\scripts\notes.code-workspace
    code c:\scripts\powershell-work.code-workspace
    code c:\scripts\puppet.code-workspace
    code c:\scripts\scripts.code-workspace
    code c:\scripts\website.code-workspace
}

Function Bitcoin
{
	[Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
	$response = Invoke-Restmethod -URI "https://api.blockchain.info/stats" -Method Get
	return $response.market_price_usd
}

###############################################################################################################################################
# Set the prompt
###############################################################################################################################################
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
    Write-Output -InputObject $IsAdmin;
}

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
	
    # Option 2b: For a more Linux feel with a new line
    Write-Host "$(($env:USERNAME.ToLower()))" -ForegroundColor Cyan -NoNewLine
    Write-Host "@" -ForegroundColor Gray -NoNewLine
    Write-Host "$(($env:COMPUTERNAME.ToLower()))" -ForegroundColor Magenta -NoNewLine
    Write-Host ":$curPath" -ForegroundColor Gray
    If (Test-IsAdmin)
    {
        "$('#' * ($nestedPromptLevel + 1)) "
    }
    Else
    {
        "$('>' * ($nestedPromptLevel + 1)) "
    }
    Return " "
	
    # Option 3: For a minimalistic feel
    # Write-Host "[$curPath]"
    # "$('>' * ($nestedPromptLevel + 1)) "
    # Return " "
	
}

###############################################################################################################################################
# Import Modules
###############################################################################################################################################
Try
{
    Import-Module "gwActiveDirectory", "gwApplications", "gwConfiguration", "gwFilesystem", "gwMisc", "gwNetworking", "gwSecurity" -ErrorAction "Stop"
}
Catch
{
    Write-Output "Module gw* was not found, moving on."
}

###############################################################################################################################################
# Set location
###############################################################################################################################################
Set-Location -Path $env:SystemDrive\
Clear-Host

<#######</Body>#######>
<#######</Script>#######>
