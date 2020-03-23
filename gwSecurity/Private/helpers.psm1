<#######<Module>#######>
<#######<Header>#######>
# Name: Helpers
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
# This file contains helper functions to be used by public functions      
<#######<Body>#######>

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

Function Set-RegEntry
{
    <#
        .Synopsis
        Writes a registry entry. Very similar to New-ItemTypeProperty except it always uses force and will create the path to the entry automatically.
        .Description
        Writes a registry entry. Very similar to New-ItemTypeProperty except it always uses force and will create the path to the entry automatically.
        .Parameter Path
        This is the path to a key.
        .Parameter Name
        This is the name of the entry.
        .Parameter Value
        This is the value of the entry.
        .Parameter PropertyType
        This is the type of entry the function is to write. Default is "Dword", but also accepts all the others, including Binary.
        Note on Binary:
        You will need to export the key you are about to change first (from a machine that has it how you want it) and then copy and paste the results into the $Value variable.
        For example, if I want OneDrive to not run on startup I would export the keys from [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run]
        on a machine that I already have OneDrive disabled on startup and then copy the $Value as "03,00,00,00,cd,9a,36,38,64,0b,d2,01". I would then place:
        $SetRegParams = @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
            Name = "OneDrive"
            Value = "03,00,00,00,cd,9a,36,38,64,0b,d2,01"
            PropertyType = "Binary"c
        }
        Set-Regentry @SetRegParams
        .Example
        Set-RegEntry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ShowSyncProviderNotifications" -Value "0"
        Tests if that value exists at that path, and if not, creates it.
    #>
    
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]$Path,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [String]$Name,
    
        [Parameter(Position = 2, Mandatory = $True)]
        [String]$Value,
 
        [Parameter(Position = 3, Mandatory = $False)]
        [ValidateSet('String', 'Expandstring', 'Binary', 'DWord', 'MultiString', 'Qword', 'Unknown')]
        [String]$PropertyType = "Dword"
 
    )
    
    Begin
    {
        If (!(Test-Path HKCR:))
        {
            New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
        }
        # Inherit higher scope verbose preference
        # This will hide output if verbose is not passed in another function and will show it it if it is!
        # Please see: https://powershell.org/2014/01/13/getting-your-script-module-functions-to-inherit-preference-variables-from-the-caller/
        If (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }  
    }
    Process
    {
        If ($PropertyType -eq "Binary")
        {
            # Try to get the regentry's current value. If it fails to retrieve it (either wrong value or doesn't exist), just create it. 
            Try
            {
                $CurrentValue = ((Get-Item -Path $Path -ErrorAction Stop ).GetValue($Name))
            }
            Catch
            {
                $CurrentValue = ''
            }
            $CurrentRegValue = Out-String -InputObject $CurrentValue
            $RegValue = Out-String -InputObject $Value
            If ($CurrentRegValue -eq $RegValue)
            {
                Write-Verbose "Key already exists: $Path\$Name with value: $Value"
            }
            Else
            {
                If (!(Test-Path $Path))
                {
                    New-Item -Path $Path -Force | Out-Null
                }
                $Hex = $Value.Split(',') | ForEach-Object -Process { "0x$_" }
                New-ItemProperty -Path $Path -Name $Name -Value ([byte[]]$Hex) -PropertyType $PropertyType -Force | Out-Null
                Write-Verbose "Added key: $Path\$Name to value: $Value"
            }
        }
        Else
        {
            Try
            {
                $CurrentValue = ((Get-Item -Path $Path -ErrorAction Stop ).GetValue($Name))
            }
            Catch
            {
                $CurrentValue = ''
            }
            $CurrentRegValue = Out-String -InputObject $CurrentValue
            $RegValue = Out-String -InputObject $Value
            If ($CurrentRegValue -eq $RegValue)
            {
                Write-Verbose "Key already exists: $Path\$Name with value: $Value"
            }
            Else
            {
                If (!(Test-Path $Path))
                {
                    New-Item -Path $Path -Force | Out-Null
                }
                New-Itemproperty -Path $Path -Name $Name -Value $Value -Propertytype $PropertyType -Force | Out-Null
                Write-Verbose "Added key: $Path\$Name to value: $Value"

            }
        }
    }
    End
    {
    
    }
}
New-Alias -Name "SetReg" -Value Set-Regentry

Export-ModuleMember -Function * -Alias *

<#######</Body>#######>
<#######</Module>#######>