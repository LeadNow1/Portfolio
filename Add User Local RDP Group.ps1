# This script adds the Active Directory user or group directly to the local "Remote Desktop Users" group on the machine

# 1. Add an AD user to the local Remote Desktop Users group
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "DOMAIN\username"

# 2. Add an AD security group instead of individual users for easier management
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "DOMAIN\GroupName"

# 3. Verify group membership after adding
Get-LocalGroupMember -Group "Remote Desktop Users"


<#
When you add an AD account or group to the local group, the membership is stored in the 
local SAM database but references the AD object. 
As long as the computer remains joined to the domain and the AD object exists, the membership survives reboots.
#>
