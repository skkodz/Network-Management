##################################################################################
# Get-TreeSize.ps1
# Version: 1.0
# Author: S Kodz
# Last Updated 25 Jan 2023 by S Kodz
#
# Version History
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
  [Parameter(Mandatory=$false)] [string]$Path = '.'
)
if ( -not (Test-Path -Path $Path -PathType Container ) ) {Throw "$($Path) is not a valid directory." }
Write-Host "Please wait while the directory sizes within directory '$Path' are calculated. This may take some time..."
$directory = Get-ChildItem -Path $Path -Directory
foreach ($dir in $directory) {
Get-ChildItem -Path $dir -Recurse | Measure-Object -Sum Length | Select-Object @{Name="Path"; Expression={$dir.FullName}},@{Name="Files"; Expression={$_.Count}},@{Name="Size (GB)"; Expression={$_.Sum / 1GB}}}
