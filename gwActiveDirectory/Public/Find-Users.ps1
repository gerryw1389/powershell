<#######<Script>#######>
<#######<Header>#######>
# Name: Find-Users
<#######</Header>#######>
<#######<Body>#######>
Function Find-Users
{
    <#
.Synopsis
Shows the 'Find Users' GUI Window for searching AD.
.Description
Shows the 'Find Users' GUI Window for searching AD.
I think you must have RSAT installed.
.Example
Find-Users
Shows the 'Find Users' GUI Window for searching AD.
#>
    $cmdArgs = @(
        '/C',
        'start Rundll32 dsquery.dll OpenQueryWindow'
    )
    Start-Process -FilePath $env:windir\system32\cmd.exe -ArgumentList $cmdArgs
}
<#######</Body>#######>
<#######</Script>#######>