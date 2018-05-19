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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
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
    }
    
    Process
    {   
        $ComputerName = $env:Computername
        Write-Output "Running Query.Exe Against $ComputerName" | Timestamp
        $Users = Query User /Server:$ComputerName 2>&1
		
        If ($Users -Like "*No User Exists*")
        {
            # Handle No User's Found Returned From Query.
            # Returned: 'No User Exists For *'
            Write-Output "There Were No Users Found Logged On $ComputerName." | Timestamp
        }
        Elseif ($Users -Like "*Error*")
        {
            # Handle Errored Returned By Query.
            # Returned: 'Error ...<Message>...'
            Write-Output "There Was An Error Running Query Against $ComputerName." | Timestamp
        }
        Elseif ($Users -Eq $Null -And $Erroractionpreference -Eq 'Silentlycontinue')
        {
            # Handdle Null Output Called By -Erroraction.
            Write-Output "Error Action Has Supressed Output From Query.Exe. Results Were Null." | Timestamp
        }
        Else
        {
            Write-Output "Users Found On $ComputerName. Converting Output From Text." | Timestamp
			
            # Conversion Logic. Handles The Fact That The SessionName Column May Be Populated Or Not.
            $Users = $Users | Foreach-Object {
                (($_.trim() -replace ">" -replace "(?m)^([A-Za-z0-9]{3,})\s+(\d{1,2}\s+\w+)", '$1  none  $2' -replace "\s{2,}", "," -replace "none", $null))
            } | Convertfrom-Csv
			
            Write-Output "Generating Output For $($Users.Count) Users Connected To $ComputerName" | Timestamp
    
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
                    Write-Output "User found: $($User.Username)" | Timestamp
                }
    
                $Results += $Output
            }
    
            Write-Output "$Results" | TimeStamp | TimeStamp
        }
    }
	
    End
    {
        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }
 
}   

# Find-LoggedOnUsers

<#######</Body>#######>
<#######</Script>#######>