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
    Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
    Main code usually starts around line 185ish.
    If -Verbose is not passed (Default) and logfile is not defined, don't show messages on the screen and don't transcript the session.
    If -Verbose is not passed (Default) and logfile is defined, enable verbose for them and transcript the session.
    If -Verbose is passed and logfile is defined, show messages on the screen and transcript the session.
    If -Verbose is passed and logfile is not defined, show messages on the screen, but don't transcript the session.
    2018-06-17: v1.1 Updated template.
    2017-09-08: v1.0 Initial script 
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
        <#######<Default Begin Block>#######>
        Function Write-ToString
        {
            <# 
        .Synopsis
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Description
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Parameter InputObject
        This can be any PSObject that will be converted to string.
        .Parameter Color
        The color in which to display the string on the screen.
        Valid options are: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, 
        Red, White, and Yellow.
        .Example 
        Write-ToString "Hello Hello"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen and the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen in default text colors.
        .Example 
        Write-ToString "Hello Hello" -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow and to the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Example 
        Write-ToString (cmd /c "ipconfig /all") -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow that shows the computer's IP information.
        The same copy will be in the logfile. 
        The whole point of converting to strings is this works best with tables and such that usually distort in logfiles.
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Notes
        2018-06-13: v1.0 Initial function
        #>
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color
            )
            
            $ConvertToString = Out-String -InputObject $InputObject -Width 100
            
            If ($($Color.Length -gt 0))
            {
                $previousForegroundColor = $Host.PrivateData.VerboseForegroundColor
                $Host.PrivateData.VerboseForegroundColor = $Color
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                $Host.PrivateData.VerboseForegroundColor = $previousForegroundColor
            }
            Else
            {
                Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
            }
            
        }
        If ($($Logfile.Length) -gt 1)
        {
            $Global:EnabledLogging = $True 
            Set-Variable -Name Logfile -Value $Logfile -Scope Global
            $VerbosePreference = "Continue"
            Function Start-Log
            {
                <#
                .Synopsis
                Function to write the opening part of the logfile.
                .Description
                Function to write the opening part of the logfil.
                It creates the directory if it doesn't exists and then the log file automatically.
                It checks the size of the file if it already exists and clears it if it is over 10 MB.
                If it exists, it creates a header. This function is best placed in the "Begin" block of a script.
                .Notes
                NOTE: The function requires the Write-ToString function.
                2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                2017-10-19: v1.0 Initial function
                #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
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
                [Double]$Sizemax = 10485760
                $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
                If ($($Size.Sum -ge $SizeMax))
                {
                    Get-Childitem $Logfile | Clear-Content
                    Write-ToString "Logfile has been cleared due to size"
                }
                Else
                {
                    Write-ToString "Logfile was less than 10 MB"   
                }
                # Start writing to logfile
                Start-Transcript -Path $Logfile -Append 
                Write-ToString "####################<Script>####################"
                Write-ToString "Script Started on $env:COMPUTERNAME"
            }
            Start-Log -Logfile $Logfile -Verbose

            Function Stop-Log
            {
                <# 
                    .Synopsis
                    Function to write the closing part of the logfile.
                    .Description
                    Function to write the closing part of the logfile.
                    This function is best placed in the "End" block of a script.
                    .Notes
                    NOTE: The function requires the Write-ToString function.
                    2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                    2017-10-19: v1.0 Initial function 
                    #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
                Write-ToString "Script Completed on $env:COMPUTERNAME"
                Write-ToString "####################</Script>####################"
                Stop-Transcript
            }
        }
        Else
        {
            $Global:EnabledLogging = $False
        }
        <#######</Default Begin Block>#######>
    
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
        If ($Global:EnabledLogging)
        {
            Stop-Log -Logfile $Logfile
        }
        Else
        {
            $Date = $(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt")
            Write-Output "Function completed at $Date"
        }
    }
}

<#######</Body>#######>
<#######</Script>#######>