<#######<Module>#######>
<#######<Header>#######>
# Name: Module
# Date: 2018-03-18
# Copyright: Gerry Williams
# License: MIT License (https://opensource.org/licenses/MIT) 
<#######</Header>#######>
<#######<Body>#######>


$Files = @( Get-ChildItem -Path $PSScriptRoot\*.ps1 -Recurse -ErrorAction SilentlyContinue)
ForEach ($File in $Files)
{ 
    . $File.fullname
}

Export-ModuleMember -Function *

<#######</Body>#######>
<#######</Module>#######>