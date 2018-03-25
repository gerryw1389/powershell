<#######<Script>#######>
<#######<Header>#######>
# Name: Add-ADUsersRandom
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Add-ADUsersRandom
{
    <#
.Synopsis
Creates a number of AD users retrieved from https://randomuser.me/api/
.Description
Creates a number of AD users retrieved from https://randomuser.me/api/ . Good for test lab user creation.
.Parameter Password
Madatory. Parameter stores a password as a string and then gets converted to a secure string in the Begin block.
.Parameter Fqdn
Madatory. Parameter that specifies the FQDN of the domain. Ex= "example.com".
.Parameter Ou
Madatory. Parameter that specifies the OU to create the users in. Ex = "OU=Users,DC=Domain,DC=com"
.Parameter Numberofusers
Madatory. Parameter that specifies the number of users to create.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Add-ADUsersRandom -Password "#Tacos99!" -Fqdn "domain.net" -Ou "Ou=DomainUsers,Dc=domain,Dc=net" -NumberofUsers 3
Creates 3 users in the "domain users" OU for domain.net. They will be enabled with the password of "#Tacos99!" 
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.   
  
#>

    [Cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $True)][String]$Password,
        [Parameter(Mandatory = $True)][String]$Fqdn,
        [Parameter(Mandatory = $True)][String]$Ou,
        [Int]$Numberofusers, 
        [String]$Logfile = "$PSScriptRoot\..\Logs\Add-ADUsersRandom.Log"
    )

    Begin
    {
                
        Import-Module Activedirectory
        
        $Pass = $Password | ConvertTo-SecureString -AsPlainText -Force
    
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        $PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log

    }
    
    Process
    {   
        For ($I = 0; $I -Lt $Numberofusers; $I++)
        {
            $Data = Invoke-Webrequest -Uri "https://randomuser.me/api/"
            $User = $Data.Content | Convertfrom-Json
            $Email = $User.Results.Email
            $FirstName = $User.Results.Name.First
            $LastName = $User.Results.Name.Last
            $Together = ($FirstName + "." + $LastName)  
            $Upn = $Together + "@" + $Fqdn
            New-Aduser -Name $Together `
                -Accountpassword $Pass `
                -Changepasswordatlogon $False `
                -Postalcode $User.Results.Location.PostCode `
                -Country "US" `
                -State $User.Results.Location.State `
                -City $User.Results.Location.City `
                -Streetaddress $User.Results.Location.Street `
                -Givenname $FirstName `
                -Surname $LastName `
                -Displayname "$FirstName $LastName" `
                -Emailaddress $Email `
                -Enabled $True `
                -Userprincipalname $Upn `
                -Path $Ou
            Log "User account created: $Together in $Ou" 
        }
    }

    End
    {
        Stop-Log  
    }

}   

# Add-ADUsersRandom -Password "#Tacos99!" -Fqdn "domain.net" -Ou "Ou=DomainUsers,Dc=domain,Dc=net" -NumberofUsers 3

<#######</Body>#######>
<#######</Script>#######>