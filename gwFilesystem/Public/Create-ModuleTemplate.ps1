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
    .Example
    New-Module -Path "C:\scripts" -Module "Test"
    Creates a new module to work with.
    #>

    [Cmdletbinding()]
    
    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Path,
    
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Modulename
    )
    
    Begin
    {       
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
            $Params = @{
                Path          = ($ModulePath + "\" + $Modulename + ".psd1")
                Guid          = $GUID 
                Author        = 'Gerry.Williams'
                RootModule    = ($ModuleName + ".psm1") 
                ModuleVersion = "1.0" 
                Description   = "Change later"
                Copyright     = '(c) 2018 Gerry Williams. All rights reserved.'
            }
            
            New-ModuleManifest @Params
            Clear-Variable -Name Params

            # Create folders
            New-Item -Path $ModulePath -ItemType Directory -Name Private | Out-Null
            New-Item -Path $ModulePath -ItemType Directory -Name Public | Out-Null
            New-Item -Path $ModulePath -ItemType Directory -Name Logs | Out-Null
    
            # Create latest helpers module
            $HelpersFromGithHub = Invoke-WebRequest "https://raw.githubusercontent.com/gerryw1389/master/master/gwSecurity/Private/helpers.psm1"
            $ModuleText = $($HelpersFromGithHub.Content)
            New-Item -Path ($ModulePath + "\Private") -ItemType File -Name helpers.psm1 -Value $ModuleText | Out-Null
    
            Write-Output "Module $Modulename created successfully!"
        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }

    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>

