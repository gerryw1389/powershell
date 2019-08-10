<#######<Script>#######>
<#######<Header>#######>
# Name: Connect-LDAPS
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Connect-LDAPS
{
    <#
    .Synopsis
    Connects to an LDAPS server. Currenly ignores the cert (insecure) just because I was unable to connect any other way. 
    .Description
    Connects to an LDAPS server. Currenly ignores the cert (insecure) just because I was unable to connect any other way.
    .Example
    Connect-LDAPS -computername myserver.domain.com -Port 636 -Username 'cn=admin,ou=users,o=domain' -Password 'Pa$$word'
    Connects to an LDAPS server. Currenly ignores the cert (insecure) just because I was unable to connect any other way.
    .Notes
    2019-08-08: Initial script
    #>

    [Cmdletbinding()]
    
    Param
    (

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [String]$ComputerName,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [int]$Port = 636,
        
        [Parameter(Mandatory = $true, Position = 2)]
        [String]$UserName,
        
        [Parameter(Mandatory = $true, Position = 3)]
        [String]$Password
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
            ForEach-Object { $_.Matches } | 
            ForEach-Object { $_.Value } | 
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
            

            <#
# Get client cert
$cert = @( Get-ChildItem -Path 'Cert:\LocalMachine\Root\' )
foreach ($c in $cert)
{
    If ($c.Subject -match "CN=server.domain.com")
    { 
        $clientCert = $c
    }
    Else {}
}
[System.Security.Cryptography.X509Certificates.X509Certificate] $ClientAuthCert = $clientCert
#>
 
            #Load the assemblies 
            [System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.Protocols") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("System.Net") | Out-Null
            if (-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type)
            {
                add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
            }
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

            # Setup connection
            $dn = "$ComputerName" + ":" + "$Port" 
            $connection = New-Object System.DirectoryServices.Protocols.LdapConnection "$dn" 
            $connection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic 
            $credentials = new-object "System.Net.NetworkCredential" -ArgumentList $UserName, $Password 
            $connection.Credential = $credentials

            # set options
            $options = $connection.SessionOptions
            $options.SecureSocketLayer = $true 
            $options.ProtocolVersion = 3 
            # Write-Output 'SSL for encryption is enabled - SSL information:'
            # Write-Output "cipher strength: $($options.SslInformation.CipherStrength)"
            # Write-Output "exchange strength: $($options.SslInformation.ExchangeStrength)"
            # Write-Output "protocol: $($options.SslInformation.Protocol)"
            # Write-Output "hash strength: $($options.SslInformation.HashStrength)"
            # Write-Output "algorithm: $($options.SslInformation.AlgorithmIdentifier)" 
            $options.VerifyServerCertificate = { return $true } 

            # connect
            Try 
            { 
                $connection.Bind() 
                # Write-host 'connected'
            } 
            catch 
            { 
                Write-host $_.Exception.Message 
            }

            # Send a query
            [Timespan]$Timeout = (New-Object System.TimeSpan(0, 0, 120))
            #$BaseDN = ""
            #$attrlist = ""
            $scope = [System.DirectoryServices.Protocols.SearchScope]::OneLevel
            $Filter = "(objectClass=*)"

            $rq = new-object System.DirectoryServices.Protocols.SearchRequest
            $rq.Filter = $Filter
            $rq.Scope = $scope

            $rsp = $Connection.SendRequest($rq, $Timeout) -as [System.DirectoryServices.Protocols.SearchResponse]

            # see results
            # $rsp.entries

            If ($rsp.ResultCode.ToString() -eq 'Success')
            {
                Write-Output "connected successfully"
            }
            Else
            {
                Write-Output "failed to connect"
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