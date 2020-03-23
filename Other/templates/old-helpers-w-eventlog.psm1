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
 
    If (!([System.Diagnostics.Eventlog]::SourceExists($Logfile)))
    {
        New-Eventlog -Logname Application -Source $Logfile 
    }
 
    If (Test-IsAdmin)
    {
        Limit-EventLog -LogName "Application" -MaximumSize 20MB -OverflowAction OverwriteAsNeeded
    }
			
    $Params = @{}
    $Params.Message = "####################<Script>####################"
    $Params.LogName = "Application"
    $Params.Source = $Logfile 
    $Params.EntryType = "Information" 
    $Params.EventID = 10 
    $Params.Category = 0
    Write-EventLog @Params
    $Params = $Null
 
    "####################<Script>####################" | Out-File -Encoding ASCII -FilePath $Logfile -Append
    ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "Script Started on $env:COMPUTERNAME ") | Out-File -Encoding ASCII -FilePath $Logfile -Append
           
}
 
Function Write-Log
{
    <# 
        .Synopsis
        Function to write to 3 places at once: 
        Console with Color options.
        A log file at $PSScriptRoot\..\Logs\scriptname.log.
        The Windows Event Viewer Application log.
        .Description
        Function to write to 3 places at once: 
        Console with Color options.
        A log file at $PSScriptRoot\..\Logs\scriptname.log.
        The Windows Event Viewer Application log.
        .Parameter Message
        The string to be displayed in each of the places.
        .Parameter Color
        The color in which to display the input string on the screen
        Default is DarkGreen
        Valid options are: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, 
        Red, White, and Yellow.
        .Parameter Warning
        A warning string to be displayed in each of the places.
        To search for it, type: Get-Eventlog -Logname Application -Source $Logfile | Where-Object {$_.Eventid -Eq "30"}
        .Parameter Error
        An error string to be displayed in each of the places.
        To search for it, type: Get-Eventlog -Logname Application -Source $Logfile | Where-Object {$_.Eventid -Eq "40"}
        .Example 
        Write-Log "Hello Hello"
        This will write "Hello Hello" to the console in DarkGreen text, 
        to the Windows Event Viewer as an informational event, 
        and to the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        .Example 
        Write-Log "Hello Hello Again" -Color Yellow
        This will write "Hello Hello" to the console in Yellow text, 
        to the Windows Event Viewer as an informational event, 
        and to the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        .Example 
        Write-Log -Message "Warning My Friend" -Color Magenta -Warning
        This will write "Warning My Friend" to the console in Magenta text, 
        to the Windows Event Viewer as an informational event, 
        and to the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        .Example 
        Write-Log "Oops! An Error!" -Error
        This will write "Oops! An Error!" to the console in Red text, 
        Terminates the script in place (if terminating error),
        to the Windows Event Viewer as an error event, 
        and to the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        .Example 
        Write-Log "Oops! An Error!" -Error -ExitGracefully
        This will write "Oops! An Error!" to the console in Red text,
        Will exit the script instead of terminating in place, 
        to the Windows Event Viewer as an error event, 
        and to the logfile at $PSScriptRoot\..\Logs\scriptname.log.
        .Notes
        2018-03-21: v1.1 Back from the dead
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
        [String]$Logfile ,
        
        [Switch] $Warning,
                
        [Switch] $Error,
 
        [Switch] $ExitGracefully         
    )
    
    If ($Warning)
    {
        Write-Host $Message -Foregroundcolor "Gray"
        Write-EventLog -Message $Message -LogName Application -Source $Logfile -EntryType Warning -EventID 30 -Category 0
        ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "WARNING: " + "$Message") | Out-File -Encoding ASCII -FilePath $Logfile -Append
    }
    
    ElseIf ($Error)
    {
        Write-Host $Message -Foregroundcolor "Red" 
        Write-EventLog -Message $Message -LogName Application -Source $Logfile -EntryType Error -EventID 40 -Category 0
        ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "ERROR: " + "$Message") | Out-File -Encoding ASCII -FilePath $Logfile -Append
    }
    
    ElseIf ( $ExitGracefully)
    {
        Write-Error $Message -Foregroundcolor "Red" 
        Write-EventLog -Message $Message -LogName Application -Source $Logfile -EntryType Error -EventID 90 -Category 0 
        ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "ERROR: " + "$Message") | Out-File -Encoding ASCII -FilePath $Logfile -Append
        ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "ERROR: " + "Exiting early / breaking out!") | Out-File -Encoding ASCII -FilePath $Logfile -Append
        Stop-Log
        Break
    }
    
    Else
    {
        Write-Host $Message -Foregroundcolor $Color 
        Write-EventLog -Message $Message -LogName Application -Source $Logfile -EntryType Information -EventID 20 -Category 0
        ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "$Message") | Out-File -Encoding ASCII -FilePath $Logfile -Append
    }
  
}
New-Alias -Name "Log" -Value Write-Log
 
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
 
    $Params = @{}
    $Params.Message = "####################</Script>####################"
    $Params.LogName = "Application"
    $Params.Source = $Logfile 
    $Params.EntryType = "Information" 
    $Params.EventID = 50 
    $Params.Category = 0
    Write-EventLog @Params
    $Params = $Null
 
    ((Get-Date -Format "yyyy-MM-dd hh:mm:ss tt") + ": " + "Script Completed on $env:COMPUTERNAME") | Out-File -Encoding ASCII -FilePath $Logfile -Append
    "####################</Script>####################" | Out-File -Encoding ASCII -FilePath $Logfile -Append
}
 
# Find out when a script was started:
# Get-Eventlog -Logname Application -Source $Logfile | Where-Object {$_.Eventid -Eq "10"}
 
# Get all the informational events:
# Get-Eventlog -Logname Application -Source $Logfile | Where-Object {$_.Eventid -Eq "20"}
 
# Get all the warning events:
# Get-Eventlog -Logname Application -Source $Logfile | Where-Object {$_.Eventid -Eq "30"}
 
# Get all the error events:
# Get-Eventlog -Logname Application -Source $Logfile | Where-Object {$_.Eventid -Eq "40"}
 
# Get all the error events that exited gracefully:
# Get-Eventlog -Logname Application -Source $Logfile | Where-Object {$_.Eventid -Eq "45"}
 
# Get all the script completed successfully events:
# Get-Eventlog -Logname Application -Source $Logfile | Where-Object {$_.Eventid -Eq "50"}
 
# To See Events:
# $Events = Get-Eventlog -Logname Application -Source $Logfile
# $Events | Sort -Property Index
 
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
        Writes a registry entry. Very similar to New-ItemTypeProperty except it always uses force and will create the path to the entry automatically.
        .Description
        Writes a registry entry. Very similar to New-ItemTypeProperty except it always uses force and will create the path to the entry automatically.
        .Parameter Path
        This is the path to a key.
        .Parameter Name
        This is the name of the entry.
        .Parameter Value
        This is the value of the entry.
        .Parameter PropertyType
        This is the type of entry the function is to write. Default is "Dword", but also accepts all the others, including Binary.
        Note on Binary:
        You will need to export the key you are about to change first (from a machine that has it how you want it) and then copy and paste the results into the $Value variable.
        For example, if I want OneDrive to not run on startup I would export the keys from [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run]
        on a machine that I already have OneDrive disabled on startup and then copy the $Value as "03,00,00,00,cd,9a,36,38,64,0b,d2,01". I would then place:
        $Params = @{}
        $Params.Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
        $Params.Name = "OneDrive"
        $Params.Value = "03,00,00,00,cd,9a,36,38,64,0b,d2,01"
        $Params.PropertyType = "Binary"
        Set-Regentry @Params
        $Params = $Null
    #>
    
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]$Path,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [String]$Name,
    
        [Parameter(Position = 2, Mandatory = $True)]
        [String]$Value,
 
        [Parameter(Position = 3, Mandatory = $False)]
        [ValidateSet('String', 'Expandstring', 'Binary', 'DWord', 'MultiString', 'Qword', 'Unknown')]
        [String]$PropertyType = "Dword"
 
    )
    
    If (!(Test-Path HKCR:))
    {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    }
    
    If ($PropertyType -eq "Binary")
    {
        If (!(Test-Path $Path))
        {
            New-Item -Path $Path -Force | Out-Null
        }
        $Test = (((Get-Item -Path $Path).GetValue($Name) -eq $Value)) 
        If ($Test)
        {
            Write-Log "Key already exists: $name at $Path" -Color Gray -Logfile $Logfile
        }
        Else
        {
            $Hex = $Value.Split(',') | ForEach-Object -Process { "0x$_" }
            New-ItemProperty -Path $Path -Name $Name -Value ([byte[]]$Hex) -PropertyType $PropertyType -Force | Out-Null
            Write-Log "Added Key: $Name at $Path" -Color Gray -Logfile $Logfile
        }
    }
    Else
    {
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
            New-Itemproperty -Path $Path -Name $Name -Value $Value -Propertytype $PropertyType -Force | Out-Null
            Write-Log "Added Key: $Name at $Path" -Color Gray -Logfile $Logfile
        }
    }
}
New-Alias -Name "SetReg" -Value Set-Regentry
 
Export-ModuleMember -Function * -Alias *
 
<#######</Body>#######>
<#######</Module>#######>