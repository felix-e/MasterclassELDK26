# Lab 2 Logic App / Entitlement Management Lessons Learned

This captures the troubleshooting path for getting `3ProvisionAdmin` working end-to-end.

## Final outcome

The full flow worked after correcting several tenant-specific hardcoded values, permissions, and provisioning timing issues.

Successful flow:

1. Entitlement Management custom extension triggers Logic App at `assignmentRequestGranted`.
2. Logic App provisions privileged admin account through API-driven inbound provisioning / SCIM bulk upload.
3. Logic App waits until the new admin account is readable in Graph.
4. Logic App patches the admin account `mail` value.
5. Logic App generates a Temporary Access Pass.
6. Logic App sends the TAP email to the requester.
7. Logic App resumes the access package assignment request.

## 1. A successful Logic App run does not mean provisioning ran

Initial run looked successful but no admin account was created.

Root cause: the outer Logic App `Condition` checked the wrong catalog ID.

Actual trigger payload catalog:

```text
bcf15229-8e85-429d-8d8b-124bda460da1
```

Workflow was checking:

```text
a6461768-60ea-4a25-9863-6ec4cba55e93
```

Because the outer condition was false, all provisioning actions were skipped, but the resume action still ran successfully.

Fix: update the outer `Condition`:

```json
"equals": [
  "@triggerBody()?['AccessPackageCatalog']?['Id']",
  "bcf15229-8e85-429d-8d8b-124bda460da1"
]
```

The inner stage condition was already correct:

```text
Stage == assignmentRequestGranted
```

## 2. Policy stage was not the issue

The access package policy did not require approval, but the custom extension was correctly configured for:

```text
Assignment is granted
```

The trigger payload confirmed:

```text
Stage: assignmentRequestGranted
```

So the skipped provisioning branch was caused by the catalog mismatch, not the policy stage.

## 3. Wrong provisioning service principal/job IDs caused tenant mismatch

Error:

```text
The service principal identifier c3f0a750-3a78-4507-a30f-36f3ea3479e4 specified in the request URL does not belong to the tenant authenticated
```

Root cause: `HTTP_-_Provision_admin_account` had a hardcoded service principal and sync job from another tenant.

Wrong URL:

```text
https://graph.microsoft.com/v1.0/servicePrincipals/c3f0a750-3a78-4507-a30f-36f3ea3479e4/synchronization/jobs/API2AAD.ad7aaf9de4784d3f99aace450535d9cc.7cbfb5f7-2635-4a01-b793-c4f646ae4a9f/bulkUpload
```

Correct tenant values:

```text
Service principal ID: 626172aa-1511-4151-bfe1-4b2ad668f77e
Display name: ELDK26 API-driven provisioning to Entra ID
Job ID: API2AAD.8f87362b5dd345dda667cbff144e3863.7ada0b78-05d2-467a-a6c3-1cb6d687762b
```

Correct URL:

```text
https://graph.microsoft.com/v1.0/servicePrincipals/626172aa-1511-4151-bfe1-4b2ad668f77e/synchronization/jobs/API2AAD.8f87362b5dd345dda667cbff144e3863.7ada0b78-05d2-467a-a6c3-1cb6d687762b/bulkUpload
```

Do not change the managed identity resource ID for this error. The issue is the target service principal/job in the URL.

## 4. Managed identity details

User-assigned managed identity used by Logic App:

```text
Name: entraLabInstance
Object / service principal ID: 63d776b5-daec-424c-8eaf-214c4d546a87
Application / client ID: 0243a124-994f-4e91-9276-f1229b863dcc
Resource ID: /subscriptions/41f018dd-427b-445f-9262-6b32b603662e/resourcegroups/entraLab/providers/Microsoft.ManagedIdentity/userAssignedIdentities/entraLabInstance
```

Graph confirmed it as:

```json
{
  "displayName": "entraLabInstance",
  "id": "63d776b5-daec-424c-8eaf-214c4d546a87",
  "appId": "0243a124-994f-4e91-9276-f1229b863dcc",
  "servicePrincipalType": "ManagedIdentity"
}
```

In Enterprise Applications, filter application type to **Managed Identities** or search by object ID / app ID.

## 5. UPN mapping caused PATCH/TAP actions to target the wrong user

The workflow originally generated:

```text
adm.holger.danske@felixelliottoutlookcom.onmicrosoft.com
```

But the provisioning API created:

```text
adm.holger.danske@lab.keepcove.com
```

Graph verified the created admin account:

```json
{
  "displayName": "Holger Danske - Admin",
  "employeeId": "A106",
  "userPrincipalName": "adm.holger.danske@lab.keepcove.com"
}
```

Fix `Compose_-_UserPrincipalName` by removing the replacement mapping.

Change from:

```text
adm.@{replace(body('Parse_JSON_-_Get_all_user_details')?['userPrincipalName'],'@lab.keepcove.com','@felixelliottoutlookcom.onmicrosoft.com')}
```

to:

```text
adm.@{body('Parse_JSON_-_Get_all_user_details')?['userPrincipalName']}
```

## 6. TAP generation needs a specific Graph app permission

`HTTP_-_Generate_TAP_for_admin` failed with:

```text
403 accessDenied / Request Authorization failed
```

Root cause: the managed identity had several Graph permissions but did not have TAP/auth method write permission.

Required permission:

```text
UserAuthMethod-TAP.ReadWrite.All
```

App role ID:

```text
627169a8-8c15-451c-861a-5b80e383de5c
```

Existing useful permissions on the managed identity included:

```text
SynchronizationData-User.Upload
User.ReadWrite.All
Mail.Send
EntitlementManagement.ReadWrite.All
RoleManagement.ReadWrite.Directory
AuditLog.Read.All
Application.Read.All
```

But TAP creation required the additional TAP auth method permission.

Also ensure Temporary Access Pass is enabled in the tenant Authentication Methods policy and targeted to the relevant users/groups.

## 7. TAP lifetime had to match policy

TAP generation originally used:

```json
"lifetimeInMinutes": 1440
```

This exceeded the tenant policy. Changing it to:

```json
"lifetimeInMinutes": 180
```

resolved that issue.

## 8. Microsoft.Graph PowerShell module version clash

PowerShell error:

```text
Could not load file or assembly 'Microsoft.Graph.Authentication, Version=2.36.1.0'
Assembly with same name is already loaded
```

Cause: mixed Microsoft Graph module versions in the same PowerShell environment.

Fast workaround: use `az rest` instead of `Get-MgServicePrincipal` / Microsoft Graph PowerShell modules.

Clean fix:

```powershell
Get-InstalledModule Microsoft.Graph* | Uninstall-Module -AllVersions -Force

Install-Module Microsoft.Graph -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Beta -Scope CurrentUser -Force
```

Then close and reopen PowerShell.

## 9. SCIM bulk upload can succeed before the user is immediately usable by Graph

`HTTP_-_Provision_admin_account` succeeded, but the following PATCH sometimes failed with:

```text
404 Request_ResourceNotFound
Resource 'adm.holger.danske@lab.keepcove.com' does not exist
```

The user existed shortly afterward, so this was a timing / eventual consistency issue.

Increasing the delay from 20 to 120 seconds still was not robust enough.

Fix: add a retry loop before `HTTP_-_Enable_Exchange_Online_plus_addressing`.

Added action:

```text
Until_-_Admin_user_exists_in_Graph
```

Flow:

```text
HTTP_-_Provision_admin_account
→ Delay_-_20_seconds, currently 120 sec
→ Until_-_Admin_user_exists_in_Graph
   → GET /beta/users/{adminUPN}
   → if 404/fail, wait 15 sec and retry
   → max 20 checks / 10 min
→ HTTP_-_Enable_Exchange_Online_plus_addressing
```

GET URI:

```text
https://graph.microsoft.com/beta/users/@{outputs('Compose_-_UserPrincipalName')}?$select=id,userPrincipalName,displayName,mail,employeeId
```

Until expression:

```text
@equals(outputs('HTTP_-_Check_admin_user_exists_in_Graph')?['statusCode'], 200)
```

## 10. sendMail had a hardcoded sender user ID from another tenant

`HTTP_-_Send_an_email` failed with:

```text
404 ErrorInvalidUser
The requested user '77ca8b96-893b-4f5b-a3f0-369beeaedf5a' is invalid.
```

Root cause: the sendMail URI used a hardcoded user ID that does not exist in this tenant.

Wrong URI:

```text
https://graph.microsoft.com/v1.0/users/77ca8b96-893b-4f5b-a3f0-369beeaedf5a/sendMail
```

Graph confirmed the correct sender account:

```json
{
  "displayName": "Felix Elliott",
  "id": "d5d580bf-5d2a-48b1-9412-6bfa573858b4",
  "mail": "admin@lab.keepcove.com",
  "userPrincipalName": "admin@lab.keepcove.com"
}
```

Fix by using the sender UPN:

```text
https://graph.microsoft.com/v1.0/users/admin@lab.keepcove.com/sendMail
```

Using UPN is easier to read and avoids copying tenant-specific object IDs.

## 11. Useful diagnostics commands

Check managed identity service principal:

```bash
az rest --method get \
  --url "https://graph.microsoft.com/v1.0/servicePrincipals/63d776b5-daec-424c-8eaf-214c4d546a87?\$select=id,displayName,appId,servicePrincipalType,alternativeNames" \
  -o json
```

Check Graph app role assignments on the managed identity:

```bash
az rest --method get \
  --url "https://graph.microsoft.com/v1.0/servicePrincipals/63d776b5-daec-424c-8eaf-214c4d546a87/appRoleAssignments?\$select=id,resourceDisplayName,appRoleId,principalDisplayName" \
  -o json
```

Check provisioning service principal:

```bash
az rest --method get \
  --url "https://graph.microsoft.com/v1.0/servicePrincipals/626172aa-1511-4151-bfe1-4b2ad668f77e?\$select=id,displayName,appId" \
  -o json
```

Check sync job:

```bash
az rest --method get \
  --url "https://graph.microsoft.com/v1.0/servicePrincipals/626172aa-1511-4151-bfe1-4b2ad668f77e/synchronization/jobs/API2AAD.8f87362b5dd345dda667cbff144e3863.7ada0b78-05d2-467a-a6c3-1cb6d687762b" \
  -o json
```

Check created admin user:

```bash
az rest --method get \
  --url "https://graph.microsoft.com/beta/users/adm.holger.danske@lab.keepcove.com?\$select=id,userPrincipalName,displayName,mail,employeeId,createdDateTime" \
  -o json
```

Check sender account:

```bash
az rest --method get \
  --url "https://graph.microsoft.com/v1.0/users/admin@lab.keepcove.com?\$select=id,userPrincipalName,displayName,mail" \
  -o json
```

## 12. Official Microsoft docs used

Relevant official docs loaded during troubleshooting:

- Microsoft Learn: Trigger Logic Apps with custom extensions in entitlement management
- Microsoft Graph: `accessPackageAssignmentRequest: resume`
- Microsoft Graph: `accessPackageAssignmentWorkflowExtension` resource type
- Microsoft Learn: Best practices for securing custom extension extensibility to Azure Logic Apps
- Microsoft Graph: Create `temporaryAccessPassAuthenticationMethod`

Important official-doc-backed points:

- New custom extensions use `Proof-of-possession` token security; this is normal.
- `/resume` is only valid while the request is waiting for callback.
- Launch-and-wait custom extensions pause the entitlement workflow until resume is called.
- For TAP creation, Graph auth method write permissions are required.
- When using Logic Apps to resume, Microsoft docs recommend disabling the HTTP async pattern.
