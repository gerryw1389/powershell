<#######<Script>#######>
<#######<Header>#######>
# Name: Get-LastBootTime
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Get-LastBootTime
{
    <#
    .Synopsis
    Returns the last boot time of the computer.
    .Description
    Returns the last boot time of the computer.
    .Example
    Get-LastBootTime
    Returns the last boot time of the computer.
    #>    
    
    [Cmdletbinding()]

    Param
    (
    )
   
    Begin
    {
    }    
    
    Process
    {    
        $Computer = $($env:COMPUTERNAME)
        $Lastboottime = (Get-Ciminstance -Classname Win32_Operatingsystem | Select-Object -Property Lastbootuptime).Lastbootuptime
        $LastBoot = @{
            'ComputerName' = $Computer
            'LastBootTime' = $Lastboottime
        }
        Write-Output $LastBoot
    }

    End
    {
    }

}

<#######</Body>#######>
<#######</Script>#######>