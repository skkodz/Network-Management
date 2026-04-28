##################################################################################
# ManageLogging.ps1
# Version: 1.0
# Author: S Kodz
# Last Updated 28 April 2026 by S Kodz
#
#   Version 1.0 - 28 April 2026 by S Kodz
#      Original Version
#
# This script lists and optionally modifies the logging parameters within a
# vCenter cluster.
#
# -vCenterServer <string>
#   The FQDN of your vCenter (e.g., vcenter.domain.com) - MANDATORY
#
# -clusterName <string>
#   The name of the cluster to target (e.g., Production) - OPTIONAL
#
##################################################################################

param (
    [Parameter(Mandatory=$true)]
    [string]$vCenterServer,
    
    [Parameter(Mandatory=$false)]
    [string]$clusterName
)

# --- Help / Parameter Validation ---
if ([string]::IsNullOrWhiteSpace($vCenterServer)) {
    Write-Host "`n[ ERROR: Missing Required Parameters ]" -ForegroundColor Red
    Write-Host "This script manages vSphere logging levels interactively." -ForegroundColor Yellow
    Write-Host "`nRequired Parameter:"
    Write-Host "  -vCenterServer : The FQDN of your vCenter (e.g., vcenter.domain.com)"
    Write-Host "`Optional Parameter:"
    Write-Host "  -clusterName   : The name of the cluster to target (e.g., Production-Cluster)"
    
    Write-Host "`nExample Usage:" -ForegroundColor Cyan
    Write-Host "  PowerShell ./ManageLogging.ps1 -vCenterServer 'vcenter.domain.com' -clusterName 'Production-Cluster'"
    Write-Host ""
    exit
}

# 1. Connect to vCenter (Check for existing connection first)
$connection = $global:DefaultVIServers | Where-Object { $_.Name -eq $vCenterServer }

if ($connection -and $connection.IsConnected) {
    Write-Host "Using existing connection to $vCenterServer..." -ForegroundColor Green
} else {
    try {
        Write-Host "No active session found for $vCenterServer. Please provide credentials." -ForegroundColor Yellow
        $creds = Get-Credential
        Write-Host "Connecting to $vCenterServer..." -ForegroundColor Cyan
        $connection = Connect-VIServer -Server $vCenterServer -Credential $creds -ErrorAction Stop
    } catch {
        Write-Host "CRITICAL: Could not connect to $vCenterServer. Check network/credentials." -ForegroundColor Red
        exit
    }
}

# 2. Cluster Validation & Selection
$cluster = $null
if (-not [string]::IsNullOrWhiteSpace($clusterName)) {
    $cluster = Get-Cluster -Name $clusterName -ErrorAction SilentlyContinue
    if (-not $cluster) {
        Write-Host "WARNING: Provided cluster '$clusterName' does not exist." -ForegroundColor Red
    }
}

if (-not $cluster) {
    $available = Get-Cluster | Select-Object -ExpandProperty Name
    if ($available.Count -eq 0) { Write-Error "No clusters found on this server."; exit }

    Write-Host "`nPlease select a valid cluster number or press [Q] to Quit:" -ForegroundColor Yellow
    $map = @{}
    for ($i = 0; $i -lt $available.Count; $i++) {
        $num = $i + 1
        Write-Host " [$num] $($available[$i])"
        $map[$num.ToString()] = $available[$i]
    }
    Write-Host " [Q] Quit"

    do {
        $key = [Console]::ReadKey($true)
        $choice = $key.KeyChar.ToString().ToUpper()
        # Build regex for valid numbers 1 to Count or Q
        $pattern = "^([1-$($available.Count)]|Q)$"
    } while ($choice -notmatch $pattern)

    if ($choice -eq "Q") { Write-Host "`nAborted."; exit }
    $cluster = Get-Cluster -Name $map[$choice]
    $clusterName = $cluster.Name
    Write-Host "`nTargeting Cluster: $clusterName" -ForegroundColor Green
}
$hosts = $cluster | Get-VMHost

# 3. External Syslog (SIEM) Configuration for ESXi
Write-Host "`n--- ESXi External Logging (Syslog/SIEM) ---" -ForegroundColor Cyan
$currentHostSyslog = ($hosts | Get-AdvancedSetting -Name "Syslog.global.logHost" -ErrorAction SilentlyContinue | Select-Object -First 1).Value
$esxiTarget = if ($currentHostSyslog) { $currentHostSyslog } else { "None" }
Write-Host "Current Cluster Syslog Target: $esxiTarget"

if ((Read-Host "Update Syslog location for all hosts in this cluster? (y/n)") -eq 'y') {
    $newSyslog = Read-Host "Enter Syslog Target (e.g., udp://10.0.0.5:514)"
    if (-not [string]::IsNullOrWhiteSpace($newSyslog)) {
        foreach ($vmhost in $hosts) {
            $existing = Get-AdvancedSetting -Entity $vmhost -Name "Syslog.global.logHost" -ErrorAction SilentlyContinue
            if ($existing) { $existing | Set-AdvancedSetting -Value $newSyslog -Confirm:$false }
            else { New-AdvancedSetting -Entity $vmhost -Name "Syslog.global.logHost" -Value $newSyslog -Confirm:$false }
            
            # Enable Firewall & Reload
            $rule = Get-VMHostFirewallException -VMHost $vmhost | Where-Object {$_.Name -eq "syslog"}
            if ($rule) { Set-VMHostFirewallException -FirewallException $rule -Enabled $true }
            (Get-EsxCli -VMHost $vmhost -V2).system.syslog.reload.Invoke()
        }
        Write-Host "Syslog updated and firewall opened for cluster." -ForegroundColor Green
    }
}

# 4. Log Source Definitions
$logSources = @(
    @{ Name = "Config.HostAgent.log.level"; Desc = "hostd (ESXi Agent)"; Target = "Host" },
    @{ Name = "Vpx.Vpxa.config.log.level";  Desc = "vpxa (Host-vCenter Link)"; Target = "Host" },
    @{ Name = "Syslog.global.logLevel";     Desc = "vmsyslogd (Syslog Filter)"; Target = "Host" },
    @{ Name = "NFC.LogLevel";               Desc = "NFC (Migrations/Cloning)"; Target = "Host" },
    @{ Name = "config.log.level";           Desc = "vpxd (vCenter Core)"; Target = "vCenter" }
)

# 5. Display Current Levels
Write-Host "`n--- Current Logging Configuration ---" -ForegroundColor Cyan
foreach ($source in $logSources) {
    $targetObj = if ($source.Target -eq "vCenter") { $connection } else { $hosts }
    $setting = Get-AdvancedSetting -Entity $targetObj -Name $source.Name -ErrorAction SilentlyContinue | Select-Object -First 1
    $val = if ($setting.Value) { $setting.Value } else { "Default" }
    Write-Host " > [$($source.Name)]: $val"
}

# 6. Interactive Configuration
Write-Host "`n--- Configuration Menu (Enter to skip) ---" -ForegroundColor Yellow
foreach ($source in $logSources) {
    Write-Host "`nSetting: $($source.Name) ($($source.Desc))" -ForegroundColor White
    $new = Read-Host "Enter level (error/warning/info/verbose/trivia)"

    if (-not [string]::IsNullOrWhiteSpace($new)) {
        try {
            if ($source.Target -eq "vCenter") {
                $existing = Get-AdvancedSetting -Entity $connection -Name $source.Name -ErrorAction SilentlyContinue
                if ($existing) { $existing | Set-AdvancedSetting -Value $new -Confirm:$false }
                else { New-AdvancedSetting -Entity $connection -Name $source.Name -Value $new -Confirm:$false }
            } else {
                foreach ($vmhost in $hosts) {
                    $existing = Get-AdvancedSetting -Entity $vmhost -Name $source.Name -ErrorAction SilentlyContinue
                    if ($existing) { $existing | Set-AdvancedSetting -Value $new -Confirm:$false }
                    else { New-AdvancedSetting -Entity $vmhost -Name $source.Name -Value $new -Confirm:$false }
                    
                    if ($source.Name -eq "Syslog.global.logLevel") { 
                        (Get-EsxCli -VMHost $vmhost -V2).system.syslog.reload.Invoke()
                    }
                }
            }
            Write-Host "Update successful." -ForegroundColor Green
        } catch { Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red }
    }
}

# 7. Final Instructions
Write-Host "`n==================================================================" -ForegroundColor Yellow
Write-Host "ESXi Host configuration is complete."
Write-Host "Note: To modify vCenter Appliance (OS) Syslog Forwarding settings,"
Write-Host "please log in to the vCenter Management Interface (VAMI) at:"
Write-Host "https://$($vCenterServer):5480" -ForegroundColor Cyan
Write-Host "Navigate to: Syslog > Forwarding Configuration."
Write-Host "==================================================================" -ForegroundColor Yellow
