##################################################################################
# Get-ADExpired.ps1
# Version: 1.0
# Author: S Kodz
# Last Updated 01 Dec 2022 by S Kodz
#
#   Version 1.0 - 01 Dec 2022 by S Kodz
#      Original Version
#
# This script will search the entire AD tree and return a list of users with
# passwords that have expired.
#
# NOTE: Run PowerShell as an administrator to get all results.
#
##################################################################################

Get-ADUser -filter * -properties SamAccountName,PasswordExpired | Where-Object {$_.PasswordExpired -EQ 'True'} | sort Name | Format-Table @{L='User Name';E={$_.Name}}, @{L='Account Name';E={$_.SamAccountName}}, @{L='Expired';E={$_.PasswordExpired}}
