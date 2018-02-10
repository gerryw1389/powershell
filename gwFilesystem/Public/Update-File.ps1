<#######<Script>#######>
<#######<Header>#######>
# Name: Update-File
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Update-File
{    
    <#
.Synopsis
Same as unix "touch" command. Updates a pre-existing file's "lastwritetime" property or creates a new emtpy file.
.Description
Same as unix "touch" command. Updates a pre-existing file's "lastwritetime" property or creates a new emtpy file.
.Parameter File
Mandatory parameter that specifies the file or files to be created or updated.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Update-File C:\scripts\text.txt
Creates a "text.txt" in C:\scripts. If it already exists, it just updates the file's "lastwritetime" property.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [String[]]$File,

        [String]$Logfile = "$PSScriptRoot\..\Logs\Update-File.Log"
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
        
        
        
        Foreach ($F In $File)
        {
            If (Test-Path -Literalpath $F)
            {
                # File Exists, Update Last Write Time To Now
                $Setprops = @{
                    Literalpath = $F
                    Name        = 'Lastwritetime'
                    Value       = (Get-Date)
                }
                Set-Itemproperty @Setprops
                Log "$F already exists, updating file to today's lastwritetime" 
            }
            Else
            {
                # Create New File. 
                # Don't Use `Echo $Null > $File` Because It Creates An Utf-16 (Le)
                # And A Lot Of Tools Have Issues With That
                Write-Output $Null | Out-File -Encoding Ascii -Literalpath $F
                Log "$F does not exist, creating an empty file" 
                # Alternative
                # New-Item -Path $File -Itemtype File | Out-Null
            }
        }
	
    }

    End
    {
        Stop-Log  
    }

}   

# Update-File

<#######</Body>#######>
<#######</Script>#######>