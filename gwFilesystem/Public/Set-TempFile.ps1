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
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Set-TempFile -Path "c:\scripts\tempfile.txt" -Size 10mb
Creates a file called tempfile.txt at the C:\scripts location with a size of ten megabytes.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]]$Path,

        [Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Enter the size in MB')]
        [Double]$Size,
        
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-TempFile.log"
    )
    
    Begin
    {       
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log 
    }
    
    Process
    {   
        ForEach ($P in $Path)
        {
            If (Test-Path $P)
            {
                "File already exists, skipping..."
            }
            Else
            {
                $File = [io.file]::Create($P)
                Log "File $P created"
        
                $File.SetLength($Size)
                Log "File $P set to $Size megabytes"
		
                $File.Close()  
    		}
        
        }
        
    }

    End
    {
        Stop-Log  
    }

}

# Set-TempFile

<#######</Body>#######>
<#######</Script>#######>