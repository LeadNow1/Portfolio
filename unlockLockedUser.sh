#!/bin/bash

# Script name: unlockUser.sh
# Usage: ./unlock_user.sh username
# Unlock a locked user account

USER=$1

if [ -z "$USER" ]; then
   echo "Usage: $0 username"
   exit 1
fi

# Unlock the user account
sudo passwd -u "$USER"

echo "User account $USER unlocked."
