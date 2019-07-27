<#######<Script>#######>
<#######<Header>#######>
# Name: Start-TimeTracker
<#######</Header>#######>
<#######<Body>#######>
Function Start-TimeTracker
{
    <#
.Synopsis
Best placed as a scheduled task, this is an interactive script that pops up and asks/records what you are doing.
.Description
Best placed as a scheduled task, this is an interactive script that pops up and asks/records what you are doing.
.Example
Start-TimeTracker
Best placed as a scheduled task, this is an interactive script that pops up and asks/records what you are doing.
.Notes
I have this set up as:
Start at 9AM M-F, repeat task every hour for a duration of 8 hours.
#>
    [Cmdletbinding()]
    Param
    (
        [String]$OutputFile = "C:\scripts\timetracker.txt"
    )

    Begin
    {
        If (-not(Test-Path $OutputFile))
        {
            New-Item -ItemType File -Path $OutputFile | Out-Null
        }
    }
    Process
    {
		$Task = Read-Host "What are you working on?"
		$Defaultvalue = '1'
		$Timespent = Read-Host "For how long?"
		$Timespent = ($Defaultvalue, $TimeSpent)[[Bool]$TimeSpent]
        $Text = "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): [$Timespent] $Task"
        
        If ( (Get-Date).Hour -eq 9 )
        {
        Write-Output '##############################################' | Out-File $OutputFile -Encoding Ascii -Append
        }

		Write-Output $Text | Out-File $OutputFile -Encoding Ascii -Append
    }

    End
    {
        
    }
}
<#######</Body>#######>
<#######</Script>#######>