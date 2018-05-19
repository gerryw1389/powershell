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
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
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
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$UserName,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Get-LastUserAuthentication.log"
    )
    
    Begin
    {   
        If ($($Logfile.Length) -gt 1)
        {
            $EnabledLogging = $True
        }
        Else
        {
            $EnabledLogging = $False
        }
        
        Filter Timestamp
        {
            "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $_"
        }

        If ($EnabledLogging)
        {
            # Create parent path and logfile if it doesn't exist
            $Regex = '([^\\]*)$'
            $Logparent = $Logfile -Replace $Regex
            If (!(Test-Path $Logparent))
            {
                New-Item -Itemtype Directory -Path $Logparent -Force | Out-Null
            }
            If (!(Test-Path $Logfile))
            {
                New-Item -Itemtype File -Path $Logfile -Force | Out-Null
            }
    
            # Clear it if it is over 10 MB
            $Sizemax = 10
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            $Sizemb = "{0:N2}" -F ($Size.Sum / 1mb) + "Mb"
            If ($Sizemb -Ge $Sizemax)
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            # Start writing to logfile
            Start-Transcript -Path $Logfile -Append 
            Write-Output "####################<Script>####################"
            Write-Output "Script Started on $env:COMPUTERNAME" | TimeStamp
        }

        # Load the required module(s)        
        If (-not(Get-module ActiveDirectory)) 
        {
            Import-Module ActiveDirectory
        }
        Else
        {
            Write-Output "Module was not found, please make sure the module exists! Exiting function." | Timestamp
            Exit 1
        }

        $UsersObj = @()
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
                    $UserObj = [Ordered]@{}
                    $UserObj.Name = $l.Name
                    $UserObj.LastLogonTime = [datetime]::FromFileTime($l.'lastLogonTimeStamp')
                    $usersobj += $userobj
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
        Write-Output $a | TimeStamp
        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>