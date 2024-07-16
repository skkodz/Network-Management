#############################################
# Get-ADUserReport.ps1
# Version: 1.4
# Author: S Kodz
# Last Updated 16 July 2024
#############################################

# This script will extract metadata relating to all users within the current AD Domain
#               ####################-IMPORTANT-####################
# To obtain correct/complete data ensure you are running the PowerShell in Administrator mode
# e.g Right click the icon and "Run as Administrator" , otherwise the data might not be accurate.

#Requires -RunAsAdministrator

$OutputFile = (get-date -format yyyyMMdd-HHmm) + $env:USERDOMAIN + ".csv"

get-aduser -filter * -properties SamAccountName,DisplayName,EmailAddress,Enabled,lastlogontimestamp,pwdLastSet,msDS-userPasswordExpiryTimeComputed,PasswordNeverExpires,AccountExpirationDate `
    | select SamAccountName,@{Name="Display Name"; Expression={$_.DisplayName}},@{Name="Email Address"; Expression={$_.EmailAddress}},Enabled, `
    @{Name="Last Logon Date";Expression={([datetime]::FromFileTime($_.LastLogonTimeStamp).ToUniversalTime() | Get-Date -Format yyyy/MM/dd)}}, `
    @{Name="Last Logon Time";Expression={([datetime]::FromFileTime($_.LastLogonTimeStamp).ToUniversalTime() | Get-Date -Format HH:mm)}}, `
    @{Name="pwd Last Set Date";Expression={([datetime]::FromFileTime($_.pwdLastSet).ToUniversalTime() | Get-Date -Format yyyy/MM/dd)}}, `
    @{Name="pwd Last Set Time";Expression={([datetime]::FromFileTime($_.pwdLastSet).ToUniversalTime() | Get-Date -Format HH:mm)}}, `
    @{Name="pwd Expire Date";Expression={([datetime]::FromFileTime($_."msDS-userPasswordExpiryTimeComputed").ToUniversalTime() | Get-Date -Format yyyy/MM/dd)}}, `
    @{Name="pwd Expire Time";Expression={([datetime]::FromFileTime($_."msDS-userPasswordExpiryTimeComputed").ToUniversalTime() | Get-Date -Format HH:mm)}}, `
    PasswordNeverExpires, `
    @{Name="Acct Expire Date";Expression={($_.AccountExpirationDate).ToUniversalTime() | Get-Date -Format yyyy/MM/dd}}, `
    @{Name="Acct Expire Time";Expression={($_.AccountExpirationDate).ToUniversalTime() | Get-Date -Format HH:mm}} `
    | Export-CSV -Path $OutputFile  -force -notypeinformation
