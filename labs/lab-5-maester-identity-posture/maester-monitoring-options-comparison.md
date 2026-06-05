# Maester Monitoring Options Comparison

Source: <https://maester.dev/docs/next/monitoring/>

This guide compares the main Maester continuous-monitoring deployment options so you can choose the best fit based on platform preference, operational model, cost, effort, and reporting needs.

## High-level grouping

The options fall into three broad categories:

1. **CI/CD runners**
   - GitHub Actions
   - Azure DevOps Pipeline
   - Azure DevOps with Terraform Module
   - GitLab
   - Bitbucket

2. **Azure-native scheduled execution**
   - Azure Automation
   - Azure Automation with Bicep
   - Azure Container App Job

3. **Hosted report portal**
   - Azure Web App with Bicep
   - Azure DevOps & Azure Web App

## Quick recommendation

| If you want... | Best fit |
|---|---|
| Fastest/easiest setup | **GitHub Actions** |
| Microsoft-native DevOps with Entra integration | **Azure DevOps** |
| Repeatable enterprise IaC deployment | **Azure DevOps with Terraform Module** |
| Already standardized on GitLab | **GitLab** |
| Already standardized on Bitbucket | **Bitbucket** |
| Low-cost Azure-native scheduled email/reporting | **Azure Automation** |
| Same as above, but repeatable/infrastructure-as-code | **Azure Automation with Bicep** |
| A browsable Maester report website protected by Entra ID | **Azure Web App with Bicep** |
| CI-generated report published to a hosted website | **Azure DevOps & Azure Web App** |
| Containerized, portable, job-style runtime | **Azure Container App Job** |

## What all methods have in common

All approaches are designed to:

- Run Maester on a schedule.
- Authenticate to Microsoft Entra and Microsoft Graph.
- Execute Maester tests.
- Store or publish the results.
- Optionally expose results as artifacts, HTML reports, email, or web output.
- Require Microsoft Graph permissions and tenant/admin consent during setup.

The main differences are:

- **Where Maester runs**
- **How it authenticates**
- **Where results live**
- **How repeatable the deployment is**
- **Operational cost**
- **How much Azure infrastructure you own**

## Comparison table

| Method | Runtime | Results location | Auth style | Cost profile | Effort | Best fit |
|---|---|---|---|---|---|---|
| **GitHub** | GitHub Actions runner | GitHub Actions artifacts/checks | OIDC workload identity recommended; client secret possible | GitHub free tier includes runner minutes; Maester docs mention 2,000 private repo minutes/month | Low | Quick start, GitHub-first teams |
| **Azure DevOps** | Azure Pipeline runner | Azure DevOps pipeline/test results | Workload identity federation/service connection recommended; secret possible | Azure DevOps free tier; Maester docs mention 1,800 minutes/month, unlimited with self-hosted agent | Low-Medium | Microsoft/Entra/Azure DevOps shops |
| **Azure DevOps with Terraform Module** | Azure Pipeline, provisioned by Terraform | Azure DevOps | Same as Azure DevOps | Same as Azure DevOps plus Terraform state/backend considerations | Medium | Repeatable IaC deployment into Azure DevOps |
| **GitLab** | GitLab CI runner | GitLab artifacts | OIDC/federated credentials | Depends on GitLab tier/minutes | Medium | GitLab-standard organizations |
| **Bitbucket** | Bitbucket Pipelines | Bitbucket artifacts | OIDC/federated or variables/secrets | Depends on Bitbucket plan/minutes | Medium | Bitbucket-standard organizations |
| **Azure Automation** | Azure Automation runbook | Email/blob/output depending setup | Managed identity or app auth depending setup | Maester docs mention 500 free execution minutes/month | Low-Medium | Simple Azure-native scheduled monitoring |
| **Azure Automation with Bicep** | Azure Automation runbook provisioned by Bicep | Usually storage/email/report output | Managed identity | Automation + storage; 500 free minutes may cover many tenants | Medium | Repeatable Azure-native deployment |
| **Azure Web App with Bicep** | Azure Automation generates report; Azure Web App hosts it | Web App UI protected by Entra ID | Managed identities | App Service + Automation + Storage | Medium-High | Human-friendly dashboard/report portal |
| **Azure Container App Job** | Container Apps scheduled job | Storage/logs/artifacts depending implementation | App/cert/managed identity patterns | Container Apps consumption + ACR + Log Analytics/storage | High | Containerized, isolated, scalable runtime |
| **Azure DevOps & Azure Web App** | Azure DevOps generates report; Web App hosts it | Entra-protected Web App | Federated credentials from Azure DevOps | Azure DevOps minutes + App Service/storage | High | CI-controlled report publishing to a portal |

## Method-by-method notes

### 1. GitHub Actions

**Pros**

- Easiest path if your Maester tests live in GitHub.
- Maester docs describe GitHub as the quickest way to get started.
- OIDC workload identity avoids long-lived secrets.
- Good built-in scheduling with cron.
- Good visibility in the GitHub Actions UI.

**Cons**

- Results mostly live in GitHub unless you publish them elsewhere.
- GitHub organization and security policies may affect setup.
- Less natural if your enterprise standard is Azure DevOps.

**Best fit**

- You want a low-friction setup.
- You already use GitHub.
- You are comfortable with GitHub Actions permissions and OIDC/secrets.

**Cost**

- Usually very low. Maester docs mention GitHub free private repo minutes being enough for daily Maester runs.

**Effort**

- Low.

### 2. Azure DevOps Pipeline

**Pros**

- Very natural for Microsoft/Azure/Entra-heavy organizations.
- Strong Entra integration.
- Supports workload identity federation.
- Pipeline results and schedules are straightforward.
- Can use Microsoft-hosted or self-hosted agents.

**Cons**

- Slightly more setup than GitHub if you do not already use Azure DevOps.
- Azure DevOps YAML/service connections can be fiddly.
- Results remain mostly pipeline-centric unless published elsewhere.

**Best fit**

- You already have Azure DevOps.
- You want Microsoft-native CI/CD.
- You want governance through Azure DevOps projects, service connections, and Entra.

**Cost**

- Low. Maester docs mention 1,800 free Microsoft-hosted minutes/month, or unlimited if self-hosted.

**Effort**

- Low-Medium.

### 3. Azure DevOps with Terraform Module

**Pros**

- Same benefits as Azure DevOps.
- Adds repeatable infrastructure-as-code deployment.
- Good for standardizing Maester across multiple tenants/projects.
- Easier to version and review deployment changes.

**Cons**

- Requires Terraform knowledge and state management.
- More moving parts than manual Azure DevOps setup.
- Probably overkill for a single simple tenant.

**Best fit**

- Platform/security teams.
- Multi-tenant or repeatable enterprise rollout.
- Environments where clickops is discouraged.

**Cost**

- Same runtime cost as Azure DevOps.
- Additional cost is operational complexity, not necessarily money.

**Effort**

- Medium.

### 4. GitLab

**Pros**

- Good if GitLab is already your source-control/CI platform.
- Can use CI variables and artifacts.
- Scheduled pipelines are familiar to GitLab users.

**Cons**

- Maester docs note GitLab does not have the same summary view as GitHub.
- Less Microsoft-native than Azure DevOps.
- OIDC/federated setup may be less familiar to Microsoft 365 admins.

**Best fit**

- GitLab-first organizations.
- Teams that already have GitLab runners and CI governance.

**Cost**

- Depends on GitLab plan and runner minutes.

**Effort**

- Medium.

### 5. Bitbucket

**Pros**

- Useful if Bitbucket is your standard repo/CI platform.
- Keeps Maester near existing source-control workflows.
- Scheduled pipeline pattern is conceptually similar to GitHub/GitLab.

**Cons**

- Less common in Microsoft security/admin environments.
- Fewer Maester-specific niceties than GitHub/Azure DevOps.
- Results/artifacts experience may be less polished for this use case.

**Best fit**

- Bitbucket-standard teams.

**Cost**

- Depends on Bitbucket Pipelines plan/minutes.

**Effort**

- Medium.

### 6. Azure Automation

**Pros**

- Simple Azure-native scheduled execution.
- No external CI/CD platform needed.
- Good for email/report automation.
- Maester docs mention 500 free execution minutes/month.
- Operationally familiar to Azure admins.

**Cons**

- Runbook/module/runtime management can be annoying.
- Less developer-friendly than CI pipelines.
- Result viewing is not as rich unless you add storage/email/report publishing.
- Debugging can be clunkier than CI logs.

**Best fit**

- Azure admins who want scheduled Maester without GitHub/Azure DevOps.
- Simple tenant monitoring with low recurring cost.

**Cost**

- Very low for light schedules. Free execution minutes may cover many daily/weekly runs.

**Effort**

- Low-Medium.

### 7. Azure Automation with Bicep

**Pros**

- Same operational model as Azure Automation.
- Repeatable deployment.
- Better for production/governed Azure environments.
- Managed identity-based pattern is cleaner than secrets.

**Cons**

- Requires Bicep/Azure CLI familiarity.
- More initial setup than portal/manual runbook.
- Still inherits Automation runbook limitations.

**Best fit**

- Azure-native teams wanting repeatable IaC.
- Security/governance teams deploying Maester consistently.

**Cost**

- Automation + possible storage. Usually low.

**Effort**

- Medium.

### 8. Azure Web App with Bicep

**Pros**

- Provides a browsable Maester report site.
- Good for stakeholders who do not want to inspect pipeline artifacts.
- Can be protected with Entra ID Authentication.
- Bicep makes the Azure resources repeatable.
- Useful when reports should be easy to access.

**Cons**

- More Azure resources to own.
- App Service cost even when Maester is not running.
- More moving parts: Web App, Automation, storage, identity, permissions.
- Higher maintenance than plain GitHub/Azure DevOps.

**Best fit**

- You want a secure internal Maester dashboard/report portal.
- Non-engineers or auditors need to view results.
- You prefer Azure-hosted reporting.

**Cost**

- Medium. App Service + Automation + Storage.

**Effort**

- Medium-High.

### 9. Azure Container App Job

**Pros**

- Modern, containerized job runtime.
- Portable and isolated.
- Good if you already package tooling in containers.
- Supports cron/event/manual job patterns.
- Better control over runtime dependencies.

**Cons**

- Highest technical complexity among the listed options.
- Requires Docker, image build, Azure Container Registry, Container Apps, logs/storage decisions.
- Maester docs suggest 1 GB memory may be insufficient; 1.5-2 GB may be more reliable.
- More infrastructure to monitor.

**Best fit**

- Teams already using containers.
- Advanced/platform teams.
- Scenarios needing runtime consistency or custom dependencies.

**Cost**

- Consumption-based Container Apps cost, plus ACR, Log Analytics, storage if used.

**Effort**

- High.

### 10. Azure DevOps & Azure Web App

**Pros**

- Combines strong CI/CD governance with a user-friendly web report.
- Azure DevOps generates report on schedule.
- Web App hosts the output behind Entra authentication.
- Good separation: pipeline runs tests, web app presents results.
- Good enterprise/audit story.

**Cons**

- More complex than either Azure DevOps alone or Web App alone.
- Requires Azure DevOps, Bicep, App Service, identities, and a publishing flow.
- Higher cost than pipeline-only options.
- More things can break.

**Best fit**

- Enterprises that already use Azure DevOps and want a polished report portal.
- Teams needing scheduled CI plus stakeholder-friendly HTML output.

**Cost**

- Medium-High: Azure DevOps minutes plus App Service/storage.

**Effort**

- High.

## Practical ranking

For most scenarios:

1. **GitHub Actions** - easiest if allowed.
2. **Azure DevOps** - best Microsoft-enterprise default.
3. **Azure Automation with Bicep** - best Azure-native scheduled option.
4. **Azure Web App with Bicep** - best if people need to browse reports.
5. **Azure DevOps & Azure Web App** - best enterprise pipeline + portal setup.
6. **Azure Container App Job** - best for container/platform teams, but not the simplest.

Choose **GitLab** or **Bitbucket** mainly when your organization already standardizes on them.

Choose **Azure DevOps with Terraform Module** when you already manage DevOps/IaC with Terraform or need repeatable rollout across environments.
