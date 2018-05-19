$Array1 = 1..9999 # Reference Array counting 1 to 9999
    $Array2 = 2..9998 # Difference Array counting 2 to 9998
    #If my code works you'll get back 2 missing values
    $Hash = @{} # Hashtable created from the difference array
    #This builds our hastable, we're looking through the array and mapping the values and keys to $Hash
    # hashtables can't have duplicate keys the IF -not checks to make sure it doesn't exist already
    $Array2 | ForEach-Object -Process { IF (-not $Hash.ContainsKey($_))
        {
            $Hash.Add($_, "") # the value you add here doesn't matter, I like to do "" but you can easily to "some value", "Bob", or "Jim"
        }} 
    Write-Host "$(Get-Date -Format u) | Checking for missing Values..."
    $missing = @() # empty array to put our difference into
    ForEach ($item in $Array1)
    {
        IF ($Hash.ContainsKey($item))
        {
            #Do Nothing
        }
        ELSE
        {
            Write-Host "Array 2 Missing Value: $item"
            $missing += $item
        }
    }
    write-host "Found : $($missing.Count) missing items"