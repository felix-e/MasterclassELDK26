# Lab 4 Lesson Learned — Microsoft Entra Agent ID / Agent0

Date: 2026-06-05

## What Lab 4 is actually demonstrating

Lab 4 is not mainly about building a sophisticated AI assistant. It demonstrates the identity plumbing for an AI agent:

- A user signs in to a frontend SPA.
- The SPA requests a token for an Agent Blueprint API scope.
- The backend validates that token.
- The backend uses the Agent Identity / Agent Blueprint relationship to perform a two-stage Agent ID token exchange.
- The Agent Identity receives a Microsoft Graph token and calls `/me` on behalf of the signed-in user.

The meaningful test prompt is:

```text
Who am I?
```

Weather questions do not work because Agent0 has no weather tool/API. The app only includes a `getUserInfo` tool for Microsoft Graph user profile lookup.

## Main issue found

The Entra **Agent Blueprint Preview UI** could create:

- Agent Blueprint
- Agent Blueprint Principal
- Agent Identity
- credentials

However, it did **not expose the normal App Registration > Expose an API UX** for the Agent Blueprint.

Graph initially showed the Agent Blueprint had:

```json
"identifierUris": [],
"oauth2PermissionScopes": [],
"requiredResourceAccess": []
```

Because of that, the frontend failed to acquire an API token and Safari console showed:

```text
AADSTS500011: The resource principal named api://<blueprint-app-id> was not found
```

## Required Graph fixes

The Agent Blueprint needed to be configured as an API resource:

```text
Application ID URI:
api://<agent-blueprint-app-id>

Scope:
access_agent_as_user
```

The SPA app then needed that scope in its required API permissions:

```text
api://<agent-blueprint-app-id>/access_agent_as_user
```

After that, the frontend could acquire the Agent API token.

## Second issue found

Once the chat/model worked, `Who am I?` still failed because the Agent Identity had no Microsoft Graph permission path.

Graph showed:

```text
Blueprint requiredResourceAccess: []
Blueprint inheritablePermissions: []
Blueprint principal oauth2PermissionGrants: []
Agent identity oauth2PermissionGrants: []
```

The fix was to configure the Agent Blueprint with Microsoft Graph delegated `User.Read`:

1. Add `User.Read` to blueprint `requiredResourceAccess`.
2. Add Microsoft Graph delegated scopes to blueprint `inheritablePermissions`.
3. Grant `User.Read` admin consent to the Agent Blueprint Principal.

After those were applied, `Who am I?` worked.

## Working object IDs from this run

Agent Blueprint app ID:

```text
fc88cc4a-7f0f-44cb-9daa-5dd43fd79787
```

Agent Blueprint Principal object ID:

```text
d602944c-7946-4418-bb8e-e576c31035e0
```

Agent Identity app/object ID:

```text
de804499-013a-4531-85ba-8fb6f0b7d689
```

SPA app ID:

```text
2bac42c6-25df-4818-9d3a-83c11b1ac088
```

SPA object ID:

```text
6452eeb6-602e-443c-bc9d-2d77102617d1
```

## App/config lessons

### 1. Backend URL behavior

`http://localhost:3000` is the Fastify API server only. It has no homepage, so this is expected:

```json
{"message":"Route GET:/ not found","error":"Not Found","statusCode":404}
```

The UI runs at:

```text
http://localhost:8080
```

### 2. Frontend `.env` location

The Vite config uses:

```ts
envDir: '../'
```

So frontend env vars must exist in:

```text
agent-0/.env
```

not only:

```text
agent-0/client/.env
```

### 3. MSAL initialization

The client hit:

```text
uninitialized_public_client_application
```

Fix: call and await MSAL initialization before rendering the app:

```ts
await msalInstance.initialize()
```

### 4. Model selection

OpenAI model access was not the root issue. Model test calls succeeded for:

```text
gpt-4o-mini
gpt-4.1-mini
gpt-4o
```

The app was updated to use these as model fallbacks.

Recommended default for this lab:

```text
gpt-4o-mini
```

## Microsoft preview workflow observations

`Invoke-EntraBetaAgentIdInteractive` was confusing and unreliable in this run. The wizard mixed together:

- blueprint creation
- credential creation
- interactive agent scope
- Agent User creation
- inheritable permissions
- static/dynamic permissions
- admin consent
- Agent Identity creation

The Entra Agent blade is still marked Preview, and the UI did not expose all normal app registration configuration needed by Agent0.

Recommended approach for the lab:

1. Use the Entra UI to create the Agent Blueprint and Agent Identity.
2. Use Graph to verify and patch missing API exposure and permission/inheritance settings.
3. Use the app only after confirming Graph object state.

## Troubleshooting checklist

If chat says:

```text
Failed to get access token
```

Check:

- Agent Blueprint has `identifierUris` set.
- Agent Blueprint has `access_agent_as_user` exposed scope.
- SPA app has required permission to that scope.
- User has logged out/in after changes.

If `Who am I?` fails after chat works:

Check:

- Blueprint `requiredResourceAccess` includes Graph `User.Read`.
- Blueprint `inheritablePermissions` includes Microsoft Graph scopes.
- Blueprint principal has an OAuth2 permission grant for `User.Read`.

If weather fails:

That is expected. Agent0 has no weather tool.

## Security note

Secrets were exposed during troubleshooting. Any pasted Entra client secrets or OpenAI API keys should be rotated/deleted before committing or sharing logs.
