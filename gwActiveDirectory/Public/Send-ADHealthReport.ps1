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
NOTE: If you wish to delete the logfile, I have updated my scripts to where they should still run fine with no logging.
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
            $Mailmessage.To.Add("Administratoremail@Domain.Com")
            $Mailmessage.Subject = "Ad Daily Replication Summary"
            $Mailmessage.Body = $Body
            #$Mailmessage.Priority = "High"
            $Mailmessage.Isbodyhtml = $True

            $Smtpclient = New-Object System.Net.Mail.Smtpclient
            $Smtpclient.Host = "Smtp.Server.Hostname"
            $Smtpclient.Send($Mailmessage)
        }
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

# Send-ADHealthReport

<#######</Body>#######>
<#######</Script>#######>