param(
  [string]$TenantId = "lab.keepcove.com",
  [string]$PayloadPath = "resources/resource-2-scim-sample-payloads/privileged-user-keepcove.json"
)

$spId = "626172aa-1511-4151-bfe1-4b2ad668f77e"
$jobId = "API2AAD.8f87362b5dd345dda667cbff144e3863.7ada0b78-05d2-467a-a6c3-1cb6d687762b"

Connect-MgGraph -TenantId $TenantId -Scopes "SynchronizationData-User.Upload" -NoWelcome

$uri = "https://graph.microsoft.com/v1.0/servicePrincipals/$spId/synchronization/jobs/$jobId/bulkUpload"
$body = Get-Content $PayloadPath -Raw

Invoke-MgGraphRequest `
  -Method POST `
  -Uri $uri `
  -Body $body `
  -ContentType "application/scim+json" `
  -StatusCodeVariable status `
  -ResponseHeadersVariable headers | Out-Null

[pscustomobject]@{
  Status = $status
  Location = $headers.Location
}