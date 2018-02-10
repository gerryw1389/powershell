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
Downloads lists of "Blacklisted"" Websites from three sources (below) and APPENDS them to your current Windows Host File.
.Description
Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
# http://winhelp2002.mvps.org/hosts.txt
# https://raw.githubusercontent.com/stevenblack/hosts/master/hosts
# http://someonewhocares.org/hosts/
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Set-AppendedHostFile
Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
.Example
"Pc2", "Pc1" | Set-AppendedHostFile
Downloads lists of "Blacklisted" Websites from three sources (below) and APPENDS them to your current Windows Host File.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>
    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-AppendedHostFile.Log"
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
        
        
        
        # Get Hostfile Values From Winhelp2002.Mvps.Org, Github, And Someonewhocares.Org And Store Them In Separate Text Files
        $Hfv = Invoke-Webrequest "http://winhelp2002.mvps.org/hosts.txt"
        New-Item -Itemtype File -Path C:\Scripts\Hfv.Txt -Value $Hfv.Content
        Log "Created C:\Scripts\hfv.txt from winhelp2002" 
        $Hfv2 = Invoke-Webrequest "https://raw.githubusercontent.com/stevenblack/hosts/master/hosts"
        New-Item -Itemtype File -Path C:\Scripts\Hfv2.Txt -Value $Hfv2.Content
        Log "Created C:\Scripts\hfv2.txt from Github" 
        $Hfv3 = Invoke-Webrequest "http://someonewhocares.org/hosts/"
        New-Item -Itemtype File -Path C:\Scripts\Hfv3.Txt -Value $Hfv3.Content
        Log "Created C:\Scripts\hfv3.txt from someonewhocares.org" 
        # Combine The Files

        $Merged = Get-Content C:\Scripts\Hfv.Txt
        $Merged2 = Get-Content C:\Scripts\Hfv2.Txt | Select-Object -Skip 67
        $Merged3 = Get-Content C:\Scripts\Hfv3.Txt | Select-Object -Skip 117
        $Total = $Merged + $Merged2 + $Merged3
        $Total | Out-File Combined.Txt

        # Modify The File
        $A = @"
# Please See:
# http://winhelp2002.mvps.org/hosts.txt
# https://raw.githubusercontent.com/stevenblack/hosts/master/hosts
# http://someonewhocares.org/hosts/
# Follow Their Rules In Regards To Licensing And Copyright
# Entries Below
"@
        Log "Cleaning The File By Removing Anything That Is Not A 0 Or 1" 
        $B = Get-Content Combined.Txt | Where-Object { $_ -Match "^0" -Or $_ -Match "^1"}
        $C = -Join $A, $B
        Log "Replace All 127.0.0.1 With 0.0.0.0" 
        $D = $C.Replace("127.0.0.1", "0.0.0.0")

        Log "Sort Alphabetically And Remove Duplicates" 
        $E = $D | Sort-Object | Get-Unique
        $E | Out-File Host.Txt

        Log "Appending To The Current Windows Host File" 
        Add-Content -Value $E -Path "$($Env:Windir)\System32\Drivers\Etc\Hosts"

        # Clean Up
        Remove-Item -Path C:\Scripts\Combined.Txt
        Remove-Item -Path C:\Scripts\Hfv.Txt
        Remove-Item -Path C:\Scripts\Hfv2.Txt
        Remove-Item -Path C:\Scripts\Hfv3.Txt
        Remove-Item -Path C:\Scripts\Host.Txt
        Log "Deleting Txt Files Created By Script"                 
    }

    End
    {
        Stop-Log
        
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
               
# Set-AppendedHostFile

<#######</Body>#######>
<#######</Script>#######>