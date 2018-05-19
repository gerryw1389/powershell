Function Restart-Computers
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string[]]$ComputersToRestart
    )

    ForEach ($Computer in $ComputersToRestart)
    {
        # If the user uses the -Whatif parameter, this will show: 
        # What if: Performing the operation "Rebooting the server" on target "Server01", but won't actually do it.
        If ($pscmdlet.ShouldProcess("$Computer", "Rebooting the server"))
        {
            # Put code here for code you want to run if the user DOESN'T USE the -WhatIf parameter
            Write-Output "Restarting computer $Computer"
            Restart-Computer $Computer 
        }
    }
}
Restart-Computers -ComputersToRestart "Server01", "Server02" -WhatIf