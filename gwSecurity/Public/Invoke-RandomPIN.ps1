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
        [Parameter(Position = 0, HelpMessage = 'Length of the PIN (Default=4)')]
        [ValidateScript( {if ($_ -eq 0){ throw "Length of the PIN can not be 0!" } else{ return $true }})]
        [Int32]$Length = 4,

        [Parameter(ParameterSetName = 'NoClipboard', Position = 1, HelpMessage = 'Number of PINs to be generated (Default=1)')]
        [ValidateScript( {if ($_ -eq 0){ throw "Number of PINs to be generated can not be 0" } else{ return $true }})]
        [Int32]$Count = 1,
        
        [Parameter(ParameterSetName = 'Clipboard', Position = 1, HelpMessage = 'Copy PIN to clipboard')]
        [switch]$CopyToClipboard,

        [Parameter(Position = 2, HelpMessage = 'Smallest possible number (Default=0)')]
        [Int32]$Minimum = 0,
        
        [Parameter(Position = 3, HelpMessage = 'Greatest possible number (Default=9)')]
        [ValidateScript( { if ($_ -lt $Minimum){ throw "Minimum can not be greater than maximum!" }})]
        [Int32]$Maximum = 9,
            
        [String]$Logfile = "$PSScriptRoot\..\Logs\Invoke-RandomPIN.log"
    )
    
    Begin
    {       
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Console
        Start-Log
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
            Log $($_.Exception.Message) -Error -ExitGracefully
        }
    }

    End
    {
        Stop-Log  
    }

}

<#######</Body>#######>
<#######</Script>#######>