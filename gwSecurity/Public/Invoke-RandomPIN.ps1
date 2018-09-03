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
    #>

    [Cmdletbinding()]
    
    Param
    (
        [Parameter(Position = 0)][Int32]$Length = 4,

        [Parameter(ParameterSetName = 'NoClipboard', Position = 1)][Int32]$Count = 1,
    
        [Parameter(ParameterSetName = 'Clipboard', Position = 1)][switch]$CopyToClipboard,

        [Parameter(Position = 2)][Int32]$Minimum = 0,
    
        [Parameter(Position = 3)][Int32]$Maximum = 9
    )
    
    Begin
    {   
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
    }

}

<#######</Body>#######>
<#######</Script>#######>