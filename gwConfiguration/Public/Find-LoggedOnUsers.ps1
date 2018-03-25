<#######<Script>#######>
<#######<Header>#######>
# Name: Find-LoggedOnUsers
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Find-LoggedOnUsers
{
    <#
.Synopsis
Finds logged on users for the current computer.
.Description
Finds logged on users for the current computer. If you wish to run against multiple computers, see below.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Find-LoggedOnUsers
Finds logged on users for the current computer.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>   

    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Find-LoggedOnUsers.Log"
    )

    Begin
    {
        Function Get-Diskspace
        {
            Get-Wmiobject Win32_Logicaldisk | Where-Object { $_.Drivetype -Eq "3" } | Select-Object Systemname,
            @{ Name = "Drive" ; Expression = { ( $_.Deviceid ) } },
            @{ Name = "Size (Gb)" ; Expression = {"{0:N1}" -F ( $_.Size / 1gb)}},
            @{ Name = "Freespace (Gb)" ; Expression = {"{0:N1}" -F ( $_.Freespace / 1gb ) } },
            @{ Name = "Percentfree" ; Expression = {"{0:P1}" -F ( $_.Freespace / $_.Size ) } } |
                Format-Table -Autosize
        }

        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Console
        Start-Log
        
    }
    
    Process
    {   
        $ComputerName = $env:Computername
        Log "Running Query.Exe Against $ComputerName" 
        $Users = Query User /Server:$ComputerName 2>&1
		
        If ($Users -Like "*No User Exists*")
        {
            # Handle No User's Found Returned From Query.
            # Returned: 'No User Exists For *'
            Log "There Were No Users Found Logged On $ComputerName." 
        }
        Elseif ($Users -Like "*Error*")
        {
            # Handle Errored Returned By Query.
            # Returned: 'Error ...<Message>...'
            Log "There Was An Error Running Query Against $ComputerName." 
        }
        Elseif ($Users -Eq $Null -And $Erroractionpreference -Eq 'Silentlycontinue')
        {
            # Handdle Null Output Called By -Erroraction.
            Log "Error Action Has Supressed Output From Query.Exe. Results Were Null." 
        }
        Else
        {
            Log "Users Found On $ComputerName. Converting Output From Text." 
			
            # Conversion Logic. Handles The Fact That The SessionName Column May Be Populated Or Not.
            $Users = $Users | Foreach-Object {
                (($_.trim() -replace ">" -replace "(?m)^([A-Za-z0-9]{3,})\s+(\d{1,2}\s+\w+)", '$1  none  $2' -replace "\s{2,}", "," -replace "none", $null))
            } | Convertfrom-Csv
			
            Log "Generating Output For $($Users.Count) Users Connected To $ComputerName" 
            
            # Output Objects.
            Foreach ($User In $Users)
            {
                $Output = [Pscustomobject]@{
                    Computername = $ComputerName
                    Username     = $User.Username
                    Sessionstate = $User.State.Replace("Disc", "Disconnected")
                    Sessiontype  = $($User.Sessionname -Replace '#', '' -Replace "[0-9]+", "")
                }
                
                If (($User.Username) -ne $null)
                {
                    Log "User found: $($User.Username)" -Color Cyan 
                }
                
                $Results += $Output
            }
            
            Log "$Results"
        }
    }
	
    End
    {
        Stop-Log  
    }
 
}   

# Find-LoggedOnUsers

<#######</Body>#######>
<#######</Script>#######>