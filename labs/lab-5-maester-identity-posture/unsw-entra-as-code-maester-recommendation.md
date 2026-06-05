# UNSW-fit recommendation: Entra-as-Code + Maester

This note captures the recommended Maester/IaC approach for the UNSW Senior Identity Engineer context, based on the Maester monitoring options and the UNSW interview/recruiter transcripts.

## Executive recommendation

For UNSW, the best-fit pattern is not simply “run Maester somewhere”. The stronger architecture is:

```text
Identity change as code
  + pull request review
  + Terraform plan/diff
  + Maester validation
  + approval/CAB evidence
  + controlled promotion
  + scheduled posture monitoring
```

Recommended implementation:

> **Terraform-led Entra-as-Code + Azure DevOps pipeline + Maester as both change gate and continuous posture monitor**

Optional phase 2:

> **Azure DevOps & Azure Web App** if UNSW wants a stakeholder-friendly Maester report portal protected by Entra ID.

## Why this fits UNSW

The interview transcript suggests UNSW’s identity estate is complex, hybrid, operationally busy, and currently still has manual change patterns.

Key current-estate signals from the transcript:

- The role sits in the **Enterprise Identity Team** inside Cyber / IT.
- The team manages identity systems from **identity governance through access management**.
- Joiner provisioning is largely automated:
  - staff source: **HR system**
  - student source: **student admin system**
  - provisioning system: **MidPoint and OneGate**
  - accounts created in **Active Directory**
  - **Entra ID Connect** syncs AD accounts to **Entra ID**
- UNSW has many personas, but a relatively clear source-of-truth model: HR + student admin.
- They support **Delinea PAM**.
- They currently maintain **MidPoint** themselves:
  - build connectors
  - maintain deployment
  - perform upgrades
  - currently undertaking an upgrade
- They are replacing MidPoint with a product transcribed as “Servion ID”; this should be verified, possibly **Saviynt Identity** or another IGA platform.
- There is a continuous stream of application onboarding:
  - Entra ID / SSO integration
  - Conditional Access policies
  - SCIM provisioning advice
  - secrets and certificate reviews
  - security gatekeeper role for application teams
- The role is a mix of:
  - BAU operations
  - escalated service desk tickets
  - application onboarding projects
  - security/design/architecture advice
  - internal consulting/customer service
- Current identity-change process sounded manual:
  - the interview discussed whether they promote changes through dev/test/prod using GitHub or Azure DevOps workflows
  - the response indicated the current process is still very “click click click”
  - they recognised this as an area that needs to change
- They are interested in **Terraform** and pipeline-based workflow.
- AD is explicitly **not going away**:
  - AD will stay for the foreseeable future
  - they want to move as much as possible to Entra
  - legacy means AD remains important
- AI agents / Entra agent identities are emerging concerns:
  - teams are already deploying agents
  - they need to work out how to protect them
  - Conditional Access and agent blueprint patterns are still evolving

Given that context, the best value is a controlled identity-engineering workflow, not just a scheduled report.

## Recommended architecture

```text
Azure Repos / Azure DevOps
        |
        | Pull request + branch policy
        v
Terraform validation pipeline
        |
        | fmt / validate / plan
        v
Maester validation + EntraExporter diff
        |
        | approval / CAB evidence
        v
Controlled deployment to Dev/Test/UAT/Prod
        |
        v
Scheduled Maester posture monitoring
        |
        +--> pipeline test results
        +--> retained artifacts
        +--> optional Teams/email/Jira notification
        +--> optional Azure Web App report portal
```

## Why Azure DevOps over the other Maester options

Azure DevOps is the most UNSW-shaped default because it supports enterprise change governance:

- pull requests
- branch policies
- pipeline approvals
- environment gates
- artifact retention
- repeatable evidence for CAB/change review
- scheduled posture runs
- Microsoft/Entra-friendly identity integration
- self-hosted agents if required

GitHub Actions is easier for a workshop or personal demo, but Azure DevOps is likely the stronger enterprise identity-operations story.

## Where Maester fits

Use Maester in two modes.

### 1. Change validation gate

Run Maester during pull requests or before production deployment.

Example flow:

```text
PR opened
  -> terraform fmt
  -> terraform validate
  -> terraform plan
  -> optional Entra export/diff
  -> Maester targeted tests
  -> peer review
  -> CAB/change approval
  -> apply to target environment
```

This turns Maester into evidence that the proposed identity change does not violate baseline security controls.

### 2. Scheduled posture monitoring

Run Maester daily or weekly against the tenant.

Example flow:

```text
Scheduled Maester run
  -> execute tests
  -> publish test results
  -> retain HTML/artifacts
  -> notify Teams/email/Jira if critical finding appears
```

This turns Maester into an operational monitoring control for drift and posture regression.

## Terraform vs Bicep

Recommended division of responsibility:

| Area | Recommended tool |
|---|---|
| Entra apps, service principals, Conditional Access, access packages, PIM | **Terraform** |
| Azure resources such as Storage, Key Vault, Web App, Automation Account | **Bicep or Terraform** |
| Maester tests | **PowerShell / Pester in repo** |
| Workflow orchestration | **Azure DevOps pipeline** |
| Reporting portal, if required | **Azure Web App with Bicep** |

Because UNSW explicitly mentioned Terraform and the workshop is Terraform-based, Terraform is the better focus for Entra-as-Code.

Bicep is still useful for Azure hosting infrastructure, especially if publishing reports to an Azure Web App.

## Self-hosted Azure DevOps agent consideration

Azure DevOps supports self-hosted agents. This may be relevant for UNSW.

Use Microsoft-hosted agents if:

- the pipeline only calls public Microsoft Graph/Entra endpoints
- no private network access is required
- fast setup is the priority
- standard tools are sufficient

Use self-hosted agents if:

- UNSW requires tighter control over runtime environment
- private network access is needed
- stable outbound IPs are required
- Terraform, PowerShell, Maester, Graph modules, or custom tools should be preinstalled
- pipeline run-time limits should be avoided
- security policy requires internal compute

For a large university identity environment, self-hosted agents are a credible option, but they increase maintenance responsibility.

## Where the workshop repo fits

Reference repo:

<https://github.com/mjendza/workshop-entra-as-code-interactive>

The workshop is highly relevant because it covers UNSW-aligned themes:

- SSO applications
- service principals
- workload identity federation
- Conditional Access
- access packages
- PIM
- tenant security hardening
- Maester
- EntraExporter
- diff-based change detection
- Zero Trust Assessment
- app roles/API patterns
- agent identity patterns

Use the workshop as a **learning/reference architecture**, not as something to apply directly to production.

Important framing:

> The workshop demonstrates the primitives. For UNSW, the enterprise value is wrapping those primitives in controlled promotion, peer review, CAB evidence, and safe rollout practices.

## Maester test focus areas for UNSW

Prioritise job-aligned checks over broad compliance coverage:

- Conditional Access baseline
- Authentication methods baseline
- phishing-resistant MFA / passkeys / Windows Hello for Business / Mac PSSO readiness
- app registrations and enterprise applications
- app registration owners and MFA
- high-risk app permissions
- secrets and certificate expiry
- privileged role assignments / PIM
- Entra Connect / on-premises sync posture
- tenant creation and security group creation restrictions
- SCIM/app provisioning evidence
- Azure/Graph permissions used by workload identities

## Recommended phased approach

### Phase 1: Personal/demo readiness

Build a lab/demo showing:

1. Terraform-managed Entra app or Conditional Access object.
2. Azure DevOps or GitHub Actions pipeline.
3. Workload identity federation instead of client secrets.
4. Terraform plan output.
5. Maester test execution.
6. EntraExporter or JSON diff evidence.
7. Manual approval step representing CAB.

### Phase 2: UNSW pilot pattern

If applying this thinking at UNSW, start with a low-risk non-production pattern:

1. Select a non-prod app onboarding scenario.
2. Represent app registration / enterprise app / group / access package in Terraform.
3. Run Maester tests as validation.
4. Produce evidence artifact for change review.
5. Document rollback and operational support steps.

### Phase 3: Broader adoption

Expand to:

- Conditional Access policy lifecycle
- access package lifecycle
- app onboarding factory pattern
- privileged identity/PIM checks
- scheduled posture reports
- optional Azure Web App report portal
- Jira/change integration

## Options not recommended as the primary UNSW pattern

### Plain GitHub Actions

Good for learning and demos, but less obviously aligned to enterprise Microsoft change governance unless UNSW already uses GitHub as the standard platform.

### Azure Automation only

Useful for simple scheduled Maester runs, but it does not solve the broader problem of identity change control, review, promotion, and CAB evidence.

### Azure Container App Job

Technically powerful and containerized, but likely too much operational complexity for the first iteration. It is better suited to platform teams already standardized on containers.

### Azure Web App first

A report portal is useful, but it should come after the validation/governance workflow. Otherwise it risks becoming a dashboard without improving change safety.

## Final position

The most fitting UNSW solution is:

> **Azure DevOps + Terraform Entra-as-Code + Maester validation + scheduled posture monitoring**

With optional later enhancement:

> **Azure DevOps publishing Maester reports to an Entra-protected Azure Web App**

This aligns with UNSW’s transcript signals:

- hybrid AD/Entra estate
- Entra ID Connect remains important
- AD remains long-term
- MidPoint/IGA transition
- Delinea PAM
- continuous app onboarding
- Conditional Access complexity
- manual “click click click” change process
- interest in Terraform and pipeline-based improvement
- need for audit/compliance/change evidence

In short:

> Use IaC to make identity changes reviewable and repeatable. Use Maester to prove those changes preserve security posture.