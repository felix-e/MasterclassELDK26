# Agent Blueprint cleanup

PowerShell command block to safely delete Agent Identity Blueprints only when they have no child Agent Identities.

```powershell
Connect-MgGraph -Scopes `
  Application.ReadWrite.All, `
  Application.Read.All, `
  AgentIdentity.Read.All

# ObjID
$blueprintAppIds = @(
  "834d93f3-6a6d-4d41-8a97-54d8537c8897",
  "e5d52af3-e641-41ef-9f9d-17f5d4fc54b7"
)

# AppID
$blueprintAppIds = @(
  "de8b50ee-9df8-4840-af6f-ce606af0322d",
  "29b2a151-43de-4587-be99-1a83e0c269eb"
)

foreach ($bpAppId in $blueprintAppIds) {
  Write-Host "`nChecking blueprint appId: $bpAppId"

  # Find blueprint application object
  $bpApp = Invoke-MgGraphRequest `
    -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/applications(appId='$bpAppId')"

  if (-not $bpApp.id) {
    Write-Warning "No application found for appId $bpAppId"
    continue
  }

  # Check child Agent Identities
  $agentIdentities = Invoke-MgGraphRequest `
    -Method GET `
    -Uri "https://graph.microsoft.com/beta/servicePrincipals/microsoft.graph.agentIdentity?`$filter=agentIdentityBlueprintId eq '$bpAppId'&`$select=id,displayName,agentIdentityBlueprintId"

  $count = @($agentIdentities.value).Count

  if ($count -gt 0) {
    Write-Warning "SKIPPING $bpAppId because it has $count Agent Identity/Identities:"
    $agentIdentities.value | Select-Object id, displayName, agentIdentityBlueprintId | Format-Table
    continue
  }

  Write-Host "No child Agent Identities found. Deleting blueprint application objectId: $($bpApp.id)"

  Invoke-MgGraphRequest `
    -Method DELETE `
    -Uri "https://graph.microsoft.com/v1.0/applications/$($bpApp.id)"

  Write-Host "Deleted blueprint $bpAppId"
}
```

## What happens if a blueprint with Agent Identities is deleted?

Deleting an Agent Identity Blueprint triggers cascade cleanup:

- The blueprint is soft deleted.
- The blueprint principal is cleaned up.
- Child Agent Identities are automatically soft deleted.
- Associated Agent User accounts may also be cleaned up.
- Deleted objects are recoverable for about 30 days.
- After cascade cleanup runs, restoring the blueprint does not automatically restore child Agent Identities; each child identity may need restoring separately.

Only delete a blueprint with Agent Identities if you intend to decommission those agents.
