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
    Write-Output "Module gw* was not found, moving on."
}

Try
{
    Import-Module PSColor -ErrorAction Stop
    $global:PSColor.File.Executable.Color = 'DarkGreen'
}
Catch
{
    Write-Output "Module PSColor was not found, moving on."
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
	
    # Option 3: For a minimalistic feel
    Write-Host "[$curPath]"
    "$('>' * ($nestedPromptLevel + 1)) "
    Return " "
	
}

Clear-Host

<#######</Body>#######>
<#######</Script>#######>