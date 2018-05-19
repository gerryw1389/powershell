begin
$ComputerObjects = @()

process:


Foreach ($Computer in $ComputerName)
            {
 
                If (!([String]::IsNullOrWhiteSpace($Computer)))
                {
 
                    If (Test-Connection -Quiet -Count 1 -Computer $Computer)
                    {
					
					$Progress = @{}
                        $Progress.Activity = "Getting Sytem Information..." 
                        $Progress.Status = ("Percent Complete:" + "{0:N0}" -f ((($i++) / $ComputerName.count) * 100) + "%")
                        $Progress.CurrentOperation = "Processing $($Computer)..."
                        $Progress.PercentComplete = ((($j++) / $ComputerName.count) * 100)
                        Write-Progress @Progress
						
						Log "ComputerName: $($ComputerObject.ComputerName.ToString())"
                        Log "LastReboot: $($ComputerObject.LastReboot.ToString())"
                        Log "OperatingSystem: $($ComputerObject.OperatingSystem.ToString())"
                        Log "Ram: $($ComputerObject.RAM.ToString())"
                        Log "TotalDiskSpace: $($ComputerObject.TotalDiskSpace.ToString())"
                        Log "CurrentUser: $($ComputerObject.CurrentUser.ToString())"
                        Log "####################<Break>####################"
 
                        $ComputerObjects += $ComputerObject
                        
                        Remove-CimSession -CimSession $CimSession 
						
						Else
                    {
                        Log "Remote computer was not online."
                        $ComputerObject = [Ordered]@{}
                        $ComputerObject.ComputerName = $computer
                        $ComputerObject.LastReboot = "Unable to ping. Make sure the computer is turned on and ICMP inbound ports are opened."
                        $ComputerObject.OperatingSystem = "$null"
                        $ComputerObject.Model = "$null"
                        $ComputerObject.RAM = "$null"
                        $ComputerObject.DiskCapacity = "$null"
                        $ComputerObject.TotalDiskSpace = "$null"
                        $ComputerObject.CurrentUser = "$null"
 
                        $ComputerObjects += $ComputerObject                     
                    }
                }
 
                Else
                {
                    Log "Computer name was not in a usable format"
                    $ComputerObject.ComputerName = "Value is null. Make sure computer name is not blank"
                    $ComputerObject.LastReboot = "$Null"
                    $ComputerObject.OperatingSystem = "$null"
                    $ComputerObject.Model = "$null"
                    $ComputerObject.RAM = "$null"
                    $ComputerObject.DiskCapacity = "$null"
                    $ComputerObject.TotalDiskSpace = "$null"
                    $ComputerObject.CurrentUser = "$null"
 
                    $ComputerObjects += $ComputerObject   
                }
            }
			
			
end

$a = $ComputerObjects | Out-String
Log $a