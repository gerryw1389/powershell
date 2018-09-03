<#######<Script>#######>
<#######<Header>#######>
# Name: New-BatLaunchers
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function New-BatLaunchers
{
    <#
    .Synopsis
    Creates batch files for each powershell script in a directory.
    .Description
    Creates batch files for each powershell script in a directory.
    .Parameter Path
    The path to the scripts directory with the powershell scripts.
    .Example
    New-BatLaunchers -Path C:\scripts
    Creates a batch file for every powershell script that when double clicked, launches the script bypassing Executionpolicy.
    #>

    [Cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [String]$Path
    )
    
    Begin
    {   
        Function Write-TestFiles
        {
            New-Item -Path "C:\scripts" -Name "g" -ItemType Directory -Force | Out-Null
            New-Item -Path "C:\scripts\g" -Name "1.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g" -Name "2.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g" -Name "h" -ItemType Directory -Force | Out-Null
            New-Item -Path "C:\scripts\g\h" -Name "1.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g\h" -Name "2.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g\h" -Name "i" -ItemType Directory -Force | Out-Null
            New-Item -Path "C:\scripts\g\h\i" -Name "1.ps1" -ItemType File -Force | Out-Null
            New-Item -Path "C:\scripts\g\h\i" -Name "2.ps1" -ItemType File -Force | Out-Null
        }
    }
    
    Process
    {   
        # Write-TestFiles
        $Files = Get-ChildItem $Path -Filter "*.ps1" -Recurse

        ForEach ($File in $Files)
        {
            Write-Output "Creating batch launcher for file $file"
            $Batch = $($File.DirectoryName) + "\" + $($File.BaseName) + ".bat"
            $String = @"
`@ECHO OFF
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dpn0.ps1""' -Verb RunAs}"
PAUSE
"@
            Write-Output $String | Out-File -LiteralPath $Batch -Encoding ascii

        }
    }

    End
    {
    }
}

<#######</Body>#######>
<#######</Script>#######>