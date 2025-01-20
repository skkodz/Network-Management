##################################################################################
# Get-TreeSize.ps1
# Version: 1.1
# Author: S Kodz
# Last Updated 20 Jan 2025 by S Kodz
#
# Version History
#   Version 1.1 - 20 Jan 2025 by S Kodz
#      Adding parameters allowing for sorting of output by size.
#   Version 1.0 - 25 Jan 2023 by S Kodz
#      Original Version
#
# This script will disply the size of directory in a provided path.
# By default it will use the current directory.
# 
# -Path <path>
#   This parameter can be a drive letter or UNC path to the directory.
#
##################################################################################

Param( 
  [Parameter(Mandatory=$false)] 
  [string]$Path = '.',

  [Parameter(Mandatory=$false)] 
  [ValidateSet("Ascending", "Descending")]
  [string]$SortOrder = "Descending"
)

# Check if the provided path is valid
if (-not (Test-Path -Path $Path -PathType Container)) {
  Throw "$($Path) is not a valid directory."
}

Write-Host "Please wait while the directory sizes within directory '$Path' are calculated. This may take some time..."

# Get all subdirectories
$directory = Get-ChildItem -Path $Path -Directory

# Collect size information for each directory
$results = foreach ($dir in $directory) {
  $sizeInfo = Get-ChildItem -Path $dir -Recurse | Measure-Object -Sum Length
  [PSCustomObject]@{
    Path = $dir.FullName
    Files = $sizeInfo.Count
    SizeGB = $sizeInfo.Sum / 1GB
  }
}

# Sort the results by size
if ($SortOrder -eq "Ascending") {
  $results = $results | Sort-Object -Property SizeGB
} else {
  $results = $results | Sort-Object -Property SizeGB -Descending
}

# Output the results
$results
