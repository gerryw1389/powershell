# To get the Server OS Version:

$Counter = 0
[string]$OsName = Get-Ciminstance -ClassName Win32_OperatingSystem -Property Caption | Select-Object -ExpandProperty Caption

Switch -Regex ($osName)
{
    '7'
    {
        Log $osName; $Counter = 1; Break 
    }
    # Had to put R2 first because if it matches 2008, it would just break and not keep the correct counter. Nested elseif's could be another option.
    '2008 R2'
    {
        Log $osName; $Counter = 3; Break 
    }
    '2008'
    {
        Log $osName; $Counter = 2; Break 
    }
    '2012 R2'
    {
        Log $osName; $Counter = 5; Break 
    }
    '2012'
    {
        Log $osName; $Counter = 4; Break 
    }
    '10'
    {
        Log $osName; $Counter = 6; Break 
    }
    '2016'
    {
        Log $osName; $Counter = 7; Break 
    }
}

# Then, if older than 2012r2, you can run this:

If ($Counter -le 4)
{
    # Do something in older versions of Powershell (Versions 2, 3)
}
Else
{
    # Do something in newer versions of Powershell (4+)
}