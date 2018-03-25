<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-Password
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Invoke-Password
{
    <#
.Synopsis
Generates a password and and sends it to the logfile, clipboard, and console.
.Description
Generates a password and and sends it to the logfile, clipboard, and console.
.Parameter Length
Mandatory parameter that defines the number of characters in the password.
.Parameter NoLower
Optional switch to declare that the password doesn't include lower characters.
.Parameter NoUpper
Optional switch to declare that the password doesn't include upper characters.
.Parameter NoNumber
Optional switch to declare that the password doesn't include numbers.
.Parameter NoSymbol
Optional switch to declare that the password doesn't include special characters.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Invoke-Password -Length 12
Generates a 12 character password and sends it to the logfile, clipboard, and console.
.Example
Invoke-Password -Length 10 -NoSymbols -Nolower
Generates a 10 character password with no symbols or lower letters and sends it to the logfile, clipboard, and console.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>  
    [Cmdletbinding()]

    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [Int]$Length = 12,
        
        [Switch]$Nolower,
        
        [Switch]$Noupper,
        
        [Switch]$Nonumber,
        
        [Switch]$Nosymbol,
        
        [String]$Logfile = "$PSScriptRoot\..\Logs\Invoke-Password.Log"
    )

    Begin
    {
        Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
        Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
    }
    
    Process
    {   
       Try
        {
            $Possible_Chars = '';
            If (!$Nolower)
            {
                $Possible_Chars += 'abcdefghijklmnopqrstuvwxyz'
            }
            If (!$Noupper)
            {
                $Possible_Chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            }
            If (!$Nonumber)
            {
                $Possible_Chars += '1234567890'
            }
            If (!$Nosymbol)
            {
                $Possible_Chars += '!@#$%^&*()<>'
            }
            If ($Possible_Chars.Length -Le 0)
            {
                Write-Warning ('Unable To Generate A Password Without Any Valid Characters.')
                Return $Null;
            }
    
            If ($Possible_Chars.Length -Gt 65535)
            {
                Write-Output (
                    'Charset "{0}" With Length Of {1} Detected - ' + 
                    'This Function Will Only Select From The First 65535 Possibilities.' -F 
                    $Possible_Chars,
                    $Possible_Chars.Length
                )
            }
    
            $Rng = [System.Security.Cryptography.Randomnumbergenerator]::Create();
            $Randbyte = New-Object Byte[] 2;
            [String]$Password = '';
    
            For ($I = 0; $I -Lt $Length; $I++)
            {
                $Rng.Getbytes($Randbyte);
                $Roll = [System.Bitconverter]::Touint16($Randbyte, 0) % $Possible_Chars.Length;
                $Password += $Possible_Chars[$Roll]
            }
    
            Log $Password 
            $Password | clip
        }
        Catch
        {
            Log $($_.Exception.Message) -Error -ExitGracefully
        }
             
    }

    End
    {
        Stop-Log  
    }

}   

# Invoke-Password -Length 12

<#######</Body>#######>
<#######</Script>#######>