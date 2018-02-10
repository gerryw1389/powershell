<#######<Script>#######>
<#######<Header>#######>
# Name: Send-ADHealthReport
# Copyright: Gerry Williams (https://www.gerrywilliams.net)
# License: MIT License (https://opensource.org/licenses/mit)
# Script Modified from: n/a
<#######</Header>#######>
<#######<Body>#######>

Function Send-ADHealthReport
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
Note: If you don't like my scripts forcing logging, I wrote a post on how to fix this at https://www.gerrywilliams.net/2018/02/ps-forcing-preferences/
.Example
Send-ADHealthReport
Sends A Report To The Email You Specify Of Ad Health Check Tests That Run Will Run On The Domain Controller.
.Notes
2017-09-08: v1.0 Initial script 
.Functionality
Please see https://www.gerrywilliams.net/2017/09/running-ps-scripts-against-multiple-computers/ on how to run against multiple computers.
 
#>
   [Cmdletbinding()]

    Param
    (
        [String]$Logfile = "$PSScriptRoot\..\Logs\Send-ADHealthReport.log"
    )

    Begin
    {
        Function Send-Email ([String] $Body)
        {
            $Mailmessage = New-Object System.Net.Mail.Mailmessage
            $Mailmessage.From = "Email@Domain.Com"
            $Mailmessage.To.Add("Administratoremail@Domain.Com")
            $Mailmessage.Subject = "Ad Daily Replication Summary"
            $Mailmessage.Body = $Body
            #$Mailmessage.Priority = "High"
            $Mailmessage.Isbodyhtml = $True

            $Smtpclient = New-Object System.Net.Mail.Smtpclient
            $Smtpclient.Host = "Smtp.Server.Hostname"
            $Smtpclient.Send($Mailmessage)
        }
       
      Import-Module -Name "$Psscriptroot\..\Private\helpers.psm1" 
		$PSDefaultParameterValues = @{ "*-Log:Logfile" = $Logfile }
Set-Variable -Name "Logfile" -Value $Logfile -Scope "Global"
        Set-Console
        Start-Log
        
    }
    
    Process
    {
        
        

        # Get The Replication Info.
        $Myrepinfo = @(Repadmin /Replsum * /Bysrc /Bydest /Sort:Delta)
 
        # Initialize Our Array.
        $Cleanrepinfo = @()
        # Start @ #10 Because All The Previous Lines Are Junk Formatting
        # And Strip Off The Last 4 Lines Because They Are Not Needed.
        For ($I = 10; $I -Lt ($Myrepinfo.Count - 4); $I++)
        {
            If ($Myrepinfo[$I] -Ne "")
            {
                # Remove Empty Lines From Our Array.
                $Myrepinfo[$I] -Replace 'S+', " "           
                $Cleanrepinfo += $Myrepinfo[$I]            
            }
        }           
        $Finalrepinfo = @()  
        Foreach ($Line In $Cleanrepinfo)
        {
            $Splitrepinfo = $Line -Split 'S+', 8
            If ($Splitrepinfo[0] -Eq "Source")
            {
                $Reptype = "Source" 
            }
            If ($Splitrepinfo[0] -Eq "Destination")
            {
                $Reptype = "Destination" 
            }
           
            If ($Splitrepinfo[1] -Notmatch "Dsa")
            {      
                # Create An Object And Populate It With Our Values.
                $Objrepvalues = New-Object System.Object
                $Objrepvalues | Add-Member -Type Noteproperty -Name Dsatype -Value $Reptype # Source Or Destination Dsa
                $Objrepvalues | Add-Member -Type Noteproperty -Name Hostname  -Value $Splitrepinfo[1] # Hostname
                $Objrepvalues | Add-Member -Type Noteproperty -Name Delta  -Value $Splitrepinfo[2] # Largest Delta
                $Objrepvalues | Add-Member -Type Noteproperty -Name Fails -Value $Splitrepinfo[3] # Failures
                #$Objrepvalues | Add-Member -Type Noteproperty -Name Slash  -Value $Splitrepinfo[4] # Slash Char
                $Objrepvalues | Add-Member -Type Noteproperty -Name Total -Value $Splitrepinfo[5] # Totals
                $Objrepvalues | Add-Member -Type Noteproperty -Name Pcterror  -Value $Splitrepinfo[6] # % Errors  
                $Objrepvalues | Add-Member -Type Noteproperty -Name Errormsg  -Value $Splitrepinfo[7] # Error Code
          
                # Add The Object As A Row To Our Array   
                $Finalrepinfo += $Objrepvalues
           
            }
        }
        $Html = $Finalrepinfo|Convertto-Html -Fragment       
           
        $Xml = [Xml]$Html

        $Attr = $Xml.Createattribute("Id")
        $Attr.Value = 'Disktbl'
        $Xml.Table.Attributes.Append($Attr)


        $Rows = $Xml.Table.Selectnodes('//Tr')
        For ($I = 1; $I -Lt $Rows.Count; $I++)
        {
            $Value = $Rows.Item($I).Lastchild.'#Text'
            If ($Value -Ne $Null)
            {
                $Attr = $Xml.Createattribute('Style')
                $Attr.Value = 'Background-Color: Red;'
                [Void]$Rows.Item($I).Attributes.Append($Attr)
            }
   
            Else
            {
                $Value
                $Attr = $Xml.Createattribute('Style')
                $Attr.Value = 'Background-Color: #7bce73;'
                [Void]$Rows.Item($I).Attributes.Append($Attr)
            }
        }

        #Embed A Css Stylesheet In The Html Header
        $Html = $Xml.Outerxml|Out-String
        $Style = '<Style Type=Text/Css>#Disktbl { Background-Color: White; } 
            Td, Th { Border:1px Solid Black; Border-Collapse:Collapse; }
            Th { Color:White; Background-Color:Black;Font-Family:Verdana;Font-Size:9pt; }
            Table, Tr, Td { Font-Family:Verdana;Font-Size:9pt;Padding: 1px 5px; }, Th { Padding: 2px 5px; Margin: 0px } Table { Margin-Left:50px; }</Style>'

        #Convertto-Html -Head $Style -Body $Html -Title "Replication Report"|Out-File Replicationreport.Htm

        $Bodyhtml = Convertto-Html -Head $Style -Body $Html -Title "Replication Report" | Out-String

        Send-Email $Bodyhtml
        Log "Email Sent" 
    }

    End
    {
        Stop-Log  
    }

}

# Send-ADHealthReport

<#######</Body>#######>
<#######</Script>#######>