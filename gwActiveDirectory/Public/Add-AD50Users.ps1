<#######<Script>#######>
<#######<Header>#######>
# Name: Add-AD50Users
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Add-AD50Users
{

    <#
.Synopsis
Creates 50 pre-populated users in AD. 
.Description
Creates 50 pre-populated users in AD. Good for test lab user creation.
.Parameter Password
Madatory. Parameter stores a password as a string and then gets converted to a secure string in the Begin block.
.Parameter Fqdn
Madatory. Parameter that specifies the FQDN of the domain. Ex= "example.com".
.Parameter Ou
Madatory. Parameter that specifies the OU to create the users in. Ex = "OU=Users,DC=Domain,DC=com"
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Add-AD50Users -Password "#Tacos99!" -Fqdn "domain.net" -Ou "Ou=DomainUsers,Dc=domain,Dc=net"
Adds 50 users to the "DomainUsers" OU in domain.net with the password of "#Tacos99!" 
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
        [String]$Logfile = "$PSScriptRoot\..\Logs\Add-AD50Users.Log"
    )

    Begin
    {
        Import-Module Activedirectory

        $Pass = $Password | ConvertTo-SecureString -AsPlainText -Force

        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
        If ($($Logfile.Length) -gt 1)
        {
            $EnabledLogging = $True
        }
        Else
        {
            $EnabledLogging = $False
        }
    
        Filter Timestamp
        {
            "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $_"
        }

        If ($EnabledLogging)
        {
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
            $Sizemax = 10
            $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
            $Sizemb = "{0:N2}" -F ($Size.Sum / 1mb) + "Mb"
            If ($Sizemb -Ge $Sizemax)
            {
                Get-Childitem $Logfile | Clear-Content
                Write-Verbose "Logfile has been cleared due to size"
            }
            # Start writing to logfile
            Start-Transcript -Path $Logfile -Append 
            Write-Output "####################<Script>####################"
            Write-Output "Script Started on $env:COMPUTERNAME" | TimeStamp
        }
    }

    Process
    {   
        $1 = @{ First = "Todd"; Last = "Parker" }
        $2 = @{ First = "Shawn"; Last = "Allen" }
        $3 = @{ First = "Harold"; Last = "Thomas" }
        $4 = @{ First = "Patrick"; Last = "Evans" }
        $5 = @{ First = "Tammy"; Last = "Torres" }
        $6 = @{ First = "Kevin"; Last = "Richardson" }
        $7 = @{ First = "Ruth"; Last = "Henderson" }
        $8 = @{ First = "Michelle"; Last = "Gonzales" }
        $9 = @{ First = "Bonnie"; Last = "Martin" }
        $10 = @{ First = "Harry"; Last = "Hernandez" }
        $11 = @{ First = "James"; Last = "Price" }
        $12 = @{ First = "Philip"; Last = "Stewart" }
        $13 = @{ First = "Louis"; Last = "Morris" }
        $14 = @{ First = "Eric"; Last = "Bell" }
        $15 = @{ First = "Jesse"; Last = "Jones" }
        $16 = @{ First = "Matthew"; Last = "Alexander" }
        $17 = @{ First = "Andrew"; Last = "Ward" }
        $18 = @{ First = "Donna"; Last = "Reed" }
        $19 = @{ First = "Brandon"; Last = "Martinez" }
        $20 = @{ First = "Russell"; Last = "Green" }
        $21 = @{ First = "Patricia"; Last = "Wood" }
        $22 = @{ First = "Richard"; Last = "Cook" }
        $23 = @{ First = "Henry"; Last = "Howard" }
        $24 = @{ First = "Janice"; Last = "Wilson" }
        $25 = @{ First = "Cynthia"; Last = "Williams" }
        $26 = @{ First = "Denise"; Last = "Clark" }
        $27 = @{ First = "John"; Last = "Phillips" }
        $28 = @{ First = "Willie"; Last = "Lopez" }
        $29 = @{ First = "Janet"; Last = "Edwards" }
        $30 = @{ First = "Ernest"; Last = "Barnes" }
        $31 = @{ First = "Dennis"; Last = "Young" }
        $32 = @{ First = "Sandra"; Last = "Patterson" }
        $33 = @{ First = "Carolyn"; Last = "Gray" }
        $34 = @{ First = "Elizabeth"; Last = "Cox" }
        $35 = @{ First = "Paul"; Last = "Johnson" }
        $36 = @{ First = "Randy"; Last = "Flores" }
        $37 = @{ First = "Julia"; Last = "Lee" }
        $38 = @{ First = "Lawrence"; Last = "Campbell" }
        $39 = @{ First = "Timothy"; Last = "Lewis" }
        $40 = @{ First = "Teresa"; Last = "Cooper" }
        $41 = @{ First = "Alice"; Last = "Taylor" }
        $42 = @{ First = "Douglas"; Last = "Jenkins" }
        $43 = @{ First = "Mildred"; Last = "Powell" }
        $44 = @{ First = "Mark"; Last = "Kelly" }
        $45 = @{ First = "Louise"; Last = "Watson" }
        $46 = @{ First = "Stephen"; Last = "Nelson" }
        $47 = @{ First = "Evelyn"; Last = "James" }
        $48 = @{ First = "Edward"; Last = "Rogers" }
        $49 = @{ First = "Shirley"; Last = "Bailey" }
        $50 = @{ First = "Maria"; Last = "Baker" }

        $Array = @($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25,
            $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50)

        Foreach ($Number In $Array)
        {
            $FirstName = $Number.First.Tostring()
            $LastName = $Number.Last.Tostring()
            $Together = ($FirstName + "." + $LastName)  
            $Upn = $Together + "@" + $Fqdn
            New-Aduser -Name $Together `
                -Accountpassword $Pass `
                -Changepasswordatlogon $False `
                -Givenname $FirstName `
                -Surname $LastName `
                -Displayname "$FirstName $LastName" `
                -Emailaddress $Upn `
                -Enabled $True `
                -Userprincipalname $Upn `
                -Path $Ou
            Write-Output "AD User Created: $Together" | TimeStamp
        }    
    }

    End
    {
        If ($EnableLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }
    
}   

# Add-AD50Users -Password "#Tacos99!" -Fqdn "domain.net" -Ou "Ou=DomainUsers,Dc=domain,Dc=net"

<#######</Body>#######>
<#######</Script>#######>