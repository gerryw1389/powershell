<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-RandomPIN
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from:  https://github.com/BornToBeRoot/PowerShell/blob/master/Documentation/Function/Get-RandomPIN.README.md
<#######</Header>#######>
<#######<Body>#######>
Function Invoke-RandomPIN
{
    <#
.Synopsis
Generate PINs with freely definable number of numbers
.Description
Generate PINs with freely definable number of numbers. You can also set the smallest and greatest possible number.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Get-RandomPIN -Length 8
PIN
---
18176072
.EXAMPLE
Get-RandomPIN -Length 6 -Count 5 -Minimum 4 -Maximum 8
Count PIN
----- ---
    1 767756
    2 755655
    3 447667
    4 577646
    5 644665
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0)][Int32]$Length = 4,

        [Parameter(ParameterSetName = 'NoClipboard', Position = 1)][Int32]$Count = 1,
    
        [Parameter(ParameterSetName = 'Clipboard', Position = 1)][switch]$CopyToClipboard,

        [Parameter(Position = 2)][Int32]$Minimum = 0,
    
        [Parameter(Position = 3)][Int32]$Maximum = 9,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Invoke-RandomPIN.log"
    )
    
    Begin
    {   
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
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
        Try
        {
            for ($i = 1; $i -ne $Count + 1; $i++)
            { 
                $PIN = [String]::Empty
                while ($PIN.Length -lt $Length)
                {
                    # Create random numbers
                    $PIN += (Get-Random -Minimum $Minimum -Maximum $Maximum).ToString()
                }
                # Return result
    
                if ($Count -eq 1)
                {
                    # Set to clipboard
                    if ($CopyToClipboard)
                    {
                        Set-Clipboard -Value $PIN
                    }
                    [pscustomobject] @{
                        PIN = $PIN
                    }
                }
                else 
                {        
                    [pscustomobject] @{
                        Count = $i
                        PIN   = $PIN
                    }    
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