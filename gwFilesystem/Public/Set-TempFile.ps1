<#######<Script>#######>
<#######<Header>#######>
# Name: Set-TempFile
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-TempFile
{
    <#
    .Synopsis
    Creates a blank temp file to be used by other functions.
    .Description
    Creates a blank temp file to be used by other functions.
    .Parameter Path
    Mandatory parameter that specifies the path for the blank file.
    .Parameter Size
    Mandatory parameter that specifies the size of the blank file in megabytes (mb).
    .Example
    Set-TempFile -Path "c:\scripts\tempfile.txt" -Size 10mb
    Creates a file called tempfile.txt at the C:\scripts location with a size of ten megabytes.
    #>

    [Cmdletbinding()]
    
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]]$Path,

        [Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Enter the size in MB')]
        [Double]$Size
    )
    
    Begin
    {   
        
    }
    
    Process
    {   
        ForEach ($P in $Path)
        {
            If (Test-Path $P)
            {
                Write-Output "File already exists, skipping..."
            }
            Else
            {
                $File = [io.file]::Create($P)
                Write-Output "File $P created"
    
                $File.SetLength($Size)
                Write-Output "File $P set to $Size megabytes"
		
                $File.Close()  
            }
    
        }
    
    }

    End
    {
        
    }

}

<#######</Body>#######>
<#######</Script>#######>