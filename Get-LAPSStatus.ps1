##################################################################################
# Get-LAPSStatus.ps1
# Version: 1.0
# Author: S Kodz
# Last Updated 18 July 2024 by S Kodz
#
#   Version 1.0 - 18 July 2024 by S Kodz
#      Original Version
#
# This script will search the entire AD tree and return Enabled or Not Enabled
# as a table for all computers in the domain. This status shows whether 
# Windows LAPS is setting a local administrator password for that computer.
# The report is written to a timestamped file in ~\Documents.
# 
# NOTE: Run PowerShell as an administrator to get all results.
#
##################################################################################

# Import the Active Directory module
Import-Module ActiveDirectory

$ReportFile = ("~\Documents\" + (Get-Date -Format "yyyyMMdd-HHmm") + "-LAPS-Report.txt")
if (-not (Test-Path $ReportFile)) {
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
  $results | Format-Table -AutoSize | Out-File -FilePath $ReportFile
  Write-Host "Report saved to the file $ReportFile"
} else {
throw "File already exists and will not be overwritten. Wait 60 seconds and run again: $ReportFile"
}
