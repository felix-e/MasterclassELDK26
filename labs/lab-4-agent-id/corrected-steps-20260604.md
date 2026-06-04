# Lab 4 corrected steps — Microsoft Entra Agent ID

Date verified: 2026-06-04

This note updates the Lab 4 Agent ID setup flow against current Microsoft documentation. The current Agent ID wizard/API sequence is different from the original lab notes, and extra permissions are required when creating Agent Identities programmatically.

## Official Microsoft docs checked

- Microsoft Entra Agent ID overview: <https://learn.microsoft.com/entra/agent-id/>
- Create an agent identity blueprint: <https://learn.microsoft.com/entra/agent-id/create-blueprint>
- Create agent identities: <https://learn.microsoft.com/entra/agent-id/identity-platform/create-delete-agent-identities>
- Configure inheritable permissions: <https://learn.microsoft.com/entra/agent-id/configure-inheritable-permissions-blueprints>
- Inheritable permissions concept: <https://learn.microsoft.com/entra/agent-id/concept-inheritable-permissions>
- Authorization in Agent ID: <https://learn.microsoft.com/entra/agent-id/authorization-agent-id>
- Graph create agentIdentity API: <https://learn.microsoft.com/graph/api/agentidentity-post?view=graph-rest-beta>
- Graph create agentIdentityBlueprint API: <https://learn.microsoft.com/graph/api/agentidentityblueprint-post?view=graph-rest-v1.0>
- Graph create agentIdentityBlueprintPrincipal API: <https://learn.microsoft.com/graph/api/agentidentityblueprintprincipal-post?view=graph-rest-v1.0>

## Why the current wizard differs from Lab 4

The original Lab 4 flow is simpler:

1. Create Agent Identity Blueprint.
2. Configure interactive agent support.
3. Configure inheritable permissions.
4. Add `User.Read`.
5. Create Agent Identities and users.

The current PowerShell/API flow is more explicit:

1. Create Agent Identity Blueprint.
2. Add blueprint credential/secret.
3. Configure interactive-agent API scope.
4. Decide whether this blueprint can create Agent ID users.
5. Configure inheritable permissions by resource application.
6. Choose static or dynamic permission model.
7. Add required resource access permissions.
8. Grant admin consent.
9. Create Agent Identities and optionally Agent ID users.

This means the difference in sequence is expected and appears to reflect current Microsoft Entra Agent ID changes.

## Important permission correction

If creation fails with this error:

```text
POST https://graph.microsoft.com/beta/servicePrincipals/Microsoft.Graph.AgentIdentity
403 Authorization_RequestDenied
Insufficient privileges to complete the operation.
```

The likely issue is missing permission to create an Agent Identity.

Current Microsoft Graph docs for `POST /servicePrincipals/microsoft.graph.agentIdentity` list:

- Least privileged delegated permission: `AgentIdentity.Create.All`
- Least privileged application permission: `AgentIdentity.Create.All`
- Higher application permissions: `AgentIdentity.CreateAsManager`, `AgentIdentity.ReadWrite.All`

`AgentIdUser.ReadWrite.IdentityParentedBy` is for Agent ID user-account operations, not for creating the Agent Identity service principal itself.

## Corrected lab setup steps

### 1. Install required PowerShell modules

```powershell
Install-Module Microsoft.Entra.Beta.Authentication -Scope CurrentUser
Install-Module Microsoft.Entra.Beta.Applications -Scope CurrentUser
```

Use PowerShell 7.

### 2. Connect with the required scopes

Use a tenant admin/account with suitable Agent ID and application administration rights.

```powershell
Connect-Entra -Scopes `
  Organization.Read.All, `
  User.Read, `
  AgentIdentityBlueprint.Create, `
  AgentIdentityBlueprintPrincipal.Create, `
  AgentIdentityBlueprint.ReadWrite.All, `
  AgentIdentityBlueprint.AddRemoveCreds.All, `
  AgentIdentityBlueprint.UpdateAuthProperties.All, `
  AgentIdentity.Create.All, `
  AppRoleAssignment.ReadWrite.All
```

Role notes from Microsoft docs:

- `Agent ID Developer` or `Agent ID Administrator` can create blueprints and blueprint principals.
- `Agent ID Administrator` is required to add a secret/certificate credential.
- `Cloud Application Administrator` or `Application Administrator` is required to grant delegated Microsoft Graph permissions.
- `Privileged Role Administrator` is the least privileged role required to grant Microsoft Graph application permissions.

### 3. Run the Agent ID wizard

```powershell
Invoke-EntraBetaAgentIdInteractive
```

Recommended lab answers:

| Wizard prompt | Recommended answer |
| --- | --- |
| Use current user as sponsor and owner? | `y` |
| Will this agent act on behalf of users? | `y` |
| Admin consent description/display name/scope value | Use defaults, or keep scope value as `access_agent_as_user` |
| Will this agent create Agent Users without a user? | Usually `n` for this lab unless Agent User accounts are specifically needed |
| Will this Agent Identity Blueprint have inheritable permissions? | `y` |
| Resource application ID | Press Enter for Microsoft Graph: `00000003-0000-0000-c000-000000000000` |
| Inherit scopes, roles, or both? | `s` for delegated Graph scopes in this lab |
| Use static permissions? | `y` for predictable lab setup |

### 4. Add required resource access permissions

For the simple demo agent that reads the signed-in user's profile, include:

- Microsoft Graph delegated `User.Read`

If the wizard or app will create Agent Identities programmatically, also include:

- `AgentIdentity.Create.All`

Only include the following if the lab really needs Agent ID user accounts:

- `AgentIdUser.ReadWrite.IdentityParentedBy`

Do not rely on inheritable permissions alone. Microsoft docs distinguish:

- `requiredResourceAccess` = declaration shown during consent
- inheritable permissions = resource apps/permissions eligible to flow to Agent Identities
- admin consent = actual grant

For inherited permissions to appear in child Agent Identity tokens, both conditions must be true:

1. The resource app is configured as inheritable.
2. The permission is granted to the blueprint principal through static or dynamic consent.

### 5. Complete admin consent

For static permissions, consent typically uses:

```text
https://graph.microsoft.com/.default
```

This grants permissions declared in the blueprint's `requiredResourceAccess`.

If a needed permission was missing before consent, add it to required resource access and complete admin consent again.

### 6. Create the Agent Identity

Current official Graph endpoint is beta:

```http
POST https://graph.microsoft.com/beta/servicePrincipals/microsoft.graph.agentIdentity
OData-Version: 4.0
Content-Type: application/json
Authorization: Bearer <token>
```

Example body:

```json
{
  "displayName": "My Agent Identity",
  "agentIdentityBlueprintId": "<agent-blueprint-app-id>",
  "sponsors@odata.bind": [
    "https://graph.microsoft.com/v1.0/users/<user-id>"
  ]
}
```

The response contains the Agent Identity `id`. Use that value as `AGENT_IDENTITY_ID` in the server configuration.

### 7. Create the frontend SPA app registration

In Microsoft Entra admin center:

1. Go to **App registrations**.
2. Select **New registration**.
3. Name: `Agent Demo Frontend`.
4. Supported account types: accounts in this organizational directory only.
5. Redirect URI type: Single-page application.
6. Redirect URI: `http://localhost:8080`.
7. Register the app.

Add API permission/scope for the Agent Blueprint API:

```text
api://<agent-blueprint-client-id>/access_agent_as_user
```

### 8. Configure server environment variables

Create `.env` in `agent-0/server`:

```env
NODE_ENV=development
API_HOST=localhost
API_PORT=3000
ALLOWED_ORIGINS=http://localhost:8080

ENTRA_TENANT_ID=<tenant-id>
ENTRA_CLIENT_ID=<agent-blueprint-app-id>
ENTRA_AUDIENCE=api://<agent-blueprint-app-id>

AGENT_BLUEPRINT_ID=<agent-blueprint-app-id>
AGENT_IDENTITY_ID=<created-agent-identity-id>

USE_MANAGED_IDENTITY=false
ENTRA_CLIENT_SECRET=<blueprint-secret>

OPENAI_API_KEY=<openai-api-key>
```

### 9. Configure client environment variables

Create `.env` in `agent-0`:

```env
NODE_ENV=development
API_HOST=localhost
API_PORT=3000
ALLOWED_ORIGINS=http://localhost:8080

VITE_ENTRA_TENANT_ID=<tenant-id>
VITE_ENTRA_CLIENT_ID=<spa-client-id>
VITE_ENTRA_API_SCOPE=api://<agent-blueprint-app-id>/access_agent_as_user
```

### 10. Run server and client

Server:

```powershell
cd agent-0/server
npm install
npm run dev
```

Client:

```powershell
cd agent-0/client
npm install
npm run dev
```

Open:

```text
http://localhost:8080
```

Sign in and test with a profile question such as:

```text
What is my name?
```

## Troubleshooting checklist

If Agent Identity creation fails with 403:

1. Confirm the caller has `AgentIdentity.Create.All`.
2. Confirm the signed-in admin has an appropriate Agent ID role, especially `Agent ID Administrator` for nonowner scenarios.
3. Confirm admin consent was completed after adding required permissions.
4. Confirm you are creating the Agent Identity from the correct blueprint app ID.
5. If creating Agent ID users, confirm `AgentIdUser.ReadWrite.IdentityParentedBy` was declared and consented.
6. Do not confuse the blueprint object ID, blueprint app ID/client ID, blueprint principal ID, and child Agent Identity ID.

## Bottom line

Lab 4 should be updated to reflect the current Agent ID setup model. The major correction is that `User.Read` alone is not sufficient when the lab flow creates Agent Identities programmatically. Add and consent `AgentIdentity.Create.All`, and only opt into Agent ID user creation if the demo truly needs Agent User accounts.
