<#######<Script>#######>
<#######<Header>#######>
# Name: Set-OutlookAutodiscover
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>
Function Set-OutlookAutodiscover
{
    <#
.Synopsis
Configures autodiscover keys for MS Outlook so adding accounts takes 5 seconds instead of 5 minutes.
.Description
Configures autodiscover keys for MS Outlook so adding accounts takes 5 seconds instead of 5 minutes.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
.Example
Set-OutlookAutodiscover
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
#>
    [Cmdletbinding()]
    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Set-OutlookAutodiscover.log"
    )


    Begin
    {
        <#######<Default Begin Block>#######>
        # Set logging globally if it has any value in the parameter so helper functions can access it.
        If ($($Logfile.Length) -gt 1)
        {
            $Global:EnabledLogging = $True
            New-Variable -Scope Global -Name Logfile -Value $Logfile
        }
        Else
        {
            $Global:EnabledLogging = $False
        }
        
        # If logging is enabled, create functions to start the log and stop the log.
        If ($Global:EnabledLogging)
        {
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
                    [Parameter(Mandatory = $True)]
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
                    Write-Verbose "Logfile has been cleared due to size"
                }
                Else
                {
                    Write-Verbose "Logfile was less than 10 MB"   
                }
                # Start writing to logfile
                Start-Transcript -Path $Logfile -Append 
                Write-ToString "####################<Script>####################"
                Write-ToString "Script Started on $env:COMPUTERNAME"
            }
            Start-Log

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
                    [Parameter(Mandatory = $True)]
                    [String]$Logfile
                )
                Write-ToString "Script Completed on $env:COMPUTERNAME"
                Write-ToString "####################</Script>####################"
                Stop-Transcript
            }
        }

        # Declare a Write-ToString function that doesn't depend if logging is enabled or not.
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
                [String]$Color,

                [Parameter(Mandatory = $False, Position = 2)]
                [String]$Logfile
            )
            
            $ConvertToString = Out-String -InputObject $InputObject -Width 100
            If ($Global:EnabledLogging)
            {
                # If logging is enabled and a color is defined, send to screen and logfile.
                If ($($Color.Length -gt 0))
                {
                    $previousForegroundColor = $Host.PrivateData.VerboseForegroundColor
                    $Host.PrivateData.VerboseForegroundColor = $Color
                    Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                    Write-Output "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString" | Out-File -Encoding ASCII -FilePath $Logfile -Append
                    $Host.PrivateData.VerboseForegroundColor = $previousForegroundColor
                }
                # If not, still send to logfile, but use default colors.
                Else
                {
                    Write-Verbose -Message "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString"
                    Write-Output "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"): $ConvertToString" | Out-File -Encoding ASCII -FilePath $Logfile -Append
                }
            }
            # If logging isn't enabled, just send the string to the screen.
            Else
            {
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
        }
        <#######</Default Begin Block>#######>

        # Load the required module(s) 
        Try
        {
            Import-Module "$Psscriptroot\..\Private\helpers.psm1" -ErrorAction Stop
        }
        Catch
        {
            Write-ToString "Module 'Helpers' was not found, stopping script"
            Exit 1
        }
        
        Function Set-2013Old
        {
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\AutoDiscover"
            $Name = "ExcludeHttpsRootDomain"
            $value = "1"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            $registryPath = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\AutoDiscover"
            $Name = "ExcludeHttpsAutoDiscoverDomain"
            $value = "1"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            # Allow adding up to 14 accounts, can adjust to 99 I believe
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Exchange"
            $Name = "MaxNumExchange"
            $value = "19"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            $registryPath = "HKCU:\Software\Policies\Microsoft\Exchange"
            $Name = "MaxNumExchange"
            $value = "19"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
        }

        Function Set-2016Old
        {
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover"
            $Name = "ExcludeHttpsRootDomain"
            $value = "1"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null


            $registryPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover"
            $Name = "ExcludeHttpsAutoDiscoverDomain"
            $value = "1"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            # Allow adding up to 14 accounts, can adjust to 99 I believe
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Exchange"
            $Name = "MaxNumExchange"
            $value = "19"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

            $registryPath = "HKCU:\Software\Policies\Microsoft\Exchange"
            $Name = "MaxNumExchange"
            $value = "19"
            IF (!(Test-Path $registryPath))
            {
                New-Item -Path $registryPath -Force | Out-Null
            }
            New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
        }

        Function Set-2013
        {
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\AutoDiscover" -Name "ExcludeHttpsRootDomain" -Value "1"
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\AutoDiscover" -Name "ExcludeHttpsAutoDiscoverDomain" -Value "1"
            # Allow adding up to 14 accounts, can adjust to 99 I believe
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Exchange" -Name "MaxNumExchange" -Value "14"
            SetReg -Path "HKCU:\Software\Policies\Microsoft\Exchange" -Name "MaxNumExchange" -Value "14"
        }

        Function Set-2016
        {
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover" -Name "ExcludeHttpsRootDomain" -Value "1"
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover" -Name "ExcludeHttpsAutoDiscoverDomain" -Value "1"
            # Allow adding up to 14 accounts, can adjust to 99 I believe
            SetReg -Path "HKCU:\SOFTWARE\Microsoft\Exchange" -Name "MaxNumExchange" -Value "14"
            SetReg -Path "HKCU:\Software\Policies\Microsoft\Exchange" -Name "MaxNumExchange" -Value "14"
        }

    }
    
    Process
    {
        Write-ToString "Getting the version of Operating System"
        $WMI = Get-WmiObject -Class win32_operatingsystem | Select-Object -Property Version
        $String = $WMI.Version.tostring()
        $OS = $String.Substring(0, 4)

        Write-ToString "Getting the version of Office"
        $Version = 0
        $Reg = [Microsoft.Win32.Registrykey]::Openremotebasekey('Localmachine', $Env:Computername)
        $Reg.Opensubkey('Software\Microsoft\Office').Getsubkeynames() |Foreach-Object {
            If ($_ -Match '(\d+)\.') 
            {
                If ([Int]$Matches[1] -Gt $Version) 
                {
                    $Version = $Matches[1] 
                }
            }   
        }


        If ($OS -match "10.0" -and $Version -match "15")
        {
            Write-ToString "Creating settings for Windows 10 and Office 2013"
            Set-2013
        }

        ElseIf ($OS -match "10.0" -and $Version -match "16")
        {
            Write-ToString "Creating settings for Windows 10 and Office 2016"
            Set-2016
        }

        ElseIf ($OS -match "6.3." -and $Version -match "15")
        {
            Write-ToString "Creating settings for Windows 8.1 and Office 2013"
            Set-2013Old
        }

        ElseIf ($OS -match "6.3." -and $Version -match "16")
        {
            Write-ToString "Creating settings for Windows 8.1 and Office 2016"
            Set-2016Old
        }

        ElseIf ($OS -match "6.1." -and $Version -match "15")
        {
            Write-ToString "Creating settings for Windows 7 and Office 2013"
            Set-2013Old
        }
    
        ElseIf ($OS -match "6.1." -and $Version -match "16")
        {
            Write-ToString "Creating settings for Windows 7 and Office 2016"
            Set-2016Old
        }

        Else
        {
            Write-ToString "Either the OS is unsupported or Office is not installed/ unsupported."
        }
    
        Write-ToString "Sending OWA Link to Desktop"
        # Send OWA Link to desktop
        $TargetFile = "https://your.owa.com"
        $ShortcutFile = "$env:userprofile\Desktop\OWA.url"
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
        $Shortcut.TargetPath = $TargetFile
        $Shortcut.Save()

        # Clear Credential Manager manually (pick and choose)
        rundll32.exe keymgr.dll, KRShowKeyMgr

    
        # To Clear Completely
        # cmd /c "cmdkey /list" | ForEach-Object {if ($_ -like "*Target:*")
        #    {
        #    cmdkey /del:($_ -replace " ", "" -replace "Target:", "")
        #    }} 
    }

    End
    {
        If ($EnabledLogging)
        {
            Stop-Log
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>