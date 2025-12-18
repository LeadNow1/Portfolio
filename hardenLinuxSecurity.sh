#!/bin/bash
# =============================================================
# One-Click Linux Ubuntu Server Hardening Script
# Purpose: Apply basic security hardening to a fresh Ubuntu Server
# Script name: hardenLinuxSecurity.sh
# Usage: sudo ./harden_ubuntu.sh
# Warning: Run as root or with sudo. Test in a lab environment first.
# =============================================================

# Exit immediately if any command fails
set -e 

### VARIABLES ###
ADMIN_USER="adminuser" # Change if needed
SSH_PORT=22

### 1. ENSURE SCRIPT IS RUN AS ROOT ###
# If the Effective User ID is not root, tell user to run as root; root should equal 0
if [ "$EUID" -ne 0 ]; then
echo "Please run as root or with sudo"
exit 1
fi

echo "Starting Ubuntu Server Hardening"

### 2. UPDATE & PATCH SYSTEM ###
echo "Updating system packages"
apt update
apt upgrade -y
apt autoremove -y

### 3. SET HOSTNAME ###
echo "Setting hostname"
hostnamectl set-hostname secure-ubuntu-server

### 4. CREATE ADMIN USER IF NOT EXISTS ###
if id "$ADMIN_USER" &>/dev/null; then
echo "User $ADMIN_USER already exists"
else
echo "Creating admin user: $ADMIN_USER"
adduser $ADMIN_USER
usermod -aG sudo $ADMIN_USER
fi

### 5. HARDEN SSH ###
echo "Hardening SSH configuration"

# Create a backup of the SSH server configuration file before you make changes 
# So you can restore the SSH server configuration file if something breaks
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Edits the sshd_config file by finding the commented-out SSH port line
# Then replaces the commented line with a new port setting with the value stored in $SSH_PORT
sed -i "s/^#Port.*/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sed -i "s/^#MaxAuthTries.*/MaxAuthTries 3/" /etc/ssh/sshd_config
sed -i "s/^#LoginGraceTime.*/LoginGraceTime 30/" /etc/ssh/sshd_config

systemctl restart ssh

### 6. ENABLE FIREWALL (UFW) and BLOCK UNUSED PORTS ###
echo "Configuring firewall"
apt install ufw -y
ufw default deny incoming
ufw default allow outgoing
echo "Allowing SSH (port 22)"
ufw allow $SSH_PORT/tcp
ufw allow 22/tcp
ufw --force enable


echo "Blocking Telnet (port 23)"
ufw deny 23/tcp

echo "Blocking FTP (ports 20 and 21)"
ufw deny 20/tcp
ufw deny 21/tcp

echo "Blocking SMB (ports 139 and 445)"
ufw deny 139/tcp
ufw deny 445/tcp

echo "Blocking HTTP (port 80)"
ufw deny 80/tcp

echo "Enabling UFW firewall"
ufw --force enable

echo "Firewall rules applied:"
ufw status verbose

# Check Open Ports, Only SSH should be listening
sudo ss -tulnp

### 7. INSTALL FAIL2BAN ###
echo "Installing Fail2Ban"

# Installs fail2ban to protect ssh
# Fail2ban monitors log files (like /var/log/auth.log)
# And detects failed login attempts and bans attacking IPs using firewall rules (iptables/nftables)
apt install fail2ban -y

# cat > redirects output into jail.local
# <<EOF tells the shell “Everything until EOF should be written into the file”
cat > /etc/fail2ban/jail.local <<EOF
# Fail2Ban’s jail configuration
[sshd]
enabled = true
port = ssh
# Automatically bans IPs after repeated failed login attempts
maxretry = 3
bantime = 3600
EOF

systemctl enable fail2ban
systemctl restart fail2ban

### 8. INSTALL MALWARE SCANNER ###
sudo apt install rkhunter -y
sudo rkhunter --update
sudo rkhunter --check

### 9. SECURE FILE PERMISSIONS ###
sudo chmod 700 /root
sudo chmod 600 /etc/ssh/sshd_config


### 10. DISABLE UNNECESSARY SERVICES ###

sudo systemctl list-unit-files --type=service

echo "Disabling insecure legacy services"

# Never use services that transmit data in clear text on modern systems
# Disable telnet, FTP, rlogin, rsh, rexec, rcp, bluetoothd

# List of insecure services and their common package names
SERVICES=(
  telnet
  telnetd
  vsftpd
  ftp
  rsh-server
  rsh-client
  rlogin
  rexec
  bluetoothd
  inetutils-rsh
  inetutils-rlogin
  inetutils-rcp
)

# Uncomment to disable apache2 only if you’re using nginx 
sudo systemctl disable apache2 
sudo systemctl stop apache2

# Loop through each service/package to stop, remove, or disable it
for SERVICE in "${SERVICES[@]}"; do
    echo "[*] Processing: $SERVICE"

    # Stop the service if it is running
    # 2>/dev/null discards error messages into null and stops it from showing on the screen
    systemctl stop "$SERVICE" 2>/dev/null

    # Disable the service from starting at boot
    systemctl disable "$SERVICE" 2>/dev/null

    # Remove the package if installed
    if dpkg -l | grep -q "^ii.*$SERVICE"; then
        echo "    - Removing package: $SERVICE"
        apt-get remove --purge -y "$SERVICE"
    else
        echo " - Package not installed: $SERVICE"
    fi
done

### 11. CLEAN UP UNUSED PACKAGES AND DEPENDENCES ###
echo "Cleaning up unused packages..."
apt-get autoremove -y
apt-get autoclean -y
echo "Insecure legacy services disabled and removed successfully."

# Don't forget to make this script executable chmod +x hardenLinuxSecurity.sh

echo "Linux Ubuntu Server security is now successfully hardened"
