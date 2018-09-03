<#######<Script>#######>
<#######<Header>#######>
# Name: Set-FileTimeStamps
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-FileTimeStamps
{
    <#
    .Synopsis
    Sets the time stamps for all files in a given folder (and optionally, subfolders) to a specific date.
    .Description
    Sets the time stamps for all files in a given folder (and optionally, subfolders) to a specific date.
    .Example
    Set-FileTimeStamps -Source C:\scripts -Date 3/3/2015
    Sets the time stamps for all files in a given folder to a specific date.
    .Example
    Set-FileTimeStamps -Path C:\scripts -Date 3/3/2015 -Recurse
    Sets the time stamps for all files in a given folder and subfolders to a specific date.
    #>  

    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Source,
    
        [Parameter(Position = 1, Mandatory = $true)]
        [DateTime]$Date,
    
        [Parameter(Position = 2)]
        [Switch]$Recurse
    )

  
    Begin
    {    
    }
    
    Process
    {    
        If ($Recurse)
        {
            Get-ChildItem -Path $Source -Recurse |
                ForEach-Object {
                $_.CreationTime = $Date
                $_.LastAccessTime = $Date
                $_.LastWriteTime = $Date }
            Write-Output "All files in $Source successfully set to $Date"
        }
    
        Else
        {
            Get-ChildItem -Path $Source |
                ForEach-Object {
                $_.CreationTime = $Date
                $_.LastAccessTime = $Date
                $_.LastWriteTime = $Date }
            Write-Output "All files in $Source successfully set to $Date"
        }
    }

    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>