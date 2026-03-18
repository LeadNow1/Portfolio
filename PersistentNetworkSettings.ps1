# This script makes your network adapter setting changes persistent against reboots, VPN connections, and GPO policy refreshes
# Run this script using powershell -ExecutionPolicy Bypass -File C:\scripts\PersistentNetworkSettings.ps1

# Use the exact network adapter name for $InterfaceAlias
# Run Get-NetAdapter to find your network adapter name
$InterfaceAlias = "Ethernet"
$IPAddress      = "192.168.1.100"
$PrefixLength   = 24
$DefaultGateway = "192.168.1.1"
$DNSServers     = @("8.8.8.8","8.8.4.4")

# Remove old IP
Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false

# Disable DHCP
Set-NetIPInterface -InterfaceAlias $InterfaceAlias -Dhcp Disabled

# Set new IP
New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway

# Set DNS
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DNSServers

# Make the script run automatically at startup (Persistence Fix) every time Windows boots up
schtasks /create /tn "FixNetwork" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\scripts\PersistentNetworkSettings.ps1" /sc onstart /rl highest /f

# Outputs the IP address for your specific network interface
Get-NetIPAddress -InterfaceAlias "Ethernet"


# If script doesn’t work, confirm you're using the correct adapter name (most common issue)
# Make sure PowerShell is Run as Admin
# If internet stops working, you likely used the wrong IP address or gateway

# Forces reapplies the PersistentNetworkSettings.ps1 script every 5 minutes
schtasks /create /tn "FixNetworkLoop" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\scripts\PersistentNetworkSettings.ps1" /sc minute /mo 5 /rl highest /f