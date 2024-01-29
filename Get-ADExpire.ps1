##################################################################################
# Get-ADExpire.ps1
# Version: 1.0
# Author: S Kodz
# Last Updated 24 Nov 2022 by S Kodz
#
#   Version 1.0 - 24 Nov 2022 by S Kodz
#      Original Version
#
# This script will search the entire AD tree and return the date (and time) that
# passwords will expire. Unless specified, it will only list those expiring
# within the next 14 days.
# 
# -Expire <integer>
#   This parameter specified how many days time to check for expired passwords,
#   but defaults to 14 if not specified.
#
# NOTE: Run PowerShell as an administrator to get all results.
#
##################################################################################

Param( 
  [Parameter(Mandatory=$false)][ValidateRange(1,90)] [int]$Expire = '14'
)

# Retrieve Domain maximum password age policy, in days.
$D = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$Domain = [ADSI]"LDAP://$D"
$MPA = $Domain.maxPwdAge.Value
# Convert to Int64 ticks (100-nanosecond intervals).
$lngMaxPwdAge = $Domain.ConvertLargeIntegerToInt64($MPA)
# Convert to days.
$MaxPwdAge = -$lngMaxPwdAge/(600000000 * 1440)

# Determine the password last changed date such that the password
# would just now be expired. We will not process any users whose
# password has already expired.
$Now = Get-Date
$Date1 = $Now.AddDays(-$MaxPwdAge)

# Determine the password last changed date such the password
# will expire $Expire in the future.
$Date2 = $Now.AddDays($Expire - $MaxPwdAge)

# Convert from PowerShell ticks to Active Directory ticks.
$64Bit1 = $Date1.Ticks - 504911232000000000
$64Bit2 = $Date2.Ticks - 504911232000000000

$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.PageSize = 100
$Searcher.SearchScope = "subtree"

# Filter on user objects where the password expires between the
# dates specified, the account is not disabled, password never
# expires is not set, password not required is not set.
# and password cannot change is not set.
$Searcher.Filter = "(&(objectCategory=person)(objectClass=user)" `
    + "(pwdLastSet>=" + $($64Bit1) + ")" `
    + "(pwdLastSet<=" + $($64Bit2) + ")" `
    + "(!userAccountControl:1.2.840.113556.1.4.803:=2)" `
    + "(!userAccountControl:1.2.840.113556.1.4.803:=65536)" `
    + "(!userAccountControl:1.2.840.113556.1.4.803:=32)" `
    + "(!userAccountControl:1.2.840.113556.1.4.803:=48))"

$Searcher.PropertiesToLoad.Add("sAMAccountName") > $Null
$Searcher.PropertiesToLoad.Add("Name") > $Null
$Searcher.PropertiesToLoad.Add("pwdLastSet") > $Null
# Only search the specified OU.
$Searcher.SearchRoot = "LDAP://$D"

$Results = $Searcher.FindAll()
ForEach ($Result In $Results)
{
    # Retrieve attribute values for this user.
    $Name = $Result.Properties.Item("Name")
    $UN = $Result.Properties.Item("SAMAccountName")
    $PLS = $Result.Properties.Item("pwdLastSet")
    If ($PLS.Count -eq 0)
    {
        $Date = [DateTime]0
    }
    Else
    {
        # Interpret 64-bit integer as a date.
        $Date = [DateTime]$PLS.Item(0)
    }
    # Convert from .NET ticks to Active Directory Integer8 ticks.
    # Also, convert from UTC to local time.
    $PwdLastSet = $Date.AddYears(1600).ToLocalTime()
    # Determine when password expires.
    $PwdExpires = $PwdLastSet.AddDays($MaxPwdAge)

    # Output information for this user.
    "$Name ($UN), password expires on $PwdExpires"

}
