<#######<Script>#######>
<#######<Header>#######>
# Name: Get-LocalAdminsRecursiveRemotely
<#######</Header>#######>
<#######<Body>#######>
Function Get-LocalAdminsRecursiveRemotely
{
    <#
.Synopsis
This creates a folder in the scripts directory that contains a separate CSV for each server you want to list the local admins for.
The CSV's contain all the members of each group that is a local admin on the server.
.Description
This creates a folder in the script's directory that contains a separate CSV for each server you want to list the local admins for.
The CSV's contain all the nested members of each group that is a local admin on the server.
You might want to then use 'Merge-CSVs' to combine and select unique, but that is broken into a different function.
This might be overkill if you just want to see nested groups. 
You might want to just try:
Import-Module Activedirectory; Get-ADGroupmember 'Domain Admins' -Recursive | Select-Object -Property Name
.Parameter FilePath
The source text file that contains the name of each server, one line per server.
.Parameter JustReport
Will output just a single file for each of the servers local admins all combined. 
If this is not specified, the script will recursively search for and export a CSV for each group.
.Example
Get-LocalAdminsRecursiveRemotely -FilePath "c:\scripts\servers.txt"
From "c:\scripts\servers.txt", the function will connect to each server in the file and create a separate CSV for each of its admins.
.Notes
Version history:
2018-11-10: version 1
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateScript( {(Test-Path $_) -and ((Get-Item $_).Extension -eq ".txt")})]
        [String]$FilePath,

        [Parameter(Mandatory = $false, Position = 1)]
        [Switch] $JustReport
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
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
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
        
        function Get-ADNestedGroupMembers
        { 
            <#  
.SYNOPSIS
Author: Piotr Lewandowski
Version: 1.01 (04.08.2015) - added displayname to the output, changed name to samaccountname in case of user objects.
.DESCRIPTION
Get nested group membership from a given group or a number of groups.
Function enumerates members of a given AD group recursively along with nesting level and parent group information. 
It also displays if each user account is enabled. 
When used with an -indent switch, it will display only names, but in a more user-friendly way (sort of a tree view) 
.EXAMPLE   
Get-ADNestedGroupMembers "MyGroup" | Export-CSV .\NedstedMembers.csv -NoTypeInformation
.EXAMPLE  
Get-ADGroup "MyGroup" | Get-ADNestedGroupMembers | ft -autosize
.EXAMPLE             
Get-ADNestedGroupMembers "MyGroup" -indent
#>

            param 
            ( 
                [Parameter(ValuefromPipeline = $true, mandatory = $true)][String]$GroupName, 
                [int]$nesting = -1, 
                [int]$circular = $null, 
                [switch]$indent 
            ) 
            
            function indent  
            { 
                Param($list) 
                foreach ($line in $list) 
                { 
                    $space = $null 
         
                    for ($i = 0; $i -lt $line.nesting; $i++) 
                    { 
                        $space += "    " 
                    } 
                    $line.name = "$space" + "$($line.name)"
                } 
                return $List 
            } 
     
            $modules = get-module | Select-Object -expand name
            if ($modules -contains "ActiveDirectory") 
            { 
                $table = $null 
                $nestedmembers = $null 
                $adgroupname = $null     
                $nesting++   
                $ADGroupname = get-adgroup $groupname -properties memberof, members 
                $memberof = $adgroupname | Select-Object -expand memberof 
                write-verbose "Checking group: $($adgroupname.name)" 
                if ($adgroupname) 
                {  
                    if ($circular) 
                    { 
                        $nestedMembers = Get-ADGroupMember -Identity $GroupName -recursive 
                        $circular = $null 
                    } 
                    else 
                    { 
                        $nestedMembers = Get-ADGroupMember -Identity $GroupName |  objectclass -Descending
                        if (!($nestedmembers))
                        {
                            $unknown = $ADGroupname | Select-Object -expand members
                            if ($unknown)
                            {
                                $nestedmembers = @()
                                foreach ($member in $unknown)
                                {
                                    $nestedmembers += get-adobject $member
                                }
                            }

                        }
                    } 
 
                    foreach ($nestedmember in $nestedmembers) 
                    { 
                        $Props = @{Type = $nestedmember.objectclass; Name = $nestedmember.name; DisplayName = ""; ParentGroup = $ADgroupname.name; Enabled = ""; Nesting = $nesting; DN = $nestedmember.distinguishedname; Comment = ""} 
                 
                        if ($nestedmember.objectclass -eq "user") 
                        { 
                            $nestedADMember = get-aduser $nestedmember -properties enabled, displayname 
                            $table = new-object psobject -property $props 
                            $table.enabled = $nestedadmember.enabled
                            $table.name = $nestedadmember.samaccountname
                            $table.displayname = $nestedadmember.displayname
                            if ($indent) 
                            { 
                                indent $table | Select-Object @{N = "Name"; E = {"$($_.name)  ($($_.displayname))"}}
                            } 
                            else 
                            { 
                                $table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment 
                            } 
                        } 
                        elseif ($nestedmember.objectclass -eq "group") 
                        {  
                            $table = new-object psobject -Property $props 
                     
                            if ($memberof -contains $nestedmember.distinguishedname) 
                            { 
                                $table.comment = "Circular membership" 
                                $circular = 1 
                            } 
                            if ($indent) 
                            { 
                                indent $table | Select-Object name, comment | ForEach-Object {
						
                                    if ($_.comment -ne "")
                                    {
                                        [console]::foregroundcolor = "red"
                                        write-output "$($_.name) (Circular Membership)"
                                        [console]::ResetColor()
                                    }
                                    else
                                    {
                                        [console]::foregroundcolor = "yellow"
                                        write-output "$($_.name)"
                                        [console]::ResetColor()
                                    }
                                }
                            }
                            else 
                            { 
                                $table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment 
                            } 
                            if ($indent) 
                            { 
                                Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular -indent 
                            } 
                            else  
                            { 
                                Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular 
                            } 
              	                  
                        } 
                        else 
                        { 
                    
                            if ($nestedmember)
                            {
                                $table = new-object psobject -property $props
                                if ($indent) 
                                { 
                                    indent $table | Select-Object name 
                                } 
                                else 
                                { 
                                    $table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment    
                                } 
                            }
                        } 
              
                    } 
                } 
            } 
            else 
            {
                Write-Warning "Active Directory module is not loaded"
            }        
        }
        Import-Module activedirectory
        Clear-Host
        [array]$Table = $null
        $Counter = 0
        $ComputerName = Get-Content -Path $FilePath
    }

    Process
    {
        Try
        {
            If ($JustReport)
            {
                $Date = Get-Date -Format yyyy-MM-dd
                $FolderName = $date.Tostring() + "-LocalAdminsReport"
                New-Item -Path "$PSScriptRoot\$FolderName" -ItemType Directory -Force | Out-Null
                foreach ($Computer in $ComputerName)
                {
                    try
                    {
                        $Name = $computer
                        $CountPC = @($ComputerName).count
                    }
                    catch
                    {
                        Write-Output "Cannot retrieve computer $Computer"
                        Add-Content -Path "$PSScriptRoot\$FolderName\ErrorLog.txt" "$Name"
                        continue
                    }
                    finally
                    {
                        $Counter ++
                    }
                    Write-Progress -Activity "Connecting PC $Counter/$CountPC " -Status "Querying ($Name)" -PercentComplete (($Counter / $CountPC) * 100)
                    try
                    {
                        $row = $null
                        $members = [ADSI]"WinNT://$Name/Administrators"
                        $members = @($members.psbase.Invoke("Members"))
                        $members | ForEach-Object {
                            $User = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
                            $row += $User
                            $row += " ; "
                        }
                        Write-Output "Computer ($Name) has been queried and exported." 
                        $obj = New-Object -TypeName PSObject -Property @{
                            "Name"        = $Name
                            "LocalAdmins" = $Row
                        }
                        $Table += $obj
                    }
                    catch
                    {
                        Write-Output "Error accessing ($Name)"
                        Add-Content -Path "$PSScriptRoot\$FolderName\ErrorLog.txt" "$Name"
                    }
                }
                try
                {
                    $Table  | Sort-Object Name | Select-Object Name, LocalAdmins |
                     Export-Csv -path "$PSScriptRoot\$FolderName\Report.csv" -Append -NoTypeInformation
                }
                catch
                {
                    Write-Warning $_
                }
            }
            Else
            {
                $ComputerName = Get-Content -Path $FilePath
                $Date = Get-Date -Format yyyy-MM-dd
                $FolderName = $date.Tostring() + "-LocalAdminsReport"
                New-Item -Path "$PSScriptRoot\$FolderName" -ItemType Directory -Force | Out-Null
                foreach ($Computer in $ComputerName)
                {
                    try
                    {
                        $Name = $computer
                        $CountPC = @($ComputerName).count
                    }
                    catch
                    {
                        Write-Output "Cannot retrieve computer $Computer"
                        Add-Content -Path "$PSScriptRoot\$FolderName\ErrorLog.txt" "$Name"
                        continue
                    }
                    finally
                    {
                        $Counter ++
                    }
                    Write-Progress -Activity "Connecting PC $Counter/$CountPC " -Status "Querying ($Name)" -PercentComplete (($Counter / $CountPC) * 100)
                    try
                    {
                        $row = $null
                        $members = [ADSI]"WinNT://$Name/Administrators"
                        $members = @($members.psbase.Invoke("Members"))
                        $members | ForEach-Object {
                            $User = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
                            Try
                            {
                                [string]$Csvpath = "$PSScriptRoot\$FolderName\$name" + "-" + $user + "-Members.csv"
                                Get-ADNestedGroupMembers $user | Export-CSV $Csvpath -NoTypeInformation
                            }
                            Catch
                            {
                                Write-Output "unable to expand local admin: $user"
                            }
                            $row += $User
                            $row += " ; "
                        }
                        Write-Output "Computer ($Name) has been queried and exported." 
                        $obj = New-Object -TypeName PSObject -Property @{
                            "Name"        = $Name
                            "LocalAdmins" = $Row
                        }
                        $Table += $obj
                    }
                    catch
                    {
                        Write-Output "Error accessing ($Name)"
                        Add-Content -Path "$PSScriptRoot\$FolderName\ErrorLog.txt" "$Name"
                    }
                }
                try
                {
                    $Table  | Sort-Object  Name | Select-Object Name, LocalAdmins |
                        Export-Csv -path "$PSScriptRoot\$FolderName\Report.csv" -Append -NoTypeInformation
                }
                catch
                {
                    Write-Warning $_
                }
            }
        }
        Catch
        {
            Write-Error $($_.Exception.Message)
        }
    }

    End
    {
        Stop-log
    }
}

<#######</Body>#######>
<#######</Script>#######>