<#######<Script>#######>
<#######<Header>#######>
# Name: Set-Template
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-Template
{
    <#
    .Synopsis
    Light description.
    .Description
    More thorough description.
    .Example
    Set-Template
    Usually same as synopsis.
    .Notes
    Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
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
        Try
        {
            # Script
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