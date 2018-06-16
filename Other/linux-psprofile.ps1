<#######<Script>#######>
<#######<Header>#######>
# Name: Profile Script - Linux
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#####
<#######</Header>#######>
<#######<Body>#######>

# Changing bash shell prompt
# nano ~/.bashrc
# PS1="[\u@\h][$(printf '%(%Y-%m-%d)T\n' -1)][\w]\n> "
# or, same:
# PS1="[\u@\h][$(printf '%(%F)T\n' -1)][\w]\n> "

Function Prompt 
{
	$s = (get-date -UFormat %Y) + "-" + (get-date -UFormat %m) + "-" + (get-date -UFormat %d) + "@" + (get-date -UFormat %T)
	return "[$s;dir=$(Get-Location)]# ";
}

New-PSDrive -Name c -PSProvider Filesystem -Root /home

Write-ToString "====================="
Write-ToString "Custom profile loaded"
Write-ToString "====================="

Start-Sleep -Seconds 1
Clear-Host

<#######</Body>#######>
<#######</Script>#######>
