#!/bin/bash

# Script name: create_user.sh
# Usage: Takes in a username and creates a user with a home directory

USER=$1

# Check if username is provided
if [ -z "$USER" ]; then
    echo "Usage: $0 username"
  exit 1
fi

# Create the user with a home directory
sudo useradd -m "$USER"

echo "User $USER created."

# Set a default password
echo "$USER:ChangeMe123!" | chpasswd

# Force password change at next login
chage -d 0 "$USER"

echo "User $USER created and password reset."
