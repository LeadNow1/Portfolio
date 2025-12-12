#!/bin/bash

# Script name: backup_home.sh
# Takes a daily snapshot of /home folder

SRC="/home"
DEST="/backups/home_$(date +%F).tar.gz"

# Creates a tar file
# gzip compression on the archive after it's created
tar -czf "$DEST" "$SRC"

echo "Backup complete at: $DEST"
