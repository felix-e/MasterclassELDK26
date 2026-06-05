# Maester Testing Categories Guide

## Question

Can you explain the commonality and differences of these testing categories? How should I use them?

## Short answer

The Maester test folders are different lenses over Microsoft 365, Entra ID, identity, security, and compliance posture.

They overlap, but they are not duplicates:

- **Maester** is practical operational security posture.
- **CIS** is benchmark compliance.
- **CISA / SCuBA** is secure configuration baseline guidance, especially useful for public-sector-style assurance.
- **EIDSCA** is deep Entra ID configuration analysis.
- **ORCA** is Exchange Online/email security posture.
- **XSPM** is exposure/security posture management around critical assets, identities, and devices.
- **Custom** is where you add organisation-specific checks.

## Commonality

All categories are:

- Automated security posture checks.
- Mostly read-only validation.
- Useful for identifying misconfiguration and missing controls.
- Useful for before/after remediation evidence.
- Useful for audit, compliance, and operational reporting.
- Often overlapping: one good configuration can satisfy multiple categories.

Example: a well-designed Conditional Access policy that targets all users/all apps, requires MFA, blocks legacy authentication, and excludes break-glass accounts can help satisfy Maester, CIS, and CISA-style checks.

## Differences

| Category | What it is | Best use |
|---|---|---|
| **Maester** | Community/Maester team tests for Microsoft 365, Entra ID, Intune, Defender, Exchange, Teams, Azure, AI Agents, and related services | Practical tenant hardening and day-to-day posture checks |
| **CIS** | Tests based on the Center for Internet Security Microsoft 365 Benchmark | Formal benchmark alignment and audit-style evidence |
| **CISA / SCuBA** | Tests based on CISA Secure Cloud Business Applications baselines | Strong secure configuration baseline, useful for government/public-sector-style posture |
| **EIDSCA** | Entra ID Security Config Analyzer tests | Deep Entra ID configuration review, especially authentication methods, consent, password/auth settings |
| **ORCA** | Exchange Online Protection and Defender for Office 365 configuration checks | Email security: anti-spam, anti-phish, Safe Links, Safe Attachments, DKIM, DMARC, SMTP AUTH |
| **XSPM** | Exposure/security posture management style tests | Critical assets, privileged identities, devices, and attack-path-style posture |
| **Custom** | Your own Pester tests | Organisation-specific controls, lab validation, and custom evidence |

## How to use them

### 1. Use Maester as the operational baseline

Start with the **Maester** category for practical Microsoft 365 and Entra hardening.

Focus first on:

- Critical findings.
- High findings.
- Conditional Access failures.
- Identity and privileged access failures.
- Authentication method failures.

Example command:

```powershell
Invoke-Maester -Path .\maester-tests
```

### 2. Use CIS for benchmark alignment

Use **CIS** when you want to explain posture in formal benchmark language.

This is useful for:

- Compliance mapping.
- Management reporting.
- Audit evidence.
- Showing alignment to a recognised security benchmark.

### 3. Use CISA / SCuBA for strong secure configuration guidance

Use **CISA / SCuBA** when you want a stricter security baseline.

This is especially useful for:

- Public-sector-style environments.
- University or institutional environments.
- Strong identity and email hardening.
- Security uplift programs.

### 4. Use EIDSCA for Entra ID depth

Use **EIDSCA** when your focus is Microsoft Entra ID configuration.

Good focus areas:

- Authentication methods.
- FIDO2 / passkeys.
- Microsoft Authenticator settings.
- Temporary Access Pass.
- SMS and voice restrictions.
- User consent and admin consent.
- Password and authorization settings.

### 5. Use ORCA for Exchange/email security

Use **ORCA** when focusing on Exchange Online and Defender for Office 365.

Good focus areas:

- DKIM.
- DMARC.
- SPF.
- Safe Links.
- Safe Attachments.
- Anti-phishing.
- Anti-malware.
- Spam filtering.
- SMTP AUTH.
- External forwarding.

### 6. Use XSPM for exposure and attack-path thinking

Use **XSPM** when focusing on security exposure rather than just configuration.

Good focus areas:

- Critical assets.
- Privileged identities.
- Device risk.
- Credential exposure.
- Attack path reduction.

### 7. Use Custom tests for local or job-specific requirements

Use **Custom** when the built-in tests do not cover your specific control.

Examples:

- A named break-glass account must be excluded from all CA policies.
- A specific privileged group must be protected.
- A specific enterprise app must use SAML/OIDC correctly.
- A certificate or client secret must not expire within 30 days.
- A lab control must be validated repeatedly.

## Recommended workflow

### Step 1: Run full test suite

```powershell
Invoke-Maester -Path .\maester-tests -OutputFolder .\maester-tests\test-results
```

### Step 2: Triage by severity

Prioritise in this order:

1. Critical.
2. High.
3. Medium.
4. Low.
5. Info.

### Step 3: Group by remediation theme

Do not fix test-by-test blindly. Group failures by theme.

Useful themes:

- Conditional Access.
- Break-glass/emergency access.
- MFA and authentication methods.
- Legacy authentication.
- Privileged access.
- App registrations and consent.
- Email security.
- Device compliance.
- Identity Governance.

### Step 4: Fix once, satisfy many

One remediation can satisfy many tests.

Example:

A baseline Conditional Access policy with:

- All users.
- All apps.
- MFA required.
- Break-glass exclusions.
- Report-only first, then enabled.

Can help with:

- MT.1003.
- MT.1004.
- MT.1006.
- MT.1007.
- MT.1008.
- Related CIS/CISA controls.

### Step 5: Document before/after evidence

For each meaningful remediation, capture:

- Failed test ID.
- Risk.
- Existing finding.
- UX remediation steps.
- PowerShell/Graph remediation commands.
- Retest result.

### Step 6: Re-run targeted tests

After remediation, rerun the relevant tests.

Example:

```powershell
Invoke-Maester -Path .\maester-tests -Tag MT.1003,MT.1004,MT.1005,MT.1006,MT.1007,MT.1008,MT.1009,MT.1010
```

## How this applies to UNSW job-readiness

For the UNSW Senior Identity Engineer role, use the categories as a job-readiness lab rather than just a compliance checklist.

Recommended priority:

1. **Maester / Entra / Conditional Access**
   - Conditional Access design.
   - MFA.
   - break-glass exclusions.
   - legacy authentication blocking.
   - Azure management protection.
   - user risk vs sign-in risk.

2. **EIDSCA**
   - Authentication methods.
   - Passkeys/FIDO2.
   - Windows Hello for Business readiness concepts.
   - Temporary Access Pass.
   - Authenticator configuration.

3. **Maester app and identity tests**
   - App registrations.
   - Enterprise apps.
   - privileged API permissions.
   - app owners.
   - consent configuration.

4. **Identity Governance-related tests**
   - Access packages.
   - access reviews.
   - stale assignments.
   - deleted resources.
   - approver validity.

5. **PAM and privileged identity tests**
   - Global Admin count.
   - permanent privileged role assignments.
   - privileged users.
   - service principals with privileged access.

6. **ORCA / Exchange security**
   - Email protection controls.
   - DKIM/DMARC/SPF.
   - Safe Links/Safe Attachments.
   - SMTP AUTH.

## Practical takeaway

Use the test categories like this:

```text
Maester = operational Microsoft 365 security health
CIS     = benchmark compliance
CISA    = secure configuration baseline
EIDSCA  = deep Entra ID configuration
ORCA    = Exchange/email security
XSPM    = exposure and attack-path posture
Custom  = your own organisation/lab/job-specific checks
```

For the next two weeks, the most useful focus is:

```text
Conditional Access + Authentication Methods + App Onboarding + Identity Governance + PAM + operational evidence
```
