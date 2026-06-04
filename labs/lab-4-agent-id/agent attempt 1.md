agent attempt 1

===


PS 23:08:26 felixelliott@M23[MasterclassELDK26]# Invoke-EntraBetaAgentIdInteractive                               
  
============================================================         
  Microsoft Entra Agent ID - Interactive Setup
============================================================

This wizard walks you through the full Agent Identity
Blueprint workflow, step by step:

  1. Create an Agent Identity Blueprint
  2. Configure security (client secret)
  3. Configure interactive agent support
  4. Configure agent user creation
  5. Configure inheritable permissions
  6. Choose static or dynamic permission model
  7. Get admin consent for the blueprint
  8. Create Agent Identities and Users

You will be prompted at each step. Press Ctrl+C to exit
at any time.

Learn more: https://learn.microsoft.com/entra/agent-id/
============================================================


--- Phase 1: Create Agent Identity Blueprint ---

Enter a display name for the Agent Identity Blueprint (press Enter to use 'Agent Identity Blueprint Example 21337881'): 
Agent Identity Blueprints and Agent Identities require sponsors.
Learn more: https://learn.microsoft.com/entra/agent-id/key-concepts#agent-owners-sponsors-and-managers
Use current user (admin@lab.keepcove.com) as sponsor and owner? (y/n): y
Using current user as default sponsor and owner: admin@lab.keepcove.com

Creating Agent Identity Blueprint: Agent Identity Blueprint Example 21337881
Retrieving current user information for helpful prompts...
  Validated sponsor user: Felix Elliott (admin@lab.keepcove.com)
  Validated owner user: Felix Elliott (admin@lab.keepcove.com)
Successfully created Agent Identity Blueprint
Created Blueprint ID: 29b2a151-43de-4587-be99-1a83e0c269eb


--- Phase 2: Configure Blueprint Security ---

Successfully added secret to Agent Blueprint
Secret: <redacted>
Secret Key ID: 499bc435-9af7-41ce-84a6-de8695221d66
Secret Expires: 09/02/2026 23:11:57


--- Phase 3: Configure Interactive Agents ---

Agents often have to act on behalf of users. These are called Interactive Agents.
Learn more: https://learn.microsoft.com/entra/agent-id/key-concepts#agent-operation-patterns
Will this agent act on behalf of users? (y/n): y

Configuring scopes for interactive agents...
Enter the admin consent description for the scope (press Enter to use 'Allow the agent to act on behalf of the signed-in user'): 
Enter the admin consent display name for the scope (press Enter to use 'Access agent on behalf of user'): 
Enter the scope value (used in token claims, press Enter to use 'access_agent_as_user'): 
Successfully added OAuth2 permission scope to Agent Blueprint
Configured interactive scope: 37e406ef-9d0d-4930-83ac-a7373d19b790


--- Phase 4: Configure Blueprint to Create Agent ID Users ---

Agent Identities can be created by users with Agent ID Developer,
Agent ID Administrator, or AI Administrator roles, or by an agent
without a user using the Agent Identity Blueprint's credentials.
Will this agent create Agent Users without a user? (y/n): y


--- Phase 5: Configure Inheritable Permissions ---

Agent Identities can optionally inherit both delegated and app-only
permissions to resources from their Agent Identity Blueprint parent.
Learn more: https://learn.microsoft.com/entra/agent-id/configure-inheritable-permissions-blueprints
Will this Agent Identity Blueprint have inheritable permissions? (y/n): y

Configuring inheritable permissions...
Enter the Resource Application ID (press Enter to use Microsoft Graph: 00000003-0000-0000-c000-000000000000): 
For 'Microsoft Graph', make inheritable: (S)copes, (R)oles, or (B)oth? [B]: s
Successfully added inheritable permissions for 'Microsoft Graph'.
Add inheritable permissions for another resource app? (y/n): n
Permissions are now available for inheritance by agent blueprints.
Configured inheritable permissions: allAllowed


--- Phase 6: Configure Static or Dynamic Permissions ---

Inheritable permissions can be configured as Static or Dynamic.
  Static permissions are declared in requiredResourceAccess on the blueprint.
  This is recommended if the agent will work in Agent 365.
  Dynamic permissions are resolved at runtime via admin consent.
Use Static permissions (recommended for Agent 365)? (y=static, n=dynamic): y

Configuring static required resource access...
Blueprint is configured to create Agent ID users. Adding AgentIdUser.ReadWrite.IdentityParentedBy to required resource access...
Successfully added required resource access for 'Microsoft Graph'.
Required resource access configuration complete.
Added AgentIdUser.ReadWrite.IdentityParentedBy to required resource access
You can now add additional permissions to the required resource access.
Enter the Resource Application ID (press Enter to use Microsoft Graph: 00000003-0000-0000-c000-000000000000): 
Permission type: (S)cope for delegated permissions or (R)ole for application permissions: s
Enter a search term to filter available permissions (or press Enter to enter a GUID directly): 
Enter the permission GUID: 
Add another permission for 'Microsoft Graph'? (y/n): 
Add another permission for 'Microsoft Graph'? (y/n): y
Permission type: (S)cope for delegated permissions or (R)ole for application permissions: r
Enter a search term to filter available permissions (or press Enter to enter a GUID directly): 
Enter the permission GUID: 
Add another permission for 'Microsoft Graph'? (y/n): y
Permission type: (S)cope for delegated permissions or (R)ole for application permissions: s
Enter a search term to filter available permissions (or press Enter to enter a GUID directly): 
Enter the permission GUID: 
Add another permission for 'Microsoft Graph'? (y/n): n
WARNING: No permissions specified for 'Microsoft Graph'. Skipping.
Add required resource access for another resource app? (y/n): n
Required resource access configuration complete.


--- Phase 7: Get Consent for the Blueprint in This Tenant ---

Static permissions were selected, so admin consent uses the .default scope.
This grants all permissions defined in the blueprint's requiredResourceAccess.
Preparing admin consent page for Agent Identity Blueprint Principal...
Opening admin consent page in system browser...
Admin consent page opened in browser successfully

Please complete the admin consent process in the browser window.
After consent is granted, the Agent Blueprint will be able to inherit the requested permissions.

AgentBlueprintId : 29b2a151-43de-4587-be99-1a83e0c269eb
TenantId         : 8f87362b-5dd3-45dd-a667-cbff144e3863
RequestedScopes  : {https://graph.microsoft.com/.default}
RequestedRoles   : 
RedirectUri      : https://entra.microsoft.com/TokenAuthorize
State            : xyz308034
ConsentUrl       : https://login.microsoftonline.com/8f87362b-5dd3-45dd-a667-cbff144e3863/v2.0/adminconsent?client_id=29b2a
                   151-43de-4587-be99-1a83e0c269eb&scope=https%3a%2f%2fgraph.microsoft.com%2f.default&redirect_uri=https%3a
                   %2f%2fentra.microsoft.com%2fTokenAuthorize&state=xyz308034
Action           : Browser Launched
Timestamp        : 4/6/2026 11:16:17 pm


IMPORTANT: Please complete the admin consent process in your browser before continuing.
The script will wait for you to grant admin consent...
Press Enter to continue after Admin Consent has been granted, or type 'retry' to relaunch the consent prompt: 
Continuing with workflow...


--- Phase 8: Create Agent Identities and Users ---

Do you want to create Agent Identities and Agent Users for this Agent Identity Blueprint? (y/n): y

Use example names for Agent Identities and Users? (y=use examples like 'Agent Identity Example', n=provide custom names): y
Using example naming pattern for Agent Identities and Users

Creating Agent Identity #21338256
Using current user as sponsor for Agent Identity.
  Validated sponsor user: Felix Elliott (admin@lab.keepcove.com)
  Validated owner user: Felix Elliott (admin@lab.keepcove.com)
New-EntraBetaAgentIDForAgentIdentityBlueprint: Failed to create Agent Identity after 10 attempts: POST
https://graph.microsoft.com/beta/servicePrincipals/Microsoft.Graph.AgentIdentity HTTP/1.1 403 Forbidden Cache-Control:
no-cache Transfer-Encoding: chunked Vary: Accept-Encoding Strict-Transport-Security: max-age=31536000 request-id:
a9ca09db-40a9-4171-8dfe-b60ef02bada8 client-request-id: 7c1c3731-6eff-4a31-8bbb-c952bc09b3c5 x-ms-ags-diagnostic:
{"ServerInfo":{"DataCenter":"Australia
Southeast","Slice":"E","Ring":"3","ScaleUnit":"000","RoleInstance":"ML1PEPF0000F462"}} Link:
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:assignmentRequiredForPrincipalTypes&f
rom=2024-08-01&to=2024-09-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:assignmentRequiredForPrincipalTypes&f
rom=2024-08-01&to=2024-09-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:SPCertification&from=2022-09-01&to=20
22-10-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:ApplicationsInAdministrativeUnits&fro
m=2021-05-01&to=2021-06-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:samlSLOPostBinding&from=2023-04-01&to
=2023-05-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,AgentBlueprint&from=2025-08-01&to=2025-09-01>;rel="d
eprecation";type="text/html" Deprecation: Mon, 18 Apr 2022 23:59:59 GMT Sunset: Thu, 18 Apr 2024 23:59:59 GMT
x-ms-resource-unit: 1 Date: Thu, 04 Jun 2026 13:19:07 GMT Content-Type: application/json 
{"error":{"code":"Authorization_RequestDenied","message":"Insufficient privileges to complete the
operation.","innerError":{"date":"2026-06-04T13:19:08","request-id":"a9ca09db-40a9-4171-8dfe-b60ef02bada8","client-request-i
d":"7c1c3731-6eff-4a31-8bbb-c952bc09b3c5"}}}
New-EntraBetaAgentIDForAgentIdentityBlueprint: Failed to create Agent Identity: POST https://graph.microsoft.com/beta/servicePrincipals/Microsoft.Graph.AgentIdentity
HTTP/1.1 403 Forbidden Cache-Control: no-cache Transfer-Encoding: chunked Vary: Accept-Encoding
Strict-Transport-Security: max-age=31536000 request-id: a9ca09db-40a9-4171-8dfe-b60ef02bada8 client-request-id:
7c1c3731-6eff-4a31-8bbb-c952bc09b3c5 x-ms-ags-diagnostic: {"ServerInfo":{"DataCenter":"Australia
Southeast","Slice":"E","Ring":"3","ScaleUnit":"000","RoleInstance":"ML1PEPF0000F462"}} Link:
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:assignmentRequiredForPrincipalTypes&f
rom=2024-08-01&to=2024-09-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:assignmentRequiredForPrincipalTypes&f
rom=2024-08-01&to=2024-09-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:SPCertification&from=2022-09-01&to=20
22-10-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:ApplicationsInAdministrativeUnits&fro
m=2021-05-01&to=2021-06-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:samlSLOPostBinding&from=2023-04-01&to
=2023-05-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,AgentBlueprint&from=2025-08-01&to=2025-09-01>;rel="d
eprecation";type="text/html" Deprecation: Mon, 18 Apr 2022 23:59:59 GMT Sunset: Thu, 18 Apr 2024 23:59:59 GMT
x-ms-resource-unit: 1 Date: Thu, 04 Jun 2026 13:19:07 GMT Content-Type: application/json 
{"error":{"code":"Authorization_RequestDenied","message":"Insufficient privileges to complete the
operation.","innerError":{"date":"2026-06-04T13:19:08","request-id":"a9ca09db-40a9-4171-8dfe-b60ef02bada8","client-request-i
d":"7c1c3731-6eff-4a31-8bbb-c952bc09b3c5"}}}
Invoke-MgGraphRequest: POST https://graph.microsoft.com/beta/servicePrincipals/Microsoft.Graph.AgentIdentity HTTP/1.1 403 Forbidden
Cache-Control: no-cache Transfer-Encoding: chunked Vary: Accept-Encoding Strict-Transport-Security: max-age=31536000
request-id: a9ca09db-40a9-4171-8dfe-b60ef02bada8 client-request-id: 7c1c3731-6eff-4a31-8bbb-c952bc09b3c5
x-ms-ags-diagnostic: {"ServerInfo":{"DataCenter":"Australia
Southeast","Slice":"E","Ring":"3","ScaleUnit":"000","RoleInstance":"ML1PEPF0000F462"}} Link:
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:assignmentRequiredForPrincipalTypes&f
rom=2024-08-01&to=2024-09-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:assignmentRequiredForPrincipalTypes&f
rom=2024-08-01&to=2024-09-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:SPCertification&from=2022-09-01&to=20
22-10-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:ApplicationsInAdministrativeUnits&fro
m=2021-05-01&to=2021-06-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,PrivatePreview:samlSLOPostBinding&from=2023-04-01&to
=2023-05-01>;rel="deprecation";type="text/html",
<https://developer.microsoft-tst.com/en-us/graph/changes?$filterby=beta,AgentBlueprint&from=2025-08-01&to=2025-09-01>;rel="d
eprecation";type="text/html" Deprecation: Mon, 18 Apr 2022 23:59:59 GMT Sunset: Thu, 18 Apr 2024 23:59:59 GMT
x-ms-resource-unit: 1 Date: Thu, 04 Jun 2026 13:19:07 GMT Content-Type: application/json 
{"error":{"code":"Authorization_RequestDenied","message":"Insufficient privileges to complete the
operation.","innerError":{"date":"2026-06-04T13:19:08","request-id":"a9ca09db-40a9-4171-8dfe-b60ef02bada8","client-request-i
d":"7c1c3731-6eff-4a31-8bbb-c952bc09b3c5"}}}
PS 23:19:08 felixelliott@M23[MasterclassELDK26]# 
PS 23:19:08 felixelliott@M23[MasterclassELDK26]# 
PS 23:19:08 felixelliott@M23[MasterclassELDK26]# 