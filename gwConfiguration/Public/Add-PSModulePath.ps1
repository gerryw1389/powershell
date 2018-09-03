<#######<Script>#######>
<#######<Header>#######>
# Name: Add-PSModulePath
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Add-PSModulePath
{
    <#
    .Synopsis
    Adds one or more paths to PS Module Path so that you can auto-load modules from a custom directory.
    .Description
    Adds one or more paths to PS Module Path so that you can auto-load modules from a custom directory.
    .Example
    Add-PSModulePath -Path "C:\Scripts\Modules"
    Adds C:\scripts\Modules to your $env:psmodulepath.
    #>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]] $Path
    )
    
    Begin
    {   
         
    }
    
    Process
    {   
        ForEach ($P in $Path)
        {
            $P = ";" + $P
            Write-Output "Adding $P to PSModulePath"
            $CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
            [Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + $P, "Machine")
        }
    }

    End
    {
        Write-Output "Make sure to restart powershell to see the new module path. Run '`$env:psmodulepath -split ';' to check"
        Write-Output "For a GUI version, run sysdm.cpl and go to Advanced - Environmental Variables - PSModulePath "
    }
}

<#######</Body>#######>
<#######</Script>#######>