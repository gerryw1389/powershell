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
    .Example
    Add-ADUsersRandom -Password "#Tacos99!" -Fqdn "domain.net" -Ou "Ou=DomainUsers,Dc=domain,Dc=net" -NumberofUsers 3
    Creates 3 users in the "domain users" OU for domain.net. They will be enabled with the password of "#Tacos99!" 
    #>

    [Cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $True)][String]$Password,
        [Parameter(Mandatory = $True)][String]$Fqdn,
        [Parameter(Mandatory = $True)][String]$Ou,
        [Parameter(Mandatory = $True)][Int]$Numberofusers
    )

    Begin
    {
        $Pass = $Password | ConvertTo-SecureString -AsPlainText -Force

        # Load the required module(s) 
        Try
        {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'ActiveDirectory' was not found, stopping script"
            Exit 1
        }

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
            
            $Params = @{
                'Name'                  = $Together
                'Accountpassword'       = $Pass
                'Changepasswordatlogon' = $False
                'City'                  = $User.Results.Location.City
                'Postalcode'            = $User.Results.Location.PostCode
                'State'                 = $User.Results.Location.State
                'Country'               = "US"
                'Streetaddress'         = $User.Results.Location.Street
                'Givenname'             = $FirstName
                'Surname'               = $LastName
                'Displayname'           = "$FirstName $LastName"
                'Emailaddress'          = $Email
                'Enabled'               = $True
                'Userprincipalname'     = $Upn
                'Path'                  = $Ou
            }
            New-Aduser @Params
            
            Write-Output "User account created: $Together in $Ou"
        }
    }

    End
    {
    }

}   

<#######</Body>#######>
<#######</Script>#######>