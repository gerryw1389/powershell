<#######<Script>#######>
<#######<Header>#######>
# Name: New-Module
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function New-Module
{
    <#
.Synopsis
Creates a new module to work with.
.Description
Creates a new module to work with.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
.Example
New-Module -Path "C:\scripts" -Module "Test"
Usually same as synopsis.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Path,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Modulename,
        
        [String]$Logfile = "$PSScriptRoot\..\Logs\New-gwModule.log"
    )
    
    Begin
    {       
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*:Logfile" = $Logfile }
        Set-Console
        Start-Log
    }
    
    Process
    {   
        Try
        {
            [String]$ModulePath = ($Path + "\" + $ModuleName)
            New-Item -Path $Path -ItemType Directory -Name $Modulename | Out-Null
            
            # Create .psm1
            $HelpersFromGithHub = Invoke-WebRequest "https://raw.githubusercontent.com/gerryw1389/master/master/gwSecurity/gwSecurity.psm1"
            $ModuleText = $($HelpersFromGithHub.Content)
            New-Item -Name ($ModuleName + ".psm1") -Path $ModulePath -ItemType File -Value $ModuleText | Out-Null

            # Create .psd1
            $GUID = [guid]::NewGuid().ToString() 
            $Params = @{}
            $Params.Path = ($ModulePath + "\" + $Modulename + ".psd1")
            $Params.Guid = $GUID 
            $Params.Author = 'Gerry.Williams'
            $Params.RootModule = ($ModuleName + ".psm1") 
            $Params.ModuleVersion = "1.0" 
            $Params.Description = "Change later"
            $Params.Copyright = '(c) 2017 Gerry Williams. All rights reserved.'
            New-ModuleManifest @Params
            Clear-Variable -Name Params

            # Create folders
            New-Item -Path $ModulePath -ItemType Directory -Name Private | Out-Null
            New-Item -Path $ModulePath -ItemType Directory -Name Public | Out-Null
            New-Item -Path $ModulePath -ItemType Directory -Name Logs | Out-Null
            
            # Create latest helpers module
            $HelpersFromGithHub = Invoke-WebRequest "https://raw.githubusercontent.com/gerryw1389/master/master/gwSecurity/Private/helpers.psm1"
            $ModuleText = $($HelpersFromGithHub.Content)
            New-Item -Path ($ModulePath  + "\Private") -ItemType File -Name helpers.psm1 -Value $ModuleText | Out-Null
            
            Log "Module $Modulename created successfully!"
        }
        Catch
        {
            Log $($_.Exception.Message) -Error -ExitGracefully
        }
    }

    End
    {
        Stop-Log  
    }

}

# New-gwModule -Path c:\scripts -ModuleName myTemplate

<#######</Body>#######>
<#######</Script>#######>

