<#######<Script>#######>
<#######<Header>#######>
# Name: Send-ADDCDiagReport
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Send-ADDCDiagReport
{
    <#
.Synopsis
This Function Is Best Placed A Scheduled Task To Run Daily On The Domain Controller. 
It Will Send An Email Showing Results Of Ad Health Checks. 
.Description
This Function Is Best Placed A Scheduled Task To Run Daily On The Domain Controller. 
It Will Send An Email Showing Results Of Ad Health Checks.
You Will Need To Setup The From Address, To Address, Smtp Server, $Logfile" Variables.
.Parameter Logfile
Specifies A Logfile. Default is $PSScriptRoot\..\Logs\Scriptname.Log and is created for every script automatically.
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
.Example
Send-ADDCDiagReport
Sends A Report To The Email You Specify Of Various Dc Diag Tests That Run Will Run On The Domain Controller.
.Notes
Requires The Active Directory Module.
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.

#>

    [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Send-ADDCDiagReport.Log"
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

        Function Send-Email ([String] $Body)
        {
            $Mailmessage = New-Object System.Net.Mail.Mailmessage
            $Mailmessage.From = "Email@Domain.Com"
            $Mailmessage.To.Add("Administrator@Domain.Com")
            $Mailmessage.Subject = "Dcdiag Health Summary V2"
            $Mailmessage.Body = $Body
            #$Mailmessage.Priority = "High"
            $Mailmessage.Isbodyhtml = $True

            $Smtpclient = New-Object System.Net.Mail.Smtpclient
            $Smtpclient.Host = "Smtp.Server.Hostname"
            $Smtpclient.Send($Mailmessage)
        }

        Function Converttovertical ([String] $Testname)
        {

            $Stringlength = $Testname.Length

            For ($I = 0; $I -Lt $Stringlength; $I++)
            {
                $Newname = $Newname + "<Br>" + $Testname.Substring($I, 1)
            }

            $Newname 
        }

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
        $Adinfo = Get-Addomain
        $Alldcs = $Adinfo.Replicadirectoryservers

        $Testnamecount = 0

        $A = "<Style>"
        $A = $A + `
            "Body{Color:#717d7d;Background-Color:#F5f5f5;Font-Size:8pt;Font-Family:'Trebuchet Ms', Helvetica, Sans-Serif;Font-Weight:Normal;Padding-:0px;Margin:0px;Overflow:Auto;}"
        #$A = $A + "A{Font-Family:Tahoma;Color:#717d7d;Font-Size:10pt Display: Block;}"
        $A = $A + "Table,Td,Th {Font-Family:Tahoma;Color:Black;Font-Size:8pt}"
        $A = $A + "Th{Font-Weight:Bold;Background-Color:#Addfff;}"
        #$A = $A + "Td {Background-Color:#E3e4fa;Text-Align: Center}"
        $A = $A + "</Style>"


        Foreach ($Item In $Alldcs)
        {
            Dcdiag.Exe /V /S:$Item >> $Logfile


            #New-Variable "Allresults$Item" -Force
            #$C = $Allresults + $Item
    
            $Allresults = New-Object Object
            $Allresults | Add-Member -Type Noteproperty -Name "Servername" -Value $Item
            #$Testcat = $Null
            $Table += "<Tr><Td>$Item</Td>"
            Get-Content $Logfile | Foreach-Object
            {
                Switch -Regex ($_)
                {
                    #"Running"   { $Testcat    = ($_ -Replace ".*Tests On : ").Trim() }
                    "Starting"
                    {
                        $Testname = ($_ -Replace ".*Starting Test: ").Trim() 
                    }
                    "Passed|Failed"
                    {
                        If ($_ -Match "Passed")
                        { 
                            $Teststatus = "Psd" 
                        }
                        Else
                        { 
                            $Teststatus = "Fld" 
                        } 
                    }
                }

                If ($Testname -Ne $Null -And $Teststatus -Ne $Null)
                {
                    $Testnamevertical = Converttovertical($Testname)


                    $Allresults | Add-Member -Name $("$Testnamevertical".Trim()) -Value $Teststatus -Type Noteproperty -Force
    
                    If ($Teststatus -Eq "Fld")
                    {
                        $Table += "<Td Style=""Background-Color:Red;"">$Teststatus</Td>"
                    }
                    Else
                    {
                        $Table += "<Td Style=""Background-Color:Green;"">$Teststatus</Td>"
                    }
    
                    If ($Testnamecount -Lt 29)
                    {
                        $Alltestnames = $Alltestnames + "<Br>" + $Testname
                        $Testnames += "<Td Style=""Background-Color:#Cce3ff;"">$Testnamevertical</Td>"
                        #$Testnames+="<Td Class=""Titlestyle"">T<Br>E<Br>S<Br>T</Td>"
                        $Testnamecount++
                    }
    
                    $Testname = $Null; $Teststatus = $Null
                }
                New-Variable "Last$Item" -Force -Value $Allresults
            } 
        
            $Table += "</Tr>"

        } 

        $Html = `
            "<Html><Head>$A</Head><H2>Active Directory Health Check</H2><Br></Br><Table><Tr><Td>S<Br>E<Br>R<Br>V<Br>E<Br>R<Br>N<Br>A<Br>M<Br>E</Td>" + $Testnames `
            + "</Tr>" + $Table + "</Table><Br><Br>Tests Ran: $Alltestnames</Html>"
        #$Html | Out-File "C:\Scripts\Send-ADDCDiagReport.Html"
        $Body = $Html | Out-String
        Send-Email $Body
        Write-ToString "Email Sent"
   
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