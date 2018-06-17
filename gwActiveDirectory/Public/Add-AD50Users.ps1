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
    Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
    Main code usually starts around line 185ish.
    If -Verbose is not passed (Default) and logfile is not defined, don't show messages on the screen and don't transcript the session.
    If -Verbose is not passed (Default) and logfile is defined, enable verbose for them and transcript the session.
    If -Verbose is passed and logfile is defined, show messages on the screen and transcript the session.
    If -Verbose is passed and logfile is not defined, show messages on the screen, but don't transcript the session.
    2018-06-17: v1.1 Updated template.
    2017-09-08: v1.0 Initial script 
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
        <#######<Default Begin Block>#######>
        Function Write-ToString
        {
            <# 
        .Synopsis
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Description
        Function that takes an input object, converts it to text, and sends it to the screen, a logfile, or both depending on if logging is enabled.
        .Parameter InputObject
        This can be any PSObject that will be converted to string.
        .Parameter Color
        The color in which to display the string on the screen.
        Valid options are: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, 
        Red, White, and Yellow.
        .Example 
        Write-ToString "Hello Hello"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen and the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen in default text colors.
        .Example 
        Write-ToString "Hello Hello" -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow and to the logfile at the same time. 
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Example 
        Write-ToString (cmd /c "ipconfig /all") -Color "Yellow"
        If $Global:EnabledLogging is set to true, this will create an entry on the screen colored yellow that shows the computer's IP information.
        The same copy will be in the logfile. 
        The whole point of converting to strings is this works best with tables and such that usually distort in logfiles.
        If $Global:EnabledLogging is set to false, it will just show up on the screen colored yellow.
        .Notes
        2018-06-13: v1.0 Initial function
        #>
            Param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
                [PSObject]$InputObject,
                
                [Parameter(Mandatory = $False, Position = 1)]
                [Validateset("Black", "Blue", "Cyan", "Darkblue", "Darkcyan", "Darkgray", "Darkgreen", "Darkmagenta", "Darkred", `
                        "Darkyellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
                [String]$Color
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
        If ($($Logfile.Length) -gt 1)
        {
            $Global:EnabledLogging = $True 
            Set-Variable -Name Logfile -Value $Logfile -Scope Global
            $VerbosePreference = "Continue"
            Function Start-Log
            {
                <#
                .Synopsis
                Function to write the opening part of the logfile.
                .Description
                Function to write the opening part of the logfil.
                It creates the directory if it doesn't exists and then the log file automatically.
                It checks the size of the file if it already exists and clears it if it is over 10 MB.
                If it exists, it creates a header. This function is best placed in the "Begin" block of a script.
                .Notes
                NOTE: The function requires the Write-ToString function.
                2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                2017-10-19: v1.0 Initial function
                #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
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
                [Double]$Sizemax = 10485760
                $Size = (Get-Childitem $Logfile | Measure-Object -Property Length -Sum) 
                If ($($Size.Sum -ge $SizeMax))
                {
                    Get-Childitem $Logfile | Clear-Content
                    Write-ToString "Logfile has been cleared due to size"
                }
                Else
                {
                    Write-ToString "Logfile was less than 10 MB"   
                }
                # Start writing to logfile
                Start-Transcript -Path $Logfile -Append 
                Write-ToString "####################<Script>####################"
                Write-ToString "Script Started on $env:COMPUTERNAME"
            }
            Start-Log -Logfile $Logfile -Verbose

            Function Stop-Log
            {
                <# 
                    .Synopsis
                    Function to write the closing part of the logfile.
                    .Description
                    Function to write the closing part of the logfile.
                    This function is best placed in the "End" block of a script.
                    .Notes
                    NOTE: The function requires the Write-ToString function.
                    2018-06-13: v1.1 Brought back from previous helper.psm1 files.
                    2017-10-19: v1.0 Initial function 
                    #>
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                    [String]$Logfile
                )
                Write-ToString "Script Completed on $env:COMPUTERNAME"
                Write-ToString "####################</Script>####################"
                Stop-Transcript
            }
        }
        Else
        {
            $Global:EnabledLogging = $False
        }
        <#######</Default Begin Block>#######>
        
        $Pass = $Password | ConvertTo-SecureString -AsPlainText -Force

        # Load the required module(s) 
        Try
        {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        Catch
        {
            Write-ToString "Module 'ActiveDirectory' was not found, stopping script"
            Exit 1
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
            Write-ToString "AD User Created: $Together"
        }    
    }

    End
    {
        If ($Global:EnabledLogging)
        {
            Stop-Log -Logfile $Logfile
        }
        Else
        {
            $Date = $(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt")
            Write-Output "Function completed at $Date"
        }
    }
    
}   

# Add-AD50Users -Password "#Tacos99!" -Fqdn "domain.net" -Ou "Ou=DomainUsers,Dc=domain,Dc=net"

<#######</Body>#######>
<#######</Script>#######>