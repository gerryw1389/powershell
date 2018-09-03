<#######<Script>#######>
<#######<Header>#######>
# Name: Get-LastUserAuthentication
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Get-LastUserAuthentication
{
    <#
    .Synopsis
    Gets the last time a user authenticated with the domain controller.
    .Description
    Gets the last time a user authenticated with the domain controller.
    .Example
    Get-LastUserAuthentication -Username "gerry", "admin"
    Name       Value
    ----       -----
    Name       Gerry
    LastLogonTime      1/26/2016 7:36:27 PM
    Name       Gerry Williams
    LastLogonTime      4/25/2018 10:47:53 PM
    Name       Administrator
    LastLogonTime      7/5/2015 3:58:05 PM
    Name       admin
    LastLogonTime      4/22/2018 9:22:18 PM
    #>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$UserName
    )
    
    Begin
    {   
        # Load the required module(s) 
        Try
        {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'ActiveDirectory' was not found, stopping script"
            Exit 1
        }

        $UsersObj = [System.Collections.Generic.List[PSObject]]@()
    }
    
    Process
    {   
        Try
        {
            ForEach ($User in $UserName)
            {
                $Logon = Get-ADUser -Filter "Name -like '$User*'" -Properties "LastLogonTimeStamp"
                # Create another level just in case it doesn't match just a single user (happens often)
                
                ForEach ($l in $logon)
                {
                    $UserObj = [Ordered]@{
                        'Name' = $($l.name)
                        'LastLogonTime' = [datetime]::FromFileTime($l.'lastLogonTimeStamp')
                    }
                    [void]$UsersObj.Add($Userobj)
                }
            }
        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }

    End
    {
        Write-Output $UsersObj
        
    }

}

<#######</Body>#######>
<#######</Script>#######>