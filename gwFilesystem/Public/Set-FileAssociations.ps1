<#######<Script>#######>
<#######<Header>#######>
# Name: Set-FileAssociations
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Set-FileAssociations
{
    <#
.Synopsis
Sets file associations in Windows using the assoc and ftype commands.
.Description
Sets file associations in Windows using the assoc and ftype commands.
.Parameter Fileextensions
Mandatory. This string or set of strings defines the file extensions you want to associate with a program.
.Parameter OpenAppPath
Mandatory. This string defines the path to a program.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Set-FileAssociations -Fileextensions .Png, .Jpeg, .Jpg -Openapppath "C:\Program Files\Imageglass\Imageglass.Exe"
Sets file associations in Windows using the assoc and ftype commands.
In this case, the extensions ".png, .jpeg, and .jpg" are associated with a program called ImageGlass.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>   
    
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]]$Fileextensions,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [String]$Openapppath,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-FileAssociations.Log"
    )

    Begin
    {
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        If ($($Logfile.Length) -gt 1)
        {
            $EnabledLogging = $True
        }
        Else
        {
            $EnabledLogging = $False
        }
    
        Filter Timestamp
        {
            "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $_"
        }

        If ($EnabledLogging)
        {
            # Create parent path and logfile if it doesn't exist
            $Regex = '([^\\]*)$'
            $Logparent = $Logfile -Replace $Regex
            If (!(Test-Path $Logparent))
            {
                New-Item -Itemtype Directory -Path $Logparent -Force | Out-Null
            }
            If (!(Test-Path $Logfile))
            {
                New-Item -Itemtype File -Path $Logfile -Force | Out-Null
            }
    
            # Clear it if it is over 10 MB
            $Sizemax = 10
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            $Sizemb = "{0:N2}" -F ($Size.Sum / 1mb) + "Mb"
            If ($Sizemb -Ge $Sizemax)
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            # Start writing to logfile
            Start-Transcript -Path $Logfile -Append 
            Write-Output "####################<Script>####################"
            Write-Output "Script Started on $env:COMPUTERNAME" | TimeStamp
        }
    
    }
    
    Process
    {   
        If (-Not (Test-Path $Openapppath))
        {
            Write-Output "$Openapppath Does Not Exist." | Timestamp
        }   
    
        Foreach ($Extension In $Fileextensions)
        {
            $Filetype = (cmd /c "Assoc $Extension")
            $Filetype = $Filetype.Split("=")[-1] 
            cmd /c "ftype $Filetype=""$Openapppath"" ""%1"""
            Write-Output "$Fileextensions set for $Filetype" | Timestamp
        }   
    }

    End
    {
        If ($EnableLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>