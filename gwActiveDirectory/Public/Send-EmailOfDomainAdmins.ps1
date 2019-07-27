<#######<Script>#######>
<#######<Header>#######>
# Name: Send-EmailOfDomainAdmins
<#######</Header>#######>
<#######<Body>#######>
Function Send-EmailOfDomainAdmins
{
   <#
.Synopsis
This script queries AD and sends an email of the current domain admins.
.Description
This script queries AD and sends an email of the current domain admins.
.Example
Send-EmailOfDomainAdmins
This script queries AD and sends an email of the current domain admins.
#>

    [Cmdletbinding()]
    Param
    (
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
        
        function Get-ADNestedGroupMembers { 
            param ( 
            [Parameter(ValuefromPipeline=$true,mandatory=$true)][String] $GroupName, 
            [int] $nesting = -1, 
            [int]$circular = $null, 
            [switch]$indent 
            ) 
                function indent  
                { 
                Param($list) 
                    foreach($line in $list) 
                    { 
                    $space = $null 
                     
                        for ($i=0;$i -lt $line.nesting;$i++) 
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
                    $ADGroupname = get-adgroup $groupname -properties memberof,members 
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
                            $nestedMembers = Get-ADGroupMember -Identity $GroupName | Sort-Object objectclass -Descending
                            if (!($nestedmembers))
                            {
                                $unknown = $ADGroupname | Select-Object -expand members
                                if ($unknown)
                                {
                                    $nestedmembers=@()
                                    foreach ($member in $unknown)
                                    {
                                    $nestedmembers += get-adobject $member
                                    }
                                }
            
                            }
                        } 
             
                        foreach ($nestedmember in $nestedmembers) 
                        { 
                            $Props = @{Type=$nestedmember.objectclass;Name=$nestedmember.name;wWWHomePage=$nestedmember.wWWHomePage;DisplayName="";Decription=$ADgroupname.name;Description="";ParentGroup=$ADgroupname.name;Enabled="";Nesting=$nesting;Manager=$nestedmember.manager;Comment=""} 
                             
                            if ($nestedmember.objectclass -eq "user") 
                            { 
                                $nestedADMember = get-aduser $nestedmember -properties enabled,displayname,manager,Description,wWWHomePage  
                                $table = new-object psobject -property $props 
                                $table.enabled = $nestedadmember.enabled
                                $table.Manager = $nestedadmember.manager
                                $table.wWWHomePage = $nestedadmember.wWWHomePage
                                $table.name = $nestedadmember.samaccountname
                                $table.displayname = $nestedadmember.displayname
                                $table.Description = $nestedadmember.Description
                                if ($indent) 
                                { 
                                indent $table | Select-Object @{N="Name";E={"$($_.name)  ($($_.displayname))"}}
                                } 
                                else 
                                { 
                                $table | Select-Object name,displayname,parentgroup,enabled,@{Name = "Manager";Expression = {ForEach-Object{(Get-AdUser $_.Manager -Properties DisplayName).DisplayName}}},@{Name = "Owner";Expression = {ForEach-Object{(Get-AdUser $nestedadmember -Properties wWWHomePage).wWWHomePage}}},Description
                                } 
                            } 
                            elseif ($nestedmember.objectclass -eq "group") 
                            {  
                                $table = new-object psobject -Property $props 
                                 
                                if ($memberof -contains $nestedmember.distinguishedname) 
                                { 
                                    $table.comment ="Circular membership" 
                                    $circular = 1 
                                } 
                                if ($indent) 
                                { 
                                indent $table | Select-Object name,comment | ForEach-Object{
                                    
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
                                $table | Select-Object type,name,parentgroup,nesting,enabled,Manager,wWWHomePage,Description 
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
                                    $table | Select-Object type,name,displayname,parentgroup,nesting,enabled,Manager,wWWHomePage,Description
                                    } 
                                 }
                            } 
                          
                        } 
                     } 
                } 
                else {Write-Warning "Active Directory module is not loaded"}        
            }

            Import-Module ActiveDirectory
    }

    Process
    {
        Try
        {
            $datestring = (Get-Date).ToString("s").Replace(":","-")

            Get-ADNestedGroupMembers "Domain Admins" | Sort-Object manager,owner|  
            Export-CSV $env:temp\AdminGroup_$datestring.csv -NoTypeInformation 

            Start-Sleep -s 3

            $Params = @{
                'UseSSL'      = $True
                'From'        = 'group@domain.com'
                'To'          = 'user@domain.com'
                'Cc'          = @('user2@domain.com', 'user3@domain.com')
                'Subject'     = "Action Required - Domain Admin account review"
                'BodyAsHTML'  = $True
                'Body'        = "Domain Admin account review - See attached"
                'SmtpServer'  = "mail.domain.com"
                'Port'        = "25"
                'Attachments' = "$env:temp\AdminGroup_$datestring.csv"
            }
            Send-MailMessage @Params

            Remove-Item $env:temp\AdminGroup_$datestring.csv -Force

            <#
            # For older servers:
            $fromaddress = "group@domain.com" 
            $toaddress = "helpdesk@domain.com" 
            $ccaddress = "user1@domain.com" 
            $CCaddress = "user2@domain.com"
            $Subject = "Action Required - Domain Admin account review" 

            $attachment = "c:\scripts\AdminGroup_$datestring.csv" 
            $smtpserver = "mail.domain.com" 
            
            $message = new-object System.Net.Mail.MailMessage 
            $message.From = $fromaddress 
            $message.To.Add($toaddress) 
            $message.CC.Add($CCaddress) 
            $message.IsBodyHtml = $True 
            $message.body = "Please create a request and assign to the correct team to review that attached spreadsheet"
            $message.subject = $Subject 
            $attach = new-object Net.Mail.Attachment($attachment) 
            $message.Attachments.Add($attach) 

            $smtp = new-object Net.Mail.SmtpClient($smtpserver) 
            $smtp.Send($message) 
            #>
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