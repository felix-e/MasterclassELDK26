# Connect to Microsoft Graph with permissions needed to:
# - read service principals
# - assign Microsoft Graph application permissions
# - assign Entra directory roles
Connect-MgGraph -Scopes `
  "Application.Read.All",
  "AppRoleAssignment.ReadWrite.All",
  "RoleManagement.ReadWrite.Directory"

# Paste the Object ID from:
# Logic App → Identity → System assigned → Object ID
# $miId = "7a8a4bd9-3167-42be-9008-4e5cfce0c37a"

# real managed identity object id for lab "entraLabInstance"
$miId = "63d776b5-daec-424c-8eaf-214c4d546a87"

# Retrieve the service principal object for the Logic App's managed identity
$mi = Get-MgServicePrincipal -ServicePrincipalId $miId

# Confirm Graph found the managed identity correctly
$mi | Select Id, DisplayName, AppId

# Retrieve the Microsoft Graph service principal
# AppId 00000003-0000-0000-c000-000000000000 is always Microsoft Graph
$graphApp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Define the Microsoft Graph application permissions required by the lab
$graphScopes = @(
  "User.ReadWrite.All"
  "SynchronizationData-User.Upload"
  "AuditLog.Read.All"
  "Mail.Send"
  "EntitlementManagement.ReadWrite.All"
  "RoleManagement.ReadWrite.Directory"
  "Application.Read.All"
)

# Loop through each required Graph permission
foreach ($scope in $graphScopes) {

  # Find the matching Graph app role object for this permission
  $role = $graphApp.AppRoles | Where-Object Value -eq $scope

  # Stop if the permission name is invalid or not found
  if (-not $role) {
    throw "Graph app role not found: $scope"
  }

  # Check whether this permission has already been assigned to the managed identity
  $existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mi.Id |
    Where-Object {
      $_.AppRoleId -eq $role.Id -and
      $_.ResourceId -eq $graphApp.Id
    }

  # Assign the permission only if it is not already assigned
  if (-not $existing) {
    New-MgServicePrincipalAppRoleAssignment `
      -ServicePrincipalId $mi.Id `
      -PrincipalId $mi.Id `
      -ResourceId $graphApp.Id `
      -AppRoleId $role.Id
  }
  else {
    "Already assigned: $scope"
  }
}





# verify
$mi.Id
$mi.DisplayName

$required = @(
  "User.ReadWrite.All",
  "SynchronizationData-User.Upload",
  "AuditLog.Read.All",
  "Mail.Send",
  "EntitlementManagement.ReadWrite.All",
  "RoleManagement.ReadWrite.Directory",
  "Application.Read.All"
)

$assigned = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mi.Id -All |
  Where-Object ResourceId -eq $graphApp.Id |
  ForEach-Object {
    ($graphApp.AppRoles | Where-Object Id -eq $_.AppRoleId).Value
  }

$required | ForEach-Object {
  [pscustomobject]@{
    Permission = $_
    Assigned = $_ -in $assigned
  }
}




# verify again
Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mi.Id -All |
  Where-Object ResourceId -eq $graphApp.Id |
  ForEach-Object {
    ($graphApp.AppRoles | Where-Object Id -eq $_.AppRoleId).Value
  } | Sort-Object




# Test the "SynchronizationData-User.Upload" permission by uploading a privileged user via the SCIM API

Connect-MgGraph -TenantId lab.keepcove.com -Scopes "SynchronizationData-User.Upload"

$uri = "https://graph.microsoft.com/v1.0/servicePrincipals/626172aa-1511-4151-bfe1-4b2ad668f77e/synchronization/jobs/API2AAD.8f87362b5dd345dda667cbff144e3863.7ada0b78-05d2-467a-a6c3-1cb6d687762b/bulkUpload"
$body = Get-Content "resources/resource-2-scim-sample-payloads/privileged-user-keepcove.json" -Raw

Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType "application/scim+json"




./invoke-ScimBulkUpload.ps1 `
  -PayloadPath "../../resources/resource-2-scim-sample-payloads/privileged-user-keepcove.json" |
  ConvertTo-Json -Depth 10 |
  fx