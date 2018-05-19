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

        # Load the required module(s) 
        Try
        {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        Catch
        {
            Write-Output "Module 'ActiveDirectory' was not found, stopping script" | Timestamp
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
        Write-Output "Email Sent" | TimeStamp
   
    }
    
    End
    {
        If ($EnabledLogging)
        {
            Write-Output "Script Completed on $env:COMPUTERNAME" | TimeStamp
            Write-Output "####################</Script>####################"
            Stop-Transcript
        }
    }

}

<#######</Body>#######>
<#######</Script>#######>