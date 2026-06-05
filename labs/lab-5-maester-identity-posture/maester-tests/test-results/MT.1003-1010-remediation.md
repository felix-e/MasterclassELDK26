# MT.1003-MT.1010 Remediation: Conditional Access Baseline

Source files reviewed:

- `TestResults-2026-06-05-155315.json`
- `TestResults-2026-06-05-155315.html`
- `TestResults-2026-06-05-155315.md`

## Summary

The failed high severity Maester checks are all Conditional Access baseline controls.

| Test | Finding | Main fix |
|---|---|---|
| MT.1003 | No enabled CA policy scoped to **All Apps** | Create/enable an All Apps CA policy |
| MT.1004 | No enabled CA policy scoped to **All Apps + All Users** | Create/enable an All Apps + All Users policy |
| MT.1005 | Not all CA policies exclude configured break-glass accounts | Add configured emergency accounts to CA exclusions |
| MT.1006 | No enabled CA policy requiring MFA for admins | Create/enable MFA policy for admins, or All Users MFA policy |
| MT.1007 | No enabled CA policy requiring MFA for all users | Create/enable All Users MFA policy |
| MT.1008 | No enabled CA policy requiring MFA for Azure management | Include Azure management/Admin portals or All Apps in MFA policy |
| MT.1009 | No enabled CA policy blocking legacy auth for `other` clients | Create/enable legacy auth block policy |
| MT.1010 | No enabled CA policy blocking legacy auth for Exchange ActiveSync | Include `exchangeActiveSync` in legacy auth block policy |

> Important: Maester checks these controls against policies with `state = enabled`. Existing policies in **Report-only** usually do **not** satisfy these tests.

## Detailed findings from the test result

The local Maester result shows these failures:

```text
MT.1003 Expected $true, because there is no policy scoped to All Apps, but got $false.
MT.1004 Expected $true, because there is no policy scoped to All Apps and All Users, but got $false.
MT.1005 Expected $true, because there is no emergency access account or group present in all enabled policies, but got $false.
MT.1006 Expected $true, because there is no policy that requires MFA for admins, but got $false.
MT.1007 Expected $true, because there is no policy that requires MFA for all users, but got $false.
MT.1008 Expected $true, because there is no policy that requires MFA for Azure management, but got $false.
MT.1009 Expected $true, because there is no policy that blocks legacy authentication, but got $false.
MT.1010 Expected $true, because there is no policy that blocks legacy authentication for Exchange ActiveSync, but got $false.
```

## Graph findings

Graph read-only review found 16 Conditional Access policies.

Several policies are close to satisfying the baseline but are in `enabledForReportingButNotEnforced`, so Maester does not count them for these checks.

Examples:

- `Require multifactor authentication for admins` - report-only, all apps, MFA, admin roles
- `Require multifactor authentication for admins 111` - report-only, all apps, MFA, admin roles
- `Require multifactor authentication for admins 222` - report-only, all apps, MFA, admin roles
- `Require multifactor authentication 333` - report-only, all apps, MFA, admin roles
- `Require multifactor authentication 444` - report-only, all apps, MFA, admin roles

Configured emergency access accounts in `maester-config.json`:

```text
d817a28c-50c5-4e14-99b5-b83dd5853790
70ea042f-a152-4322-b505-2878d2a804f5
```

Many existing CA policies do not exclude both configured emergency accounts, causing MT.1005 to fail.

## Recommended remediation approach

Use two baseline policies plus one cleanup step:

1. Add both configured emergency accounts to exclusions on all applicable CA policies.
2. Create or enable an **All Users + All Apps MFA** policy.
   - This can satisfy MT.1003, MT.1004, MT.1006, MT.1007, and MT.1008.
3. Create or enable a **Block legacy authentication** policy.
   - This can satisfy MT.1009 and MT.1010.

## UX steps

### Step 1: Add break-glass exclusions to all CA policies

1. Open **Microsoft Entra admin center**.
2. Go to **Protection → Conditional Access → Policies**.
3. For each Conditional Access policy:
   - Open the policy.
   - Go to **Users**.
   - Under **Exclude**, add both emergency/break-glass accounts:

     ```text
     d817a28c-50c5-4e14-99b5-b83dd5853790
     70ea042f-a152-4322-b505-2878d2a804f5
     ```

   - Save the policy.

This addresses MT.1005.

### Step 2: Create baseline MFA policy for All Users and All Apps

1. Go to **Protection → Conditional Access → Policies**.
2. Select **New policy**.
3. Name:

   ```text
   Baseline - Require MFA for all users - all cloud apps
   ```

4. Configure **Users**:
   - Include: **All users**
   - Exclude: both emergency/break-glass accounts

5. Configure **Target resources**:
   - Include: **All resources / All cloud apps**

6. Configure **Grant**:
   - Grant access
   - Require **multifactor authentication**

7. Configure **Session** if desired:
   - Sign-in frequency: Every time, or your tenant standard

8. Start with **Report-only** for validation.
9. After validation, set the policy to **On**.

This addresses MT.1003, MT.1004, MT.1006, MT.1007, and MT.1008 once enabled.

### Step 3: Create legacy authentication block policy

1. Go to **Protection → Conditional Access → Policies**.
2. Select **New policy**.
3. Name:

   ```text
   Baseline - Block legacy authentication
   ```

4. Configure **Users**:
   - Include: **All users**
   - Exclude: both emergency/break-glass accounts

5. Configure **Target resources**:
   - Include: **All resources / All cloud apps**

6. Configure **Conditions → Client apps**:
   - Configure: **Yes**
   - Select legacy clients:
     - **Exchange ActiveSync clients**
     - **Other clients**

7. Configure **Grant**:
   - **Block access**

8. Start with **Report-only** for validation.
9. After validation, set the policy to **On**.

This addresses MT.1009 and MT.1010 once enabled.

## PowerShell / Microsoft Graph commands

> These commands are intentionally written to create policies in `enabledForReportingButNotEnforced` first. Maester will only pass once the policy state is changed to `enabled`.

### Connect

```powershell
Connect-MgGraph -Scopes "Policy.Read.All", "Policy.ReadWrite.ConditionalAccess"
```

### Backup current CA policies

```powershell
$backupPath = ".\conditional-access-backup-$(Get-Date -Format yyyyMMdd-HHmmss).json"
Get-MgIdentityConditionalAccessPolicy -All |
  ConvertTo-Json -Depth 50 |
  Out-File -FilePath $backupPath -Encoding utf8

Write-Host "Backup written to $backupPath"
```

### Add configured emergency accounts to all CA policy exclusions

```powershell
$EmergencyAccessUserIds = @(
  "d817a28c-50c5-4e14-99b5-b83dd5853790",
  "70ea042f-a152-4322-b505-2878d2a804f5"
)

$policies = Get-MgIdentityConditionalAccessPolicy -All

foreach ($policy in $policies) {
    $conditions = $policy.Conditions | ConvertTo-Json -Depth 50 | ConvertFrom-Json

    if (-not $conditions.users) {
        Write-Warning "Skipping $($policy.DisplayName): no users condition found"
        continue
    }

    $existingExclusions = @($conditions.users.excludeUsers)
    $mergedExclusions = @($existingExclusions + $EmergencyAccessUserIds | Select-Object -Unique)
    $conditions.users.excludeUsers = $mergedExclusions

    $body = @{
        conditions = $conditions
    }

    Update-MgIdentityConditionalAccessPolicy `
      -ConditionalAccessPolicyId $policy.Id `
      -BodyParameter $body

    Write-Host "Updated emergency exclusions for: $($policy.DisplayName)"
}
```

### Create All Users + All Apps MFA baseline policy

```powershell
$EmergencyAccessUserIds = @(
  "d817a28c-50c5-4e14-99b5-b83dd5853790",
  "70ea042f-a152-4322-b505-2878d2a804f5"
)

$params = @{
    displayName = "Baseline - Require MFA for all users - all cloud apps"
    state       = "enabledForReportingButNotEnforced" # change to enabled after validation
    conditions  = @{
        users = @{
            includeUsers = @("All")
            excludeUsers = $EmergencyAccessUserIds
        }
        applications = @{
            includeApplications = @("All")
        }
        clientAppTypes = @("all")
    }
    grantControls = @{
        operator        = "OR"
        builtInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params
```

### Create legacy authentication block policy

```powershell
$EmergencyAccessUserIds = @(
  "d817a28c-50c5-4e14-99b5-b83dd5853790",
  "70ea042f-a152-4322-b505-2878d2a804f5"
)

$params = @{
    displayName = "Baseline - Block legacy authentication"
    state       = "enabledForReportingButNotEnforced" # change to enabled after validation
    conditions  = @{
        users = @{
            includeUsers = @("All")
            excludeUsers = $EmergencyAccessUserIds
        }
        applications = @{
            includeApplications = @("All")
        }
        clientAppTypes = @(
            "exchangeActiveSync",
            "other"
        )
    }
    grantControls = @{
        operator        = "OR"
        builtInControls = @("block")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params
```

### Enable policies after validation

After validating sign-in logs and report-only impact, enable the new baseline policies.

```powershell
Get-MgIdentityConditionalAccessPolicy -All |
  Where-Object { $_.DisplayName -in @(
    "Baseline - Require MFA for all users - all cloud apps",
    "Baseline - Block legacy authentication"
  ) } |
  ForEach-Object {
    Update-MgIdentityConditionalAccessPolicy `
      -ConditionalAccessPolicyId $_.Id `
      -BodyParameter @{ state = "enabled" }

    Write-Host "Enabled: $($_.DisplayName)"
  }
```

## Optional: enable an existing admin MFA policy instead of creating another

Existing report-only admin MFA policies already look close to satisfying MT.1006 and MT.1008. If you prefer to reuse one, first ensure it excludes both configured emergency accounts, then enable it.

Example:

```powershell
Update-MgIdentityConditionalAccessPolicy `
  -ConditionalAccessPolicyId "60963524-cd6a-4d78-a819-7e621b8970f8" `
  -BodyParameter @{ state = "enabled" }
```

However, the new **All Users + All Apps MFA** policy is simpler because it can satisfy MT.1003, MT.1004, MT.1006, MT.1007, and MT.1008 together.

## Re-test

After applying the changes and enabling the baseline policies, rerun Maester:

```powershell
Invoke-Maester -Path .\maester-tests -OutputFolder .\maester-tests\test-results
```

Or rerun the specific tests if preferred:

```powershell
Invoke-Maester -Path .\maester-tests -Tag MT.1003,MT.1004,MT.1005,MT.1006,MT.1007,MT.1008,MT.1009,MT.1010
```
