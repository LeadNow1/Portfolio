<# 
========================================================
NETWORK TROUBLESHOOTING SCRIPT

Usage: .\NetworkTroubleshootingScript.ps1
Script name: NetworkTroubleshootingScript.pst

Purpose: Diagnose common network issues and automatically fix DNS, DHCP, network adapter, Winsock, default gateway issues

This script must be run as Administrator
Restarting the adapter will temporarily disconnect the network
Winsock reset requires a reboot to fully apply
========================================================
#>

# ------------------------------------------------
# 1. CHECK IF SCRIPT IS RUNNING AS ADMINISTRATOR
# ------------------------------------------------

If (-NOT ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    Exit
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green


# ------------------------------------------------
# 2. CREATE A LOG FILE ON DESKTOP
# ------------------------------------------------

# Path to the troubleshooting report
$LogFile = "$env:USERPROFILE\Desktop\Network_Troubleshooting_AutoFix_Report.txt"

# Clear existing content if file already exists
Clear-Content $LogFile -ErrorAction SilentlyContinue

"NETWORK TROUBLESHOOTING + AUTO FIX REPORT" | Out-File $LogFile
"Generated on: $(Get-Date)" | Out-File $LogFile -Append
"--------------------------------------------------" | Out-File $LogFile -Append


# ------------------------------------------------
# 3. IDENTIFY ACTIVE NETWORK ADAPTER
# ------------------------------------------------

Write-Host "Detecting Active Network Adapter..."

# Finds the network adapter that is currently "Up"
$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

If ($null -eq $Adapter)
{
    Write-Host "❌ No active network adapter found." -ForegroundColor Red
    "No active network adapter found." | Out-File $LogFile -Append
    Exit
}

"Active Adapter: $($Adapter.Name)" | Out-File $LogFile -Append
Write-Host "✅ Active Adapter Found: $($Adapter.Name)" -ForegroundColor Green


# ------------------------------------------------
# 4. FLUSH DNS CACHE
# ------------------------------------------------

Write-Host "Flushing DNS Cache..."

# Clears locally cached DNS records
ipconfig /flushdns | Out-File $LogFile -Append

Write-Host "✅ DNS cache flushed" -ForegroundColor Green


# ------------------------------------------------
# 5. RELEASE AND RENEW IP ADDRESS
# ------------------------------------------------

Write-Host "Releasing IP Address..."

# Drops current IP address
ipconfig /release | Out-File $LogFile -Append

Start-Sleep -Seconds 3

Write-Host "Renewing IP Address..."

# Requests a new IP address from DHCP
ipconfig /renew | Out-File $LogFile -Append

Write-Host "IP address renewed" -ForegroundColor Green


# ------------------------------------------------
# 6. RESTART NETWORK ADAPTER
# ------------------------------------------------

Write-Host "Restarting Network Adapter..."

# Disables the network adapter
Disable-NetAdapter -Name $Adapter.Name -Confirm:$false
Start-Sleep -Seconds 5

# Enables the network adapter
Enable-NetAdapter -Name $Adapter.Name -Confirm:$false

"Network adapter restarted." | Out-File $LogFile -Append
Write-Host "Network adapter restarted" -ForegroundColor Green


# ------------------------------------------------
# 7. RESET WINSOCK (ADVANCED FIX)
# ------------------------------------------------

Write-Host "Resetting Winsock..."

# Fixes corrupted network stack issues
netsh winsock reset | Out-File $LogFile -Append

Write-Host "Winsock reset completed (REBOOT REQUIRED)" -ForegroundColor Yellow
"System reboot required for Winsock reset." | Out-File $LogFile -Append


# ------------------------------------------------
# 8. TEST CONNECTIVITY AFTER FIXES
# ------------------------------------------------

Write-Host "Testing Connectivity After Fixes..."

"Ping Default Gateway:" | Out-File $LogFile -Append
$Gateway = (Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway}).IPv4DefaultGateway.NextHop
Test-Connection -ComputerName $Gateway -Count 4 |
Out-File $LogFile -Append

"Ping Internet (8.8.8.8):" | Out-File $LogFile -Append
Test-Connection -ComputerName 8.8.8.8 -Count 4 |
Out-File $LogFile -Append

"DNS Test (google.com):" | Out-File $LogFile -Append
Resolve-DnsName google.com |
Out-File $LogFile -Append


# ------------------------------------------------
# 9. FINAL MESSAGE
# ------------------------------------------------

Write-Host "Network troubleshooting & auto-fix completed!" -ForegroundColor Green
Write-Host "Report saved to Desktop:"
Write-Host "Network_Troubleshooting_AutoFix_Report.txt" -ForegroundColor Cyan
Write-Host "Please RESTART the computer if internet issues persist." -ForegroundColor Yellow

