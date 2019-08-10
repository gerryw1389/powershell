<#######<Script>#######>
<#######<Header>#######>
# Name: New-RDGFile
<#######</Header>#######>
<#######<Body>#######>
Function New-RdgFile
{
    <#
.Synopsis
This function will create a RDG file from a list of servers.
.Description
This function will create a RDG file from a list of servers.
.Example
New-RdgFile -FilePath c:\scripts\servers.txt -AppendText '.domain.com'
This script will create a .rdg file in the scripts current directory for each server listed in servers.txt
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [String]$FilePath,
        
        [Parameter(Mandatory = $false, Position = 1)]
        [String]$AppendText
    )
    
    Begin
    {

        ####################<Default Begin Block>####################
        # Force verbose because Write-Output doesn't look well in transcript files
        $VerbosePreference = "Continue"
        
        [String]$Logfile = $PSScriptRoot + '\PSLogs\' + (Get-Date -Format "yyyy-MM-dd") +
        "-" + $MyInvocation.MyCommand.Name + ".log"
        
        Function Write-Log
        {
            <#
            .Synopsis
            This writes objects to the logfile and to the screen with optional coloring.
            .Parameter InputObject
            This can be text or an object. The function will convert it to a string and verbose it out.
            Since the main function forces verbose output, everything passed here will be displayed on the screen and to the logfile.
            .Parameter Color
            Optional coloring of the input object.
            .Example
            Write-Log "hello" -Color "yellow"
            Will write the string "VERBOSE: YYYY-MM-DD HH: Hello" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Example
            Write-Log (cmd /c "ipconfig /all")
            Will write the string "VERBOSE: YYYY-MM-DD HH: ****ipconfig output***" to the screen and the logfile.
            NOTE that Stop-Log will then remove the string 'VERBOSE :' from the logfile for simplicity.
            .Notes
            2018-06-24: Initial script
            #>
            
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                # I usually set this to = "Green" since I use a black and green theme console
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color = "Green"
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

        Function Start-Log
        {
            <#
            .Synopsis
            Creates the log file and starts transcribing the session.
            .Notes
            2018-06-24: Initial script
            #>
            
            # Create transcript file if it doesn't exist
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
                Write-Verbose "Logfile has been cleared due to size"
            }
            Else
            {
                Write-Verbose "Logfile was less than 10 MB"   
            }
            Start-Transcript -Path $Logfile -Append 
            Write-Log "####################<Function>####################"
            Write-Log "Function started on $env:COMPUTERNAME"

        }
        
        Function Stop-Log
        {
            <#
            .Synopsis
            Stops transcribing the session and cleans the transcript file by removing the fluff.
            .Notes
            2018-06-24: Initial script
            #>
            
            Write-Log "Function completed on $env:COMPUTERNAME"
            Write-Log "####################</Function>####################"
            Stop-Transcript
       
            # Now we will clean up the transcript file as it contains filler info that needs to be removed...
            $Transcript = Get-Content $Logfile -raw

            # Create a tempfile
            $TempFile = $PSScriptRoot + "\PSLogs\temp.txt"
            New-Item -Path $TempFile -ItemType File | Out-Null
			
            # Get all the matches for PS Headers and dump to a file
            $Transcript | 
                Select-String '(?smi)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*([\S\s]*?)\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*' -AllMatches | 
                ForEach-Object {$_.Matches} | 
                ForEach-Object {$_.Value} | 
                Out-File -FilePath $TempFile -Append

            # Compare the two and put the differences in a third file
            $m1 = Get-Content -Path $Logfile
            $m2 = Get-Content -Path $TempFile
            $all = Compare-Object -ReferenceObject $m1 -DifferenceObject $m2 | Where-Object -Property Sideindicator -eq '<='
            $Array = [System.Collections.Generic.List[PSObject]]@()
            foreach ($a in $all)
            {
                [void]$Array.Add($($a.InputObject))
            }
            $Array = $Array -replace 'VERBOSE: ', ''

            Remove-Item -Path $Logfile -Force
            Remove-Item -Path $TempFile -Force
            # Finally, put the information we care about in the original file and discard the rest.
            $Array | Out-File $Logfile -Append -Encoding ASCII
            
        }
        
        Start-Log

        Function Set-Console
        {
            <# 
        .Synopsis
        Function to set console colors just for the session.
        .Description
        Function to set console colors just for the session.
        This function sets background to black and foreground to green.
        Verbose is DarkCyan which is what I use often with logging in scripts.
        I mainly did this because darkgreen does not look too good on blue (Powershell defaults).
        .Notes
        2017-10-19: v1.0 Initial script 
        #>
        
            Function Test-IsAdmin
            {
                <#
                .Synopsis
                Determines whether or not the user is a member of the local Administrators security group.
                .Outputs
                System.Bool
                #>

                [CmdletBinding()]
    
                $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $Principal = new-object System.Security.Principal.WindowsPrincipal(${Identity})
                $IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
                Write-Output -InputObject $IsAdmin
            }

            $console = $host.UI.RawUI
            If (Test-IsAdmin)
            {
                $console.WindowTitle = "Administrator: Powershell"
            }
            Else
            {
                $console.WindowTitle = "Powershell"
            }
            $Background = "Black"
            $Foreground = "Green"
            $Messages = "DarkCyan"
            $Host.UI.RawUI.BackgroundColor = $Background
            $Host.UI.RawUI.ForegroundColor = $Foreground
            $Host.PrivateData.ErrorForegroundColor = $Messages
            $Host.PrivateData.ErrorBackgroundColor = $Background
            $Host.PrivateData.WarningForegroundColor = $Messages
            $Host.PrivateData.WarningBackgroundColor = $Background
            $Host.PrivateData.DebugForegroundColor = $Messages
            $Host.PrivateData.DebugBackgroundColor = $Background
            $Host.PrivateData.VerboseForegroundColor = $Messages
            $Host.PrivateData.VerboseBackgroundColor = $Background
            $Host.PrivateData.ProgressForegroundColor = $Messages
            $Host.PrivateData.ProgressBackgroundColor = $Background
            Clear-Host
        }
        Set-Console

        ####################</Default Begin Block>####################

        # Helper functions for RDP file generation.
        function New-RDCManFile
        {
            <#
      .SYNOPSIS
      Creates a new Remote Desktop Connection Manager File.
      .DESCRIPTION
      Creates a new Remote Desktop Connection Manager File for version 2.7
      which can then be modified.
      .PARAMETER  FilePath
      Input the path for the file you wish to Create.
      .PARAMETER  Name
      Input the name for the Structure within the file.
      .EXAMPLE
      PS C:\> New-RDCManFile -FilePath .\Test.rdg -Name RDCMan
      'If no output is generated the command was run successfully'
      This example shows how to call the Name function with named parameters.
      .INPUTS
      System.String
      .OUTPUTS
      Null
  #>
            Param(
                [Parameter(Mandatory = $true)]
                [String]$FilePath,
    
                [Parameter(Mandatory = $true)]
                [String]$Name
            )
            BEGIN
            {
                [string]$template = @' 
<?xml version="1.0" encoding="utf-8"?>
<RDCMan programVersion="2.7" schemaVersion="3">
  <file>
    <credentialsProfiles />
    <properties>
      <expanded>True</expanded>
      <name></name>
    </properties>
  </file>
  <connected />
  <favorites />
  <recentlyUsed />
</RDCMan>
'@ 
                $FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
                if (Test-Path -Path $FilePath)
                {
                    Write-Error -Message 'File Already Exists'
                }
                else
                {
                    $xml = New-Object -TypeName Xml
                    $xml.LoadXml($template)
                }
            }
            PROCESS
            {
                $File = (@($xml.RDCMan.file.properties)[0]).Clone()
                $File.Name = $Name
    
                $xml.RDCMan.file.properties |
                    Where-Object -FilterScript {
                    $_.Name -eq ''
                } |
                    ForEach-Object -Process {
                    [void]$xml.RDCMan.file.ReplaceChild($File, $_)
                }
            }
            END
            {
                $xml.Save($FilePath)
            }
        }
        function New-RDCManGroup
        {
            <#
      .SYNOPSIS
      Creates a new Group within your Remote Desktop Connection Manager File.
      .DESCRIPTION
      Creates a new Group within your Remote Desktop Connection Manager File for version 2.7.
      which can then be modified.
      .PARAMETER  FilePath
      Input the path for the file you wish to Create.
      .PARAMETER  Name
      Input the name for the Group you wish to create within the file.
      .EXAMPLE
      PS C:\> New-RDCManGroup -FilePath .\Test.rdg -Name RDCMan
      'If no output is generated the command was run successfully'
      This example shows how to call the Name function with named parameters.
      .INPUTS
      System.String
      .OUTPUTS
      Null
  #>
            Param(
                [Parameter(Mandatory = $true)]
                [String]$FilePath,
    
                [Parameter(Mandatory = $true)]
                [String]$Name
            )
            BEGIN
            {
                $FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
                if (Test-Path -Path $FilePath)
                {
                    $xml = New-Object -TypeName XML
                    $xml.Load($FilePath)
                } 
                else
                {
                    Write-Error -Exception $_.Exception
                    throw $_.Exception
                }
            }
            PROCESS
            {
                $group = $xml.CreateElement('group')
                $grouproperties = $xml.CreateElement('properties')
      
                $groupname = $xml.CreateElement('name')
                $groupname.set_InnerXML($Name)
      
                $groupexpanded = $xml.CreateElement('expanded')
                $groupexpanded.set_InnerXML('False')
      
                [void]$grouproperties.AppendChild($groupname)
                [void]$grouproperties.AppendChild($groupexpanded)
      
                [void]$group.AppendChild($grouproperties)
                [void]$xml.RDCMan.file.AppendChild($group)
            }
            END
            {
                $xml.Save($FilePath)
            }
        }
        function New-RDCManServer
        {
            <#
      .SYNOPSIS
      Creates a new Server within a group in your Remote Desktop Connection Manager File.
      .DESCRIPTION
      Creates a new server within the  Remote Desktop Connection Manager File.
      .PARAMETER  FilePath
      Input the path for the file you wish to append a new group.
      .PARAMETER  DisplayName
      Input the name DisplayName of the server.
      
      .PARAMETER  Server
      Input the FQDN, IP Address or Hostname of the server.
      .PARAMETER  GroupName
      Input the name DisplayName of the server.
      .EXAMPLE
      PS C:\> New-RDCManServer -FilePath .\Test.rdg -DisplayName RDCMan -Server '10.10.0.5' -Group Test
      'If no output is generated the command was run successfully'
      This example shows how to call the Name function with named parameters.
      .INPUTS
      System.String
      .OUTPUTS
      Null
  #>
            Param(
                [Parameter(Mandatory = $true)]
                [String]$FilePath,
    
                [Parameter(Mandatory = $true)]
                [String]$GroupName,

                [Parameter(Mandatory = $true)]
                [String]$Server,

                [Parameter(Mandatory = $true)]
                [String]$DisplayName
            )
            BEGIN
            {
                $FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
                if (Test-Path -Path $FilePath)
                {
                    $xml = New-Object -TypeName XML
                    $xml.Load($FilePath)
                } 
                else
                {
                    Write-Error -Exception $_.Exception
                    throw $_.Exception
                }
            }
            PROCESS
            {
                $ServerNode = $xml.CreateElement('server')
                $serverproperties = $xml.CreateElement('properties')

                $servername = $xml.CreateElement('name')
                $servername.set_InnerXML($Server)
    
                $serverdisplayname = $xml.CreateElement('displayName')
                $serverdisplayname.set_InnerXML($DisplayName)
    
                [void]$serverproperties.AppendChild($servername)
                [void]$serverproperties.AppendChild($serverdisplayname)

                [void]$ServerNode.AppendChild($serverproperties)

                $group = @($xml.RDCMan.file.group) | Where-Object -FilterScript {
                    $_.properties.name -eq $groupname
                } 
                [void]$group.AppendChild($ServerNode)
            }
            END
            {
                $xml.Save($FilePath)
            }
        }

    }
    Process
    {
        $RDGPath = "$PSScriptRoot\servers.rdg"
        New-RDCManFile -FilePath $RDGPath -Name Company
        New-RDCManGroup -FilePath $RDGPath -Name Servers
        
        $servers = @( Get-Content $FilePath)
        foreach ($s in $servers)
        {
            $name = $s + $AppendText
            New-RDCManServer -FilePath $RDGPath -DisplayName $name -Server $name -Group Servers
        }

    }
    End
    {
        Stop-log
    }

}

<#######</Body>#######>
<#######</Script>#######>