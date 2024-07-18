# Import the Active Directory module
Import-Module ActiveDirectory

# Get all computers in the domain
$computers = Get-ADComputer -Filter * -Property msLAPS-EncryptedPassword, msLAPS-PasswordExpirationTime

# Initialize an array to store the results
$results = @()

foreach ($computer in $computers) {
    # Check if the LAPS attributes are present
    $lapsEnabled = $false
    if ($computer."msLAPS-EncryptedPassword" -ne $null -and $computer."msLAPS-PasswordExpirationTime" -ne $null) {
        $lapsEnabled = $true
    }

    # Create an object with the computer name and LAPS status
    $results += [PSCustomObject]@{
        ComputerName = $computer.Name
        LAPSStatus   = if ($lapsEnabled) { "Enabled" } else { "Not Enabled" }
    }
}

# Output the results
$results | Format-Table -AutoSize
