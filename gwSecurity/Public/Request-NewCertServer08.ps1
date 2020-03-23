<#######<Script>#######>
<#######<Header>#######>
# Name: Request-NewCert
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Request-NewCertServer08
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

    $INFPath = "\\some\path\" + $TrimmedName + ".inf"
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
            cmd /c "pause"
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

    Copy-Item $CSRPath -Destination "C:\Scripts\"
}

<#######</Body>#######>
<#######</Script>#######>