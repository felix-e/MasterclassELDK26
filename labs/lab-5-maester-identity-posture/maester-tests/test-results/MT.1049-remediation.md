# MT.1049 Remediation: Separate User Risk and Sign-in Risk Policies

## Summary

Maester test **MT.1049** checks that Microsoft Entra Conditional Access policies do **not** combine **User risk** and **Sign-in risk** in the same policy.

Conditional Access conditions are evaluated together. If both risk conditions are configured in one policy, the policy only applies when both conditions are true. That can leave a gap where a high-risk sign-in is allowed because the user risk is not also high.

Reference: <https://maester.dev/docs/tests/MT.1049/>

## Graph findings

Graph read-only query found **16 Conditional Access policies** and **2 risk-based policies**.

### Existing risk-based policies

| Policy | State | User risk | Sign-in risk | Action |
|---|---|---:|---:|---|
| `Require password change for high-risk users` | `enabledForReportingButNotEnforced` | `high` | none | Keep; this is the User Risk policy |
| `lowRiskToU` | `enabledForReportingButNotEnforced` | `low` | none | Review; likely lab/test policy |

### MT.1049-specific finding

No enabled policy was found with both `userRiskLevels` and `signInRiskLevels` configured.

The local Maester report showed the test result as **Error**, with this Maester exception:

```text
Parameter cannot be processed because the parameter name 'Error' is ambiguous.
```

So the MT.1049 result appears to be a Maester 2.1.0 test/runtime error rather than a confirmed policy misconfiguration.

## Recommended fix

Create the missing separate **Sign-in risk** Conditional Access policy. Keep the existing `Require password change for high-risk users` policy as the separate **User risk** policy.

## UX steps: create Sign-in risk policy

1. Open **Microsoft Entra admin center**.
2. Go to **Protection → Conditional Access → Policies**.
3. Select **New policy**.
4. Name the policy:

   ```text
   Require MFA for medium and high sign-in risk
   ```

5. Configure **Users**:
   - Include: **All users**
   - Exclude: break-glass accounts

   Existing break-glass/user-risk policy exclusions found:

   ```text
   d5d580bf-5d2a-48b1-9412-6bfa573858b4
   d817a28c-50c5-4e14-99b5-b83dd5853790
   ```

6. Configure **Target resources**:
   - Include: **All resources**

7. Configure **Conditions → Sign-in risk**:
   - Configure: **Yes**
   - Select: **Medium** and **High**

8. Configure **Grant**:
   - Grant access
   - Require **multifactor authentication** or an MFA authentication strength

9. Configure **Session**:
   - Sign-in frequency: **Every time**

10. Set policy state to **Report-only** first.
11. Validate impact.
12. Change policy state to **On** when ready.

## PowerShell: create Sign-in risk policy

```powershell
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess","Policy.Read.All"

$params = @{
    displayName = "Require MFA for medium and high sign-in risk"
    state       = "enabledForReportingButNotEnforced" # report-only
    conditions  = @{
        users = @{
            includeUsers = @("All")
            excludeUsers = @(
                "d5d580bf-5d2a-48b1-9412-6bfa573858b4",
                "d817a28c-50c5-4e14-99b5-b83dd5853790"
            )
        }
        applications = @{
            includeApplications = @("All")
        }
        signInRiskLevels = @("medium", "high")
    }
    grantControls = @{
        operator        = "OR"
        builtInControls = @("mfa")
    }
    sessionControls = @{
        signInFrequency = @{
            isEnabled          = $true
            frequencyInterval  = "everyTime"
            authenticationType = "primaryAndSecondaryAuthentication"
        }
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params
```

## Optional: turn the existing User Risk policy from Report-only to On

Only do this after validating report-only impact.

```powershell
Update-MgIdentityConditionalAccessPolicy `
  -ConditionalAccessPolicyId "7ca16262-b1a4-4692-8e07-fede99190205" `
  -BodyParameter @{ state = "enabled" }
```

## Optional: disable the likely lab/test policy

Disable first rather than deleting.

```powershell
Update-MgIdentityConditionalAccessPolicy `
  -ConditionalAccessPolicyId "8f25ef1d-7e5d-4270-a0f8-034b9346aeb2" `
  -BodyParameter @{ state = "disabled" }
```

## Re-test

After creating the sign-in risk policy, rerun Maester.

If MT.1049 still reports **Error** instead of Pass/Fail, update Maester and rerun because the current report indicates a Maester test exception.
