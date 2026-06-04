# Logic App Managed Identity Permission Fixes

This note captures the two fixes needed when granting Microsoft Graph permissions to the Logic App user-assigned managed identity for Lab 2.

Managed identity in this lab:

```text
Name: entraLabInstance
Object / service principal ID: 63d776b5-daec-424c-8eaf-214c4d546a87
Application / client ID: 0243a124-994f-4e91-9276-f1229b863dcc
Resource ID: /subscriptions/41f018dd-427b-445f-9262-6b32b603662e/resourcegroups/entraLab/providers/Microsoft.ManagedIdentity/userAssignedIdentities/entraLabInstance
```

## Fix 1 - Add missing TAP Graph permission

`HTTP_-_Generate_TAP_for_admin` can fail with:

```text
403 accessDenied / Request Authorization failed
```

The managed identity already has several Graph app roles, but it also needs permission to create Temporary Access Pass methods.

Add this Microsoft Graph **application permission** to the managed identity:

```text
UserAuthMethod-TAP.ReadWrite.All
```

App role ID:

```text
627169a8-8c15-451c-861a-5b80e383de5c
```

### Recommended: grant with `az rest`

Run while signed in as an admin that can assign app roles / grant admin consent:

```powershell
$miSpId = "63d776b5-daec-424c-8eaf-214c4d546a87"
$tapAppRoleId = "627169a8-8c15-451c-861a-5b80e383de5c" # UserAuthMethod-TAP.ReadWrite.All

$graphSp = az rest --method get `
  --url "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '00000003-0000-0000-c000-000000000000'&`$select=id" `
  | ConvertFrom-Json

$graphSpId = $graphSp.value[0].id

$body = @{
  principalId = $miSpId
  resourceId  = $graphSpId
  appRoleId   = $tapAppRoleId
} | ConvertTo-Json

az rest --method post `
  --url "https://graph.microsoft.com/v1.0/servicePrincipals/$miSpId/appRoleAssignments" `
  --headers "Content-Type=application/json" `
  --body $body
```

Verify:

```powershell
az rest --method get `
  --url "https://graph.microsoft.com/v1.0/servicePrincipals/$miSpId/appRoleAssignments" `
  --query "value[].appRoleId" -o tsv
```

Look for:

```text
627169a8-8c15-451c-861a-5b80e383de5c
```

Wait a few minutes for permission/token propagation, then rerun the Logic App.

### If using `giveLogicAppMsGraphPermissionViaMI.ps1`

The MI ID in that script is already correct:

```powershell
$miId = "63d776b5-daec-424c-8eaf-214c4d546a87"
```

Add this permission to both `$graphScopes` and `$required`:

```powershell
"UserAuthMethod-TAP.ReadWrite.All"
```

Example `$graphScopes`:

```powershell
$graphScopes = @(
  "User.ReadWrite.All"
  "SynchronizationData-User.Upload"
  "AuditLog.Read.All"
  "Mail.Send"
  "EntitlementManagement.ReadWrite.All"
  "RoleManagement.ReadWrite.Directory"
  "Application.Read.All"
  "UserAuthMethod-TAP.ReadWrite.All"
)
```

## Fix 2 - Resolve Microsoft.Graph PowerShell module version clash

If PowerShell shows this error:

```text
Could not load file or assembly 'Microsoft.Graph.Authentication, Version=2.36.1.0'
Assembly with same name is already loaded
```

then mixed Microsoft Graph module versions are loaded/installed, for example `Microsoft.Graph.Authentication` 2.37.0 with `Microsoft.Graph.Applications` 2.36.1.

### Fast workaround

Do not use `Get-MgServicePrincipal` / `Import-Module Microsoft.Graph.Applications` for this fix. Use the `az rest` commands above instead.

### Clean module fix

Close all PowerShell sessions, open a fresh session, then reinstall matching Graph modules:

```powershell
Get-InstalledModule Microsoft.Graph* | Uninstall-Module -AllVersions -Force

Install-Module Microsoft.Graph -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Beta -Scope CurrentUser -Force
```

Close PowerShell again and open a new session before running Microsoft Graph PowerShell commands.

You can inspect installed versions with:

```powershell
Get-Module Microsoft.Graph* -ListAvailable |
  Select-Object Name, Version, Path |
  Sort-Object Name, Version
```

## Portal note

The managed identity is a service principal of type `ManagedIdentity` with display name `entraLabInstance`. In Enterprise Applications it may only appear after filtering application type to **Managed Identities**, or by searching for:

```text
Object ID: 63d776b5-daec-424c-8eaf-214c4d546a87
Application ID: 0243a124-994f-4e91-9276-f1229b863dcc
```

Adding Graph app roles to managed identities is often easier with Graph / `az rest` than through the portal UI.
