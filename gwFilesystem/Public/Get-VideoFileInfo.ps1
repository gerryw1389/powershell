<#######<Script>#######>
<#######<Header>#######>
# Name: Get-VideoFileInfo
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Get-VideoFileInfo
{
    <#
.Synopsis
Given a source directory, this function will recursively get all the video files and display their resolutions.
.Description
Given a source directory, this function will recursively get all the video files and display their resolutions.
.Parameter Source
Mandatory - The source folder where your video files reside.
.Parameter OutputFile
Mandatory - The destination file name csv.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Get-VideoFileInfo -Source "E:\videos" -OutputFile "C:\temp\videos.csv"
Given a source directory, this function will recursively get all the video files and display their resolutions.
.Notes
Source info: https://gallery.technet.microsoft.com/scriptcenter/Retrieve-file-metadata-6814c8ba
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]$Source,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [String]$OutputFile,
    
        [String]$Logfile = "$PSScriptRoot\..\Logs\Get-VideoFileInfo.Log"
    )

    Begin
    {
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
        $Objshell = New-Object -Comobject Shell.Application 

        $Filelist = @() 
        $Attrlist = @{} 
        $Details = ( "Frame Height", "Frame Width", "Frame Rate" ) 
 
        $Objfolder = $Objshell.Namespace($Source) 
        For ($Attr = 0 ; $Attr -Le 500; $Attr++) 
        { 
            $Attrname = $Objfolder.Getdetailsof($Objfolder.Items, $Attr) 
            If ( $Attrname -And ( -Not $Attrlist.Contains($Attrname) )) 
            {  
                $Attrlist.Add( $Attrname, $Attr )  
            } 
        } 
 
        Get-ChildItem $Source -Recurse -Directory | Foreach-Object { 
            $Objfolder = $Objshell.Namespace($_.Fullname) 
            Foreach ($File In $Objfolder.Items()) 
            {
                Foreach ( $Attr In $Details) 
                { 
                    $Attrvalue = $Objfolder.Getdetailsof($File, $Attrlist[$Attr]) 
                    If ( $Attrvalue )  
                    {  
                        Add-Member -Inputobject $File -Membertype Noteproperty -Name $("A_" + $Attr) -Value $Attrvalue 
                    }  
                } 
                $Filelist += $File 
                $Filelist.Count 
            } 
        } 
 
        $Filelist | Export-Csv $Outputfile -Delimiter ',' 
        $Filelist | Format-Table
    }

    End
    {
        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

# Get-VideoFileInfo -Source "E:\videos" -OutputFile "C:\temp\videos.csv"


<#######</Body>#######>
<#######</Script>#######>