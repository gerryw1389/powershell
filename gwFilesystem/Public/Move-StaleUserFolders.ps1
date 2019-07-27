<#######<Script>#######>
<#######<Header>#######>
# Name: Move-StaleUserFolders
<#######</Header>#######>
<#######<Body>#######>
Function Move-StaleUserFolders
{
    <#
.Synopsis
This functions assumes you have a file server with $Path\SamAccountName\SomeFolder structure - for example e:\web\bob\my-docs
And you want to test if 'bob' is still active in AD.
If he is not, move the folder to $Destination but keeping the original file structure.
For example: e:\files\bob\my-docs will check if user 'bob' exists in AD and if he does, do nothing. 
If he doesn't, move e:\files\bob\my-docs to e:\tobedeleted\bob\my-docs.
.Description
This functions assumes you have a file server with $Path\SamAccountName\SomeFolder structure - for example e:\web\bob\my-docs
And you want to test if 'bob' is still active in AD.
If he is not, move the folder to $Destination but keeping the original file structure.
For example: e:\files\bob\my-docs will check if user 'bob' exists in AD and if he does, do nothing. 
If he doesn't, move e:\files\bob\my-docs to e:\tobedeleted\bob\my-docs.
NOTE: It would be fairly easy to tweak this to check if the account is enabled or not, but my organization deletes accounts after a set amount of time.
.Example
Move-StaleUserFolders -Path 'e:\web\test' -Destination 'e:\ToBeDeleted'
Will go through all folders under 'e:\web\test' and query each folder (assuming they match a SamAccountName), 
and move the folder to 'e:\tobedeleted' if the user account doesn't exist.
.Notes
2019-07-27: Modified
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [string]$Destination
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
        
    }

    Process
    {
        Try
        {
            # get a list of paths
            $folders = Get-Childitem -Path "$Path\*" | Select-Object -ExpandProperty fullname
            #$folders = Get-Childitem -Path "$Path\*\*" | Select-Object -ExpandProperty fullname

            #for each path, expand the path and check if the user exists in AD 
            Foreach ($folder in $folders)
            {
                # get the name from the folder
                $name = split-Path $folder -Leaf

                # Check if user exists without AD commandlets
                $user = (([adsisearcher]"(&(objectCategory=User)(samaccountname=$name))").findall()).properties
    
                If ($user.count -gt 0)
                {
                    Write-output "user exists in AD: $name"
                }
                Else
                {
                    Write-output "could not find user in ad: $name"
    
                    # breakdown the path splitting on '\', grab the last two parts. AN\aa10101 for example
                    $parts = $Folder -split '\\'
                    $thirdpath = $parts[-2]
                    $finalpath = $parts[-1]

                    # Ensure that the third path exists - for example $Destination\williamsg
                    If (Test-Path "$Destination\$thirdpath")
                    {
                        # Do nothing
                    }
                    Else
                    {
                        New-Item -itemtype Directory -Path "$Destination\$thirdpath" | Out-Null
                    }
                    # Now move the original folder to that folders path - Ex: move e:\web\wi\williamsg to e:\tobedeleted\wi\williamsg
                    Move-item $Folder -destination $Destination\$thirdpath\$finalpath -Force -Verbose
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