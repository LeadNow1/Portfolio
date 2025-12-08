<#
.What the script does:
Offboards a user from Azure AD / Microsoft 365 by performing access removal tasks.
#>

# ---------------------------
# 1. Connect to Microsoft Graph
# ---------------------------
Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All","Mail.ReadWrite","Mail.Send" -ErrorAction Stop


# ---------------------------
# 2. Ask for the User Principal Name (email)
# ---------------------------
$UPN = Read-Host "Enter the user's email (UPN) to offboard"

# Get the user object
$user = Get-MgUser -UserId $UPN -ErrorAction Stop


# ---------------------------
# 3. Disable user sign-in
# ---------------------------
Write-Host "Disabling user sign-in..."
Update-MgUser -UserId $UPN -AccountEnabled:$false


# ---------------------------
# 4. Reset password (optional but common)
# ---------------------------
$newPassword = "TempPassword123!"  # You can change this
Update-MgUser -UserId $UPN -PasswordProfile @{ ForceChangePasswordNextSignIn = $true; Password = $newPassword }


# ---------------------------
# 5. Revoke all user sessions (immediate sign-out)
# ---------------------------
Write-Host "Revoking user sessions..."
Invoke-MgInvalidateUserRefreshToken -UserId $UPN


# ---------------------------
# 6. Remove user from all Microsoft 365 Groups
# ---------------------------
Write-Host "Removing user from all groups..."
$groups = Get-MgUserMemberOf -UserId $UPN

foreach ($group in $groups) {
    if ($group.AdditionalProperties['groupTypes']) {
        Remove-MgGroupMember -GroupId $group.Id -MemberId $user.Id -ErrorAction SilentlyContinue
    }
}


# ---------------------------
# 7. Remove Azure AD Assigned Licenses
# ---------------------------
Write-Host "Removing licenses..."
$assignedLicenses = $user.AssignedLicenses
Update-MgUserLicense -UserId $UPN -RemoveLicenses $assignedLicenses.SkuId -AddLicenses @()


# ---------------------------
# 8. Convert mailbox to shared (Exchange)
# ---------------------------
Write-Host "Converting mailbox to shared (if applicable)..."
Set-Mailbox -Identity $UPN -Type Shared


# ---------------------------
# 9. Forward email to a manager (edit this)
# ---------------------------
$ManagerEmail = Read-Host "Enter manager email for mail forwarding"
Write-Host "Setting mail forwarding..."
Set-Mailbox -Identity $UPN -ForwardingSMTPAddress $ManagerEmail -DeliverToMailboxAndForward $true


# ---------------------------
# 10. Set Auto-Reply Out-of-Office Message
# ---------------------------
Write-Host "Setting auto-reply..."
Set-MailboxAutoReplyConfiguration -Identity $UPN -AutoReplyState Enabled `
    -InternalMessage "User has left the company." `
    -ExternalMessage "User has left the company."


# ---------------------------
# Done
# ---------------------------
Write-Host "Offboarding Completed Successfully!"
