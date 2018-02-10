<#######<Module>#######>
<#######<Header>#######>
# Name: Module
# Date: 2017-10-26
# Copyright: Gerry Williams
# License: MIT License (https://opensource.org/licenses/MIT) 
<#######</Header>#######>
<#######<Body>#######>


$files = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Recurse -ErrorAction SilentlyContinue)
$files | ForEach-Object `
{ 
    . $_.fullname
}

Export-ModuleMember -Function *

<#######</Body>#######>
<#######</Module>#######>