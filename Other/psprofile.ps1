<#######<Script>#######>
<#######<Header>#######>
# Name: PS Profile Script
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
###############################################################################################################################################
# Misc:
###############################################################################################################################################
# Setup Colors and remove annoying bell sound:
Set-PSReadlineOption -Bellstyle 'none'
$options = Get-PSReadlineOption
$ForegroundColor                                = "White"
$Options.CommandForegroundColor                 = 'Cyan'
$Options.ParameterForegroundColor               = 'DarkCyan'
$Options.OperatorForegroundColor                = 'Magenta'
$Options.NumberForegroundColor                  = 'Magenta'
$Options.ContinuationPromptForegroundColor      = 'Magenta'
$Options.StringForegroundColor                  = 'Green'
$Options.DefaultTokenForegroundColor            = 'Green'
$Options.CommentForegroundColor                 = 'DarkGray'
$Options.VariableForegroundColor                = 'Red'
$Options.EmphasisForegroundColor                = $ForegroundColor
$Options.ErrorForegroundColor                   = $ForegroundColor
$Options.MemberForegroundColor                  = $ForegroundColor
$Options.TypeForegroundColor                    = $ForegroundColor

$BackgroundColor                                = "Black"
$Options.CommandBackgroundColor                 = $BackgroundColor
$Options.CommentBackgroundColor                 = $BackgroundColor
$Options.ContinuationPromptBackgroundColor      = $BackgroundColor
$Options.DefaultTokenBackgroundColor            = $BackgroundColor
$Options.EmphasisBackgroundColor                = $BackgroundColor
$Options.ErrorBackgroundColor                   = $BackgroundColor
$Options.KeywordBackgroundColor                 = $BackgroundColor
$Options.KeywordForegroundColor                 = $BackgroundColor
$Options.MemberBackgroundColor                  = $BackgroundColor
$Options.NumberBackgroundColor                  = $BackgroundColor
$Options.OperatorBackgroundColor                = $BackgroundColor
$Options.ParameterBackgroundColor               = $BackgroundColor
$Options.StringBackgroundColor                  = $BackgroundColor
$Options.TypeBackgroundColor                    = $BackgroundColor
$Options.VariableBackgroundColor                = $BackgroundColor

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
    Import-Module gwActiveDirectory, gwApplications, gwConfiguration, gwFilesystem, gwMisc, gwNetworking, gwSecurity -Prefix gw -ErrorAction Stop
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
