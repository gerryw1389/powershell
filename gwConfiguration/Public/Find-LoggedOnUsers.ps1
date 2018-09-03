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
    .Example
    Find-LoggedOnUsers
    Finds logged on users for the current computer.
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
        $ComputerName = $env:Computername
        Write-Output "Running Query.Exe Against $ComputerName"
        $Users = Query User /Server:$ComputerName 2>&1
		
        If ($Users -Like "*No User Exists*")
        {
            # Handle No User's Found Returned From Query.
            # Returned: 'No User Exists For *'
            Write-Output "There Were No Users Found Logged On $ComputerName"
        }
        Elseif ($Users -Like "*Error*")
        {
            # Handle Errored Returned By Query.
            # Returned: 'Error ...<Message>...'
            Write-Output "There Was An Error Running Query Against $ComputerName"
        }
        Elseif ($Users -Eq $Null -And $Erroractionpreference -Eq 'Silentlycontinue')
        {
            # Handle Null Output Called By -Erroraction.
            Write-Output "Error Action Has Supressed Output From Query.Exe. Results Were Null."
        }
        Else
        {
            Write-Output "Users Found On $ComputerName. Converting Output From Text."
			
            # Conversion Logic. Handles The Fact That The SessionName Column May Be Populated Or Not.
            $Users = $Users | Foreach-Object {
                (($_.trim() -replace ">" -replace "(?m)^([A-Za-z0-9]{3,})\s+(\d{1,2}\s+\w+)", '$1  none  $2' -replace "\s{2,}", "," -replace "none", $null))
            } | Convertfrom-Csv
			
            Write-Output "Generating Output For $($Users.Count) Users Connected To $ComputerName"
    
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
                    Write-Output "User found: $($User.Username)"
                }
    
                $Results += $Output
            }
    
            Write-Output $Results
        }
    }
	
    End
    {
        
    }
} 

<#######</Body>#######>
<#######</Script>#######>