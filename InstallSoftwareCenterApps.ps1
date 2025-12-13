<#
.SYNOPSIS
Installs multiple applications from Software Center (SCCM / MECM)

Script name: InstallSoftwareCenterApps.ps1

.DESCRIPTION
Accepts 3–5 application names as arguments and triggers installation
through the SCCM client on Windows 11.

.EXAMPLE
.\Install-SoftwareCenterApps.ps1 "Google Chrome" "7-Zip" "Visual Studio Code" “Global Protect” “Pull Print”

.NOTES
Common Issues & Fixes
- App not found: Name must match Software Center exactly
- Access denied: Run PowerShell as Administrator
- Nothing happens: App not deployed to user/device
- SCCM namespace missing: Client not installed
#>

# “param” allows the script to accept values (app names) as arguments
# [string[]] means list of text values for the app names
param (
    [Parameter(Mandatory = $true)]
    [string[]]$AppNames
)

# Validate the number of apps
# Count checks how many app names were passed in to ensure it’s between 3 and 5 apps
if ($AppNames.Count -lt 3 -or $AppNames.Count -gt 5) {
    Write-Host "Please specify between 3 and 5 application names." -ForegroundColor Yellow
    exit 1
}

# Ensure script is running as Administrator to be able to install
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "`nStarting Software Center installations...`n" -ForegroundColor Cyan

# Loop through each app name provided
# foreach ($item in $list) { }
foreach ($AppName in $AppNames) {

    Write-Host "Searching for application: $AppName"

    # Query Software Center catalog for the app, Same source the GUI uses
    # ‘ means to continue as one line
    # Get-CimInstance -Namespace root\ccm\clientSDK
    $Application = Get-CimInstance `
         # - root\ccm\clientSDK is where SCCM stores Software Center info
        -Namespace "root\ccm\clientSDK" `
        # - CCM_Application represents Software Center applications
        -ClassName "CCM_Application" `
        # Pipe | passes output to next command, Similar to Bash pipes
        # $_.varName is the current object in the loop
        | Where-Object { $_.Name -eq $AppName }

    # Check if the app exists
    if ($null -eq $Application) {
        Write-Host "Application not found in Software Center: $AppName" 
        continue   # Skip to next app in the list
    }

    # If app name is found, install the app
    Write-Host "✔ Found $AppName. Triggering install..." -ForegroundColor Green

    # Trigger installation of the apps (same as clicking Install in Software Center)
    # Fully supported by MECM
    Invoke-CimMethod `
        -Namespace "root\ccm\clientSDK" `
        -ClassName "CCM_Application" `
        -MethodName "Install" `
        -Arguments @{
            Id                = $Application.Id
            IsMachineTarget   = $Application.IsMachineTarget
            Revision          = $Application.Revision
            EnforcePreference = 0
        }

    Write-Host "➡ Install request sent for: $AppName`n" -ForegroundColor Cyan
}

Write-Host "All installation requests have been submitted to Software Center." -ForegroundColor Green
