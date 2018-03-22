<#
.Synopsis
   Creates a local user account in the Targeted computername
.DESCRIPTION
   Creates a local user account in the Targeted computername
.EXAMPLE
   NEW-Localuser -Name TestUser1 -Computername RemotePC1 -Password 'password123' -Description 'A new User'
#>
function New-LocalUser
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$Name,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$Env:computername",


        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [ValidateScript( {$_.GetType().Name -eq 'SecureString'})]
        [array][system.security.securestring]$Password,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 3)]
        [string[]]$Description = ' '

    )

    Begin
    {
    }
    Process
    {
        $cred = New-Object -TypeName System.management.automation.pscredential -ArgumentList "null", $Password[0]
        $Plaintextpassword = $cred.GetNetworkCredential().password
        $computer = [ADSI]"WinNT://$($ComputerName[0]),computer"
        $user = $computer.Create("User", "$($Name[0])")
        $user.setpassword("$PlainTextPassword")
        $user.put("Description", $($Description[0]))    
        $user.SetInfo()    
    }
    End
    {
    }
}
<#
.Synopsis
   Creates a local group in the Targeted computername
.DESCRIPTION
   Creates a local group in the Targeted computername
.EXAMPLE
   NEW-Localgroup -name TestUser1 -Computername RemotePC1 -Description 'A new group'
#>
function New-LocalGroup
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$name,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$Env:computername",


        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string[]]$Description

    )

    Begin
    {
    }
    Process
    {
        $computer = [ADSI]"WinNT://$($ComputerName[0]),computer"
        $group = $computer.Create("Group", $name[0])
        $group.SetInfo()    
        $group.description = $Description[0]
        $group.SetInfo()    
    }
    End
    {
    }
}
<#
.Synopsis
   Gets a list of local users in the Targeted computername
.DESCRIPTION
   Gets a list of local users in the Targeted computername
.EXAMPLE
   Get a list of all user accounts on computer remotepc1

   Get-Localuser -computername remotepc1

.EXAMPLE
    Get a local user called 'john' from the localhost

    Get-localuser -name john

#>
function Get-LocalUser
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$name,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$Env:computername"

    )

    Begin
    {
    }
    Process
    {
        if ($name) 
        { 
            $user = [adsi]"WinNT://$($ComputerName[0])/$($name[0]),user" 
            If ($User.Name -eq $NULL) 
            { 
                $user
            }
        }    
        else 
        {
            $computer = [ADSI]"WinNT://$($ComputerName[0]),computer"
            $user = $computer.psbase.Children | where { $_.psbase.schemaclassname -match 'user' }
        }
        $user | Select-Object -property `
        @{Name = 'Name'; Expression = { $_.name }}, `
        @{Name = 'Fullname'; Expression = { $_.Fullname }}, `
        @{Name = 'Description'; Expression = { $_.Description }}, `
        @{Name = 'AutoUnlockInterval'; Expression = { $_.AutoUnlockInterval }}, `
        @{Name = 'BadPasswordAttempts'; Expression = { $_.BadPasswordAttempts }}, `
        @{Name = 'HomeDirDrive'; Expression = { $_.HomeDirDrive }}, `
        @{Name = 'HomeDirectory'; Expression = { $_.HomeDirectory }}, `
        @{Name = 'LastLogin'; Expression = { $_.LastLogin }}, `
        @{Name = 'LockoutObservationInterval'; Expression = { $_.LockoutObservationInterval }}, `
        @{Name = 'LoginHours'; Expression = { $_.LoginHours }}, `
        @{Name = 'LoginScript'; Expression = { $_.LoginScript }}, `
        @{Name = 'MaxBadPasswordsAllowed'; Expression = { $_.MaxBadPasswordsAllowed }}, `
        @{Name = 'MaxPasswordAge'; Expression = { $_.MaxPasswordAge }}, `
        @{Name = 'MaxStorage'; Expression = { $_.MaxStorage }}, `
        @{Name = 'MinPasswordAge'; Expression = { $_.MinPasswordAge }}, `
        @{Name = 'MinPasswordLength'; Expression = { $_.MinPasswordLength }}, `
        @{Name = 'objectSid'; Expression = { $_.objectSid }}, `
        @{Name = 'Parameters'; Expression = { $_.Parameters }}, `
        @{Name = 'PasswordAge'; Expression = { $_.PasswordAge }}, `
        @{Name = 'PasswordExpired'; Expression = { $_.PasswordExpired }}, `
        @{Name = 'PasswordHistoryLength'; Expression = { $_.PasswordHistoryLength }}, `
        @{Name = 'PrimaryGroupID'; Expression = { $_.PrimaryGroupID }}, `
        @{Name = 'Profile'; Expression = { $_.Profile }}, `
        @{Name = 'UserFlags'; Expression = { $_.UserFlags }}
      
    }
    End
    {
    }
}
<#
.Synopsis
   Gets a list of local groups in the Targeted computername
.DESCRIPTION
   Gets a list of local groups in the Targeted computername
.EXAMPLE
   Get-Localuser -computername remotepc1
#>
function Get-LocalGroup
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$name,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$Env:computername"

    )

    Begin
    {
    }
    Process
    {
        if ($name) 
        { 
            $group = [adsi]"WinNT://$($ComputerName[0])/$($name[0]),group" 
            If ($group.Name -eq $NULL) 
            { 
                $group
            }
        }    
        else 
        {
            $computer = [ADSI]"WinNT://$($ComputerName[0]),computer"
            $Group = $computer.psbase.Children | where { $_.psbase.schemaclassname -match 'group' }
        }
        $Group | Select-Object -property `
        @{Name = 'Name'; Expression = { $_.name }}, `
        @{Name = 'Description'; Expression = { $_.Description }}, `
        @{Name = 'objectSid'; Expression = { $_.objectSid }}
    }
    End
    {
    }
}
<#
.Synopsis
   Remove a local group in the Targeted computername
.DESCRIPTION
   Remove a local group in the Targeted computername
.EXAMPLE
   Remove-Localgroup -name TestGroup -Computername RemotePC1
#>
function Remove-LocalGroup
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$name,
        
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$Env:computername"
                
    )

    Begin
    {
    }
    Process
    {
        if ($PSCmdlet.Shouldprocess("$name Removed from $($computername[0])") )
        {
            $computer = [ADSI]"WinNT://$($ComputerName[0]),computer"
            $computer.delete("group", $name[0])
        }
    }
    End
    {
    }
}
<#
.Synopsis
   Remove a local user in the Targeted computername
.DESCRIPTION
   Creates a local user in the Targeted computername
.EXAMPLE
   Remove-Localuser -name TestUser1 -Computername RemotePC1
#>
function Remove-LocalUser
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$Name,
        
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$Env:computername"
                
    )

    Begin
    {
    }
    Process
    {
        if ($PSCmdlet.Shouldprocess("$Name Removed from $computername") )
        {
            $computer = [ADSI]"WinNT://$($ComputerName[0]),computer"
            $computer.delete("user", $name[0])
        }
    }
    End
    {
    }
}
<#
.Synopsis
   Rename a local user in the Targeted computername
.DESCRIPTION
   Rename a local user in the Targeted computername
.EXAMPLE
   Rename-localuser -name TestUser1 -newname TestUserName -computername remotepc1
#>
function Rename-LocalUser
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$Name,
        
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$NewName,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string[]]$Computername = "$ENV:Computername"

        
    )

    Begin
    {
    }
    Process
    {
        $user = [ADSI]"WinNT://$($computername[0])/$($name[0]),user" 
        $user.psbase.rename($newname[0])
    
    }
    End
    {
    }
}
<#
.Synopsis
   Rename a local group in the Targeted computername
.DESCRIPTION
   Rename a local group in the Targeted computername
.EXAMPLE
   Rename-localgroup -name TestGroup -newname TestGroupName -computername remotepc1
#>
function Rename-LocalGroup
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$Name,
        
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$NewName,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string[]]$Computername = "$ENV:Computername"

        
    )

    Begin
    {
    }
    Process
    {
        $group = [ADSI]"WinNT://$($computername[0])/$($name[0]),group" 
        $group.psbase.rename($newname[0])
    
    }
    End
    {
    }
}
function Disable-LocalUser
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$Name,
        
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$ENV:Computername"

        
    )

    Begin
    {
    }
    Process
    {
        if ($PSCmdlet.Shouldprocess("$Name Disabled on $computername") )
        {
            $user = [ADSI]"WinNT://$($computername[0])/$($Name[0]),user" 
            $status = $user.userflags
    
            $Disable = [int]$Status.tostring() -bxor 512 -bor 2
            $user.userflags = $disable
            $user.setinfo()
        }
    }
    End
    {
    }
}
<#
.Synopsis
   Enable a local user in the Targeted computername
.DESCRIPTION
   Enable a local user in the Targeted computername
.EXAMPLE
   Enable-localuser -name TestUser1 -computername remotepc1
#>
function Enable-LocalUser
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$Name,
        
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$ENV:Computername"

        
    )

    Begin
    {
    }
    Process
    {
        $user = [ADSI]"WinNT://$($computername[0])/$($Name[0]),user" 
        $status = $user.userflags
    
        $Enable = [int]$Status.tostring() -bxor 2 -bor 512
        $user.userflags = $enable
        $user.setinfo()
    }
    End
    {
    }
}
<#
.Synopsis
   Add a local user to a local group in the Targeted computername
.DESCRIPTION
   Add a local user to a local group in the Targeted computername
.EXAMPLE
   Add-LocalGroupMember -name TestUser1 -groupname Testgroup -computername remotepc1
#>
function Add-LocalGroupMember
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$GroupName,
        
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$Env:computername",

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string[]]$name

        
    )

    Begin
    {
    }
    Process
    {
        $group = [ADSI]"WinNT://$($computername[0])/$($groupname[0]),group" 
        $group.add("WinNT://$($Name[0]),user")
    
    }
    End
    {
    }
}
<#
.Synopsis
   Remove a local user to a local group in the Targeted computername
.DESCRIPTION
   Remove a local user to a local group in the Targeted computername
.EXAMPLE
   Remove-LocalGroupMember -name TestUser1 -groupname Testgroup -computername remotepc1
#>
function Remove-LocalGroupMember
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$GroupName,
        
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$Env:computername",

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string[]]$name

        
    )

    Begin
    {
    }
    Process
    {
        if ($PSCmdlet.Shouldprocess("$($Name[0]) Removed from $($groupname[0]) on $computername") )
        {
            $group = [ADSI]"WinNT://$($computername[0])/$($groupname[0]),group" 
            $group.remove("WinNT://$($Name[0]),user")
        }
    }
    End
    {
    }
}
<#
.Synopsis
   Show members of a local group in the Targeted computername
.DESCRIPTION
Show members of a local group in the Targeted computername
.EXAMPLE
   Get-LocalGroupMember -name TestGroup -computername remotepc1
#>
function Get-LocalGroupMember
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$Name,
        
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string[]]$Computername = "$ENV:Computername"

        
    )

    Begin
    {
    }
    Process
    {
        # Code for decoding group membership provided
        # Courtesy of Francois-Xaver Cat 
        # Windows PowerShell MVP
        # Thanks Dude!
        $group = [ADSI]"WinNT://$($computername[0])/$($Name[0]),group" 
        $member = @($group.psbase.invoke("Members"))
        $member | ForEach-Object {([ADSI]$_).InvokeGet("Name")}
        
    }
    End
    {
    }
}
<#
.Synopsis
   Updates a local user account in the Targeted computername
.DESCRIPTION
   Updates a local user account in the Targeted computername
.EXAMPLE
   Set-Localuser -Name TestUser1 -Computername RemotePC1 -Password 'password123' -Description 'A new User'
#>
function Set-LocalUser
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$Name,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string[]]$Computername = "$Env:computername",

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [ValidateScript( {$_.GetType().Name -eq 'SecureString'})]
        [array][system.security.securestring]$Password,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 3)]
        [string[]]$Description,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 4)]
        [string[]]$Fullname

    )

    Begin
    {
    }
    Process
    {
        $user = [ADSI]"WinNT://$($ComputerName[0])/$($Name[0]),user"
        if ($Description) 
        { 
            $User.Description = $Description 
        }
        if ($Fullname) 
        { 
            $User.Fullname = $Fullname 
        }
        if ($Password) 
        { 
            $cred = New-Object -TypeName System.management.automation.pscredential -ArgumentList "null", $Password[0]
            $Plaintextpassword = $cred.GetNetworkCredential().password
            $user.setpassword($PlainTextPassword) 
        }
        $User.setinfo()

    }
    End
    {
    }
}

Export-ModuleMember -Function *
