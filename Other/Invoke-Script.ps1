<#######<Script>#######>
<#######<Header>#######>
# Name: Invoke-Script
# Copyright: Gerry Williams (https://automationadmin.com)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Invoke-Script
{
    <#
.Synopsis
This function downloads a specific script from Github and runs it from any computer.
In this example I will download my "Set-Template" script for W10 images because I run it often (after every major version update).
What the script does is:
1. Creates a folder in your downloads called "temp"
2. Inside Downloads\Temp it creates two folders "private" and "public".
3. Inside the "private" folder, it will download my helpers.psm1 module that I use for logging and other functions.
4. Inside the "public" folder, it will download whatever script you specify. NOTE: You must change the script (line 44, 48, 52) if you want to use a different script!!
5. Lastly, it creates a "batch launcher file" so that you can run the script bypassing execution policy. It then calls the script so it will run.
#>

    Begin
    {
    }

    Process
    {
        [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"

        $Path = "$Env:UserProfile\Downloads" + "\Temp"
        If (Test-Path $Path)
        {
            Remove-Item -Path $Path -Recurse -Force
            New-Item -ItemType Directory -Path $Path -Force
        }
        Else
        {
            New-Item -ItemType Directory -Path $Path -Force
        }

        $PrivatePath = $Path + "\Private"
        New-Item -ItemType Directory -Path $PrivatePath -Force
        $Download = "$Path\Private\helpers.psm1"
        $URI = "https://raw.githubusercontent.com/gerryw1389/master/master/gwConfiguration/Private/helpers.psm1"
        $Response = Invoke-RestMethod -Method Get -Uri $URI
        $Response | Out-File $Download -Encoding ASCII

        $PublicPath = $Path + "\Public"
        New-Item -ItemType Directory -Path $PublicPath -Force
        $Download = "$Path\Public\set-template.ps1"
        $URI = "https://raw.githubusercontent.com/gerryw1389/master/master/gwConfiguration/Public/Set-Template.ps1"
        $Response = Invoke-RestMethod -Method Get -Uri $URI
        $Response | Out-File $Download -Encoding ASCII

        $Batch = "$PublicPath" + "\set-template.bat"
        $String = @'
@ECHO OFF
PowerShell.exe -NoProfile ^
-Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command ". "%~dpn0.ps1"; Set-Template "' -Verb RunAs}"
'@
        Write-Output $String | Out-File -LiteralPath $Batch -Encoding ASCII

        Start-Process $Batch -Verb Runas
    }

    End
    {
    }
}
<#######</Body>#######>
<#######</Script>#######>