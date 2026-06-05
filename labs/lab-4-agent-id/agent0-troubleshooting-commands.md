# Agent0 troubleshooting commands

Run these commands from the Agent0 server folder:

```bash
cd labs/lab-4-agent-id/agent-0/server
```

## Check required environment variables

This prints only whether each variable exists and its length. It does not print secret values.

```bash
node - <<'NODE'
import dotenv from 'dotenv';
dotenv.config();

for (const k of [
  'OPENAI_API_KEY',
  'ENTRA_TENANT_ID',
  'AGENT_BLUEPRINT_ID',
  'AGENT_IDENTITY_ID',
  'ENTRA_CLIENT_SECRET'
]) {
  console.log(k, Boolean(process.env[k]), process.env[k]?.length || 0);
}
NODE
```

PowerShell-safe one-liner alternative:

```powershell
node -e 'import("dotenv").then(({default:d})=>{d.config(); for (const k of ["OPENAI_API_KEY","ENTRA_TENANT_ID","AGENT_BLUEPRINT_ID","AGENT_IDENTITY_ID","ENTRA_CLIENT_SECRET"]) console.log(k, Boolean(process.env[k]), process.env[k]?.length || 0)})'
```

## Test OpenAI API key

This checks whether the configured OpenAI API key can call the OpenAI models endpoint. It prints only the HTTP status and the first 500 characters of the response.

```bash
node - <<'NODE'
import dotenv from 'dotenv';
dotenv.config();

const r = await fetch('https://api.openai.com/v1/models', {
  headers: { Authorization: `Bearer ${process.env.OPENAI_API_KEY}` }
});

console.log(r.status, r.statusText);
console.log((await r.text()).slice(0, 500));
NODE
```

Expected result:

```text
200 OK
```

If the response is `401`, `403`, `429`, `insufficient_quota`, or similar, the chat failure is likely caused by the OpenAI key, quota, or model access rather than Agent ID.
