<#######<Script>#######>
<#######<Header>#######>
# Name: Restart-NIC
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Restart-NIC
{
    <#
    .Synopsis
    Restarts one or more network cards.
    .Description
    Restarts one or more network cards.
    .Parameter NetAdapter
    Mandatory parameter that specifies the name of the NICs you want to restart.
    .Example
    Restart-NIC -NetAdapter "LAN"
    Restarts the LAN network adapter.
    #>

    [Cmdletbinding()]
    
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]]$NetAdapter
    )
    
    Begin
    {   
    }
    
    Process
    {   
        ForEach ($Adapter in $NetAdapter)
        {
            Restart-NetAdapter -Name $Adapter
            Write-Output "Restarting Adapter $Adapter"
        }
    }

    End
    {
    }
}

<#######</Body>#######>
<#######</Script>#######>