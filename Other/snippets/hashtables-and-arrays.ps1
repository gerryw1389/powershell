# Hashtables:
$Params = @{}
$Params.Path = "HKCU:\Some\Path"
$Params.Name = "Category"
$Params.Value = "1" 
$Params.Type = "DWORD"
SetReg @Params
 
 
# Arrays:
$Tasks = @()
$Tasks += "Microsoft-Windows-DiskDiagnosticDataCollector"
$Tasks += "QueueReporting"
ForEach ($Task in $Tasks)
{
    Get-Scheduledtask | Disable-ScheduledTask
}