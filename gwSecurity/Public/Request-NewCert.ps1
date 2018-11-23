<#######<Script>#######>
<#######<Header>#######>
# Name: Request-NewCert
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Request-NewCert
{
    <#
.Synopsis
This script will request a new SSL cert for a server.
.Description
This script will request a new SSL cert for a server.
.Example
Request-NewCert
Places a completed request for SSL cert at \\some\path using server's hostname.
#>
    [Cmdletbinding()]
    Param()
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
        
    }
    Process
    {
        
        $Full = $env:computername.tolower() + '.' + $env:USERDNSDOMAIN.tolower()

        $ServerName = Read-Host "Script has detected the full name of the computer as $Full . Is this correct? Press (y) for Yes or (n) for No"
        If ($Servername -ne 'y')
        {
            $ServerName = Read-Host "Please enter the full fqdn. The script will parse accordingly"
        }
        Else
        {
            $ServerName = $Full
        }
        
        $Continue = Read-Host "You entered $ServerName , is this correct? Press (y) for Yes or (n) for No"
        If ($Continue -ne 'y')
        {
            $ServerName = Read-Host "Please enter the full fqdn. The script will parse accordingly"
        }
        Else
        {
            # Do nothing
        }
        $TrimmedName = $Servername.Substring(0, ($Servername.Length - 8))
        $TrimmedName = $TrimmedName + "_domain_com"

        $INFPath = "\\some\path\inf\" + $TrimmedName + ".inf"
        $CSRPath = "\\some\path\" + $TrimmedName + ".csr"

        $LoadBalanced = Read-Host "Is this server behind a load balancer? Press (y) for Yes or (n) for No"
        $SAN = Read-Host "Is this server part of a SAN? Press (y) for Yes or (n) for No"
        # Placing this here because of possible here-string issues
        $Signature = '$Windows NT$'

        If ($SAN -eq 'y')
        {
            $LBServer1 = Read-Host "Please enter the full fqdn of the access point in the cluster"
            $Continue = Read-Host "You entered $LBServer1 , is this correct? Press (y) for Yes or (n) for No"
            If ($Continue -eq 'y')
            {
                # Do nothing
            }
            Else
            {
                $LBServer1 = Read-Host "Please enter the full fqdn of the access point in the cluster"
            }
    
            $LBServer2 = Read-Host "Please enter the full fqdn of a node in the cluster"
            $Continue = Read-Host "You entered $LBServer2 , is this correct? Press (y) for Yes or (n) for No"
            If ($Continue -eq 'y')
            {
                # Do nothing
            }
            Else
            {
                $LBServer2 = Read-Host "Please enter the full fqdn of the access point in the cluster"
            }
    
            $INF =
            @"
;----------------- here.domain.com.inf -----------------
[Version]
Signature="$Signature"

[NewRequest]
;Change to your,country code, company name and common name
Subject = "C=US, S=SomeState, L=SomeCity, O=SomeOrg, OU=SomeOrg, CN="$ServerName"

KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1 ; this is for Server Authentication / Token Signing

[Extensions]
2.5.29.17 = "{text}"
_continue_ = "dns=$LBServer1&"
_continue_ = "dns=$LBServer2&"
;-----------------------------------------------
"@
            $INF | Out-File -Filepath $INFPath -Force
            # Now call certreq
            certreq.exe -new $INFPath $CSRPath

            Write-Output "Certificate Request has been generated"
        }
        Else
        {

            If ($LoadBalanced -eq 'y')
            { 
                Write-output "Since this computer is load balanced, you will need to create two requests"
                Write-output "One with the full fqdn"
                Write-output "One with the local DNS entry"
                Write-output "Rerun the script again using whichever one you didn't use this time."
                Stop-Script
            }
            Else
            {
                # Do nothing
            }
            $INF =
            @"
;----------------- here.domain.com.inf -----------------

[Version]
Signature="$Signature"

[NewRequest]
;Change to your,country code, company name and common name
Subject = "C=US, S=SomeState, L=SomeCity, O=SomeOrg, OU=SomeOrg, CN="$ServerName"

KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1 ; this is for Server Authentication / Token Signing
;-----------------------------------------------
"@
            $INF | Out-File -Filepath $INFPath -Force
            certreq.exe -new $INFPath $CSRPath
            Write-Output "Certificate Request has been generated"
        }
    }

    End 
    {
		# Copy the CSR from the remote file share locally in case we need it for something.        
		Copy-Item $CSRPath -Destination "C:\scripts\"
        Stop-log
    }
}

<#######</Body>#######>
<#######</Script>#######>