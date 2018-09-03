<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-WSUSCleanup
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Invoke-WSUSCleanup
{
    <#
    .Synopsis
    Cleans Up The Wsus Server.
    .Description
    Cleans Up The Wsus Server.
    .Example
    Invoke-WSUSCleanup
    Cleans Up The Wsus Server.
    .Example
    Invoke-WSUSCleanup
    Cleans Up The Wsus Server.
    #>  
    
    [Cmdletbinding()]
    
    Param
    (
    )
    
    
    Begin
    {
        # Load the required module(s) 
        Try
        {
            Import-Module UpdateServices -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'UpdateServices' was not found, stopping script"
            Exit 1
        }
    }
    
    Process
    {    
        $Params = @{
            Cleanupobsoleteupdates      = $True
            Cleanupunneededcontentfiles = $True
            Declineexpiredupdates       = $True
            Declinesupersededupdates    = $True
        }
        Get-Wsusserver | Invoke-Wsusservercleanup @Params
        Write-Output "Wsus Server Has Been Cleaned"
    }

    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>