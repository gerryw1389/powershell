<#######<Script>#######>
<#######<Header>#######>
# Name: Set-PreformattedContent
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-PreformattedContent
{
    <#
    .Synopsis
    Adds formatted text to the beginning and end of all text, log, and powershell files in the source directory. 
    Make sure to edit the $Preformatting and $Postformatting variables before running it!
    .Description
    Adds formatted text to the beginning and end of all text, log, and powershell files in the source directory. 
    Make sure to edit the $Preformatting and $Postformatting variables before running it!
    .Parameter Path
    Mandatory parameter that specifies a source directory where your files are located.
    .Example
    Set-PreformattedContent -Source C:\scripts
    Adds formatted text to the beginning and end of all files at c:\scripts.
    #>   
    
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$Path
    )

    Begin
    {
        
    }
    
    Process
    {    
        $Files = Get-ChildItem -Path $Path | Where-Object { $_.Extension -like ".ps1" }
        Foreach ($File In $Files)
        {

            Write-Output "Processing $File ..."
    
            # Remember to use the escape character "`" before every dollar sign and ` character. For example `$myVar and ``r``n (new line)
            $Preformatting = @"
Multi-Line
Text
To
Insert
At
Top
"@

            $CurrentFile = Get-Content $File

            $PostFormatting = @"
Multi-Line
Text
To
Insert
At
Bottom
"@

            $Val = -Join $Preformatting, $CurrentFile, $PostFormatting
            Set-Content -Path $File -Value $Val
            Write-Output "$File rewritten successfully"
        }
    }

    End
    {
    }
}

<#######</Body>#######>
<#######</Script>#######>