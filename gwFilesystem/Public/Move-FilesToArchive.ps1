<#######<Script>#######>
<#######<Header>#######>
# Name: Move-FilesToArchive
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Move-FilesToArchive
{
    <#
    .Synopsis
    Moves files older than a specific number of days to a new location.
    .Description
    Moves files older than a specific number of days to a new location.
    .Parameter Source
    Mandatory parameter that specifies a source directory. This will be searched RECURSIVELY to move older files.
    .Parameter Destination
    Mandatory parameter that specifies a destination directory.
    .Parameter Days
    Mandatory parameter that specifies how many days back you want to go for moving files.
    .Example
    Move-FilesToArchive -Source C:\test -Dest C:\test2 -Days 365
    Moves files older than a specific number of days to a new location.
    #>    
    
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Source,
    
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Destination,
    
        [Parameter(Position = 2, Mandatory = $true)]
        [Int]$Days
    )

    Begin
    {    
    }
    
    Process
    {    
        Write-Output "Moving all files under directory $Source to $Destination"
        Get-Childitem $Source -Recurse |
            Where-Object { $_.Lastwritetime -Lt (Get-Date).Adddays( - $Days) } | 
            Move-Item -Destination $Destination -Force
    }
    
    End
    {   
    }
}

<#######</Body>#######>
<#######</Script>#######>