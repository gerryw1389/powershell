<#######<Script>#######>
<#######<Header>#######>
# Name: Set-AppendedHostFile
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-AppendedHostFile
{
    <#
    .Synopsis
    Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
    .Description
    Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
    # http://winhelp2002.mvps.org/hosts.txt
    # https://raw.githubusercontent.com/stevenblack/hosts/master/hosts
    # http://someonewhocares.org/hosts/
    .Example
    Set-AppendedHostFile
    Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
    #>
    
    [Cmdletbinding()]

    Param
    (
    )

    Begin
    {
    }
    
    Process
    {    
        # Get Hostfile Values From Winhelp2002.Mvps.Org, Github, And Someonewhocares.Org And Store Them In Separate Text Files
        $Hfv = Invoke-Webrequest "http://winhelp2002.mvps.org/hosts.txt"
        New-Item -Itemtype File -Path "$PSScriptRoot\Hfv.txt" -Value $Hfv.Content  | Out-Null
        Write-Output "Created $PSScriptRoot hfv.txt from winhelp2002"
        $Hfv2 = Invoke-Webrequest "https://raw.githubusercontent.com/stevenblack/hosts/master/hosts"
        New-Item -Itemtype File -Path "$PSScriptRoot\Hfv2.txt" -Value $Hfv2.Content  | Out-Null
        Write-Output "Created $PSScriptRoot hfv2.txt from Github"
        $Hfv3 = Invoke-Webrequest "http://someonewhocares.org/hosts/"
        New-Item -Itemtype File -Path "$PSScriptRoot\Hfv3.txt" -Value $Hfv3.Content  | Out-Null
        Write-Output "Created $PSScriptRoot hfv3.txt from someonewhocares.org"
        # Combine The Files

        $Merged = Get-Content "$PSScriptRoot\Hfv.txt"
        $Merged2 = Get-Content "$PSScriptRoot\Hfv2.txt" | Select-Object -Skip 67
        $Merged3 = Get-Content "$PSScriptRoot\Hfv3.txt" | Select-Object -Skip 117
        $Total = $Merged + $Merged2 + $Merged3
        $Total | Out-File "$PSScriptRoot\combined.txt"

        # Modify The File
        $A = @"
# Please See:
# http://winhelp2002.mvps.org/hosts.txt
# https://raw.githubusercontent.com/stevenblack/hosts/master/hosts
# http://someonewhocares.org/hosts/
# Follow Their Rules In Regards To Licensing And Copyright
# Entries Below
"@
        Write-Output "Cleaning The File By Removing Anything That Is Not A 0 Or 1"
        $B = Get-Content "$PSScriptRoot\combined.txt" | Where-Object { $_ -Match "^0" -Or $_ -Match "^1"}
        $C = -Join $A, $B
        Write-Output "Replace All 127.0.0.1 With 0.0.0.0"
        $D = $C.Replace("127.0.0.1", "0.0.0.0")

        Write-Output "Sort Alphabetically And Remove Duplicates"
        $E = $D | Sort-Object | Get-Unique
        $E | Out-File "$PSScriptRoot\host.txt"

        Write-Output "Appending To The Current Windows Host File"
        Add-Content -Value $E -Path "$($Env:Windir)\System32\Drivers\Etc\Hosts"

        # Clean Up
        Write-Output "Deleting Txt Files Created By Script"
        Remove-Item -Path "$PSScriptRoot\combined.txt"
        Remove-Item -Path "$PSScriptRoot\Hfv.txt"
        Remove-Item -Path "$PSScriptRoot\Hfv2.txt"
        Remove-Item -Path "$PSScriptRoot\Hfv3.txt"
        Remove-Item -Path "$PSScriptRoot\host.txt"
    }

    End
    {
        $Input = Read-Host "Would You Like To See Your Windows Host File? (Y)Yes Or (N)No"
        If ($Input -Eq "Y")
        {
            Invoke-Item "$($Env:Windir)\System32\Drivers\Etc\Hosts"
        }
        Else
        {
            Exit
        }
    }
}

<#######</Body>#######>
<#######</Script>#######>