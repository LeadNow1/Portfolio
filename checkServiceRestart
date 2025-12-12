#!/bin/bash

# Script name: check_service.sh
# Usage: ./check_service.sh serviceName
# Checks if a service is active, and automatically restart it if it’s down

SERVICE=$1

if ! systemctl is-active --quiet "$SERVICE"; then
    echo "$SERVICE is down. Restarting..."
    systemctl restart "$SERVICE"
else
    echo "$SERVICE is running."
fi
