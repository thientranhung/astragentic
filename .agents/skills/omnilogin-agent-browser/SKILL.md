---
name: omnilogin-agent-browser
description: Open and reuse an OmniLogin antidetect-browser profile through its local API, expose a stable CDP port, and hand the browser to agent-browser for website automation. Use when the user names OmniLogin, Omni browser, an OmniLogin profile, or asks to automate a site with an OmniLogin fingerprint, proxy, cookie session, or existing profile. Handle only the minimal profile/browser lifecycle by default; inspect the bundled omnilogin-swagger.json only for deeper OmniLogin operations.
argument-hint: "[profile name and browser task]"
---

# OmniLogin Agent Browser

Use OmniLogin for profile identity, fingerprint, proxy, cookies, and browser
lifecycle. Use `agent-browser` for navigation and page interaction after CDP is
ready.

```text
OmniLogin local API -> OmniLogin profile + CDP -> agent-browser
```

Keep the default path lightweight. Do not load the full Swagger document unless
the requested OmniLogin operation falls outside the core workflow below.

When invoked directly as `/omnilogin-agent-browser`, treat `$ARGUMENTS` as
additional task details. If no arguments are supplied, use the current user
request.

## Core API

Use `http://127.0.0.1:35353` as the local API base.

| Purpose | Request |
|---|---|
| Find profiles | `GET /profiles?q=<name>&page=1&pageSize=100` |
| Create a profile | `POST /profiles` |
| Check browser state | `GET /active/{profile_id}` |
| Open browser with CDP | `GET /open?profile_id=<id>&remote_debug_port=<port>` |
| Stop browser | `GET /stop/{profile_id}` |

Treat profile creation and stopping as mutations. Create only when the user asks
for a new profile or approves creation. Stop only when requested or when the
task explicitly requires cleanup.

## Open a profile

### 1. Check the local API

```bash
curl -fsS --max-time 10 \
  "http://127.0.0.1:35353/profiles?page=1&pageSize=1"
```

If the connection fails, tell the user to open and sign in to the OmniLogin
desktop application. Do not claim that a profile or browser is available.

### 2. Resolve the exact profile

Prefer an explicit profile ID. Otherwise URL-encode the requested name and
query profiles:

```bash
curl -fsS --max-time 10 \
  "http://127.0.0.1:35353/profiles?q=<encoded-name>&page=1&pageSize=100"
```

Filter `docs` by exact `name`; do not trust fuzzy search order. Continue only
when exactly one profile matches. If duplicate exact names exist, show their
IDs and ask which one to use.

If no exact profile exists:

- Create it only when creation is explicit.
- Otherwise report that it is missing and ask whether to create it.

Use a minimal creation payload unless the user specifies fingerprint or proxy
settings:

```bash
curl -fsS --max-time 15 \
  -X POST "http://127.0.0.1:35353/profiles" \
  -H "Content-Type: application/json" \
  --data-binary '{
    "name": "<profile-name>",
    "account": {
      "notes": "Created for browser automation",
      "userDataType": "automatic"
    }
  }'
```

Use the returned `id`. Do not create a second profile to recover from a
response-parsing or connection error; query by exact name again first.

### 3. Resolve a CDP port

Prefer, in order:

1. A port explicitly supplied by the user.
2. A port already established in the current task for this profile.
3. Port `49331` when opening the only profile and the port is free.

Use a different port for every concurrently running profile. Before opening an
inactive profile, confirm the chosen port is not serving another browser:

```bash
curl -fsS --max-time 2 "http://127.0.0.1:<port>/json/version"
```

A successful response means the port is occupied. Do not attach it to a
different profile by assumption.

### 4. Check whether the browser is active

```bash
curl -fsS --max-time 10 \
  "http://127.0.0.1:35353/active/<profile_id>"
```

If the result is `false`, open the profile:

```bash
curl -fsS --max-time 45 \
  "http://127.0.0.1:35353/open?profile_id=<profile_id>&remote_debug_port=<port>"
```

Require `status: true`, then take the actual port from
`remote_debug_address`. Do not add `launch_bridge=true`; agent-browser uses CDP,
not OmniBridge.

If the result is `true`, reuse only a CDP port already known for that profile.
The active endpoint returns no port. If no port is known, do not probe arbitrary
CDP ports or attach to an unrelated browser. Explain the ambiguity and ask
whether to stop and reopen the profile on a known port.

### 5. Verify CDP and hand off to agent-browser

```bash
curl -fsS --max-time 10 \
  "http://127.0.0.1:<port>/json/version"
```

Load the installed agent-browser instructions that match the current CLI:

```bash
agent-browser skills get core
```

Inspect existing tabs before navigating:

```bash
agent-browser --session "omni-<profile_id>" --cdp <port> tab
```

Continue the requested website task with the same `--session` and `--cdp`
values. Use the agent-browser snapshot-and-ref workflow. Do not use
`agent-browser --profile`; OmniLogin owns the browser profile and persistent
state.

## Stop a profile

Stop only the resolved profile ID:

```bash
curl -fsS --max-time 15 \
  "http://127.0.0.1:35353/stop/<profile_id>"
```

Confirm `/active/<profile_id>` becomes `false`. Never kill all Chrome or
OmniLogin processes as a shortcut.

## Inspect deeper OmniLogin APIs only when needed

Use the Swagger fallback for proxy, fingerprint, clone, tags, groups, workflow,
AI App, IPv6, MCP, or any undocumented response. The Swagger document ships with
this skill at `references/omnilogin-swagger.json`, relative to this file. Prefer
that copy; fall back to an `omnilogin-swagger.json` in the active workspace only
when the bundled one is missing.

Avoid printing or reading the whole file. Query only the relevant path and
referenced schema. Examples:

```bash
jq '.paths["/profiles/{profileId}/fingerprint"].put' \
  references/omnilogin-swagger.json
```

```bash
jq '.definitions.UFingerprints' references/omnilogin-swagger.json
```

When the correct endpoint is unknown, list path names first:

```bash
jq -r '.paths | keys[]' references/omnilogin-swagger.json
```

Then read only the selected method and its referenced definitions. Treat the
Swagger file as API truth; do not invent fields or accepted enum values.

## Safety and reporting

- Keep the OmniLogin API and CDP bound to localhost.
- Never print cookie values, proxy passwords, API keys, or session tokens.
- Require explicit authorization before deleting profiles, proxies, or groups.
- Preserve the profile's OmniLogin-managed cookie and storage state.
- Report the exact profile name, ID, CDP port, active state, and whether the
  browser was left open.
- Distinguish profile creation, browser launch, CDP verification, and website
  automation instead of reporting them as one success.
