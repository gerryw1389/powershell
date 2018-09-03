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
    .Example
    Get-VideoFileInfo -Source "E:\videos" -OutputFile "C:\temp\videos.csv"
    Given a source directory, this function will recursively get all the video files and display their resolutions.
    .Notes
    Source info: https://gallery.technet.microsoft.com/scriptcenter/Retrieve-file-metadata-6814c8ba
    #>
    
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]$Source,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [String]$OutputFile
    )

    Begin
    {
    }

    Process
    {    
        $Objshell = New-Object -Comobject Shell.Application 

        $Filelist = [System.Collections.ArrayList]@()
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
                [Void]$Filelist.Add($File) 
                $Filelist.Count 
            } 
        } 
 
        $Filelist | Export-Csv $Outputfile -Delimiter ',' 
        $Filelist | Format-Table
    }

    End
    {
    }
}

<#######</Body>#######>
<#######</Script>#######>