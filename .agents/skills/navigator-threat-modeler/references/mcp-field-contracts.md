# Navigator MCP Field Contracts

Load this reference before creating or updating Navigator DFD records or threats.

## Threat Statement Fields

Navigator renders a full sentence from structured fields:

`A/An [threat_source] [prerequisites] can [threat_action], which leads to [threat_impact], resulting in reduced [impacted_goal], negatively impacting [impacted_assets].`

Enter only the field fragments. Do not include words supplied by the renderer.

| Field | Use | Avoid |
|---|---|---|
| `threat_source` | Actor phrase: `attacker with a leaked API key`, `malicious workspace collaborator` | Leading articles: `An attacker`, `the user` |
| `prerequisites` | Condition phrase: `who has obtained a valid bearer token`, `with write access to the workspace` | Modal verbs: `can access`, `can modify` |
| `threat_action` | Verb phrase: `modify workspace records through MCP`, `submit malicious rich text` | Subject/modal: `an attacker can modify`, `can modify` |
| `threat_impact` | Direct result: `unauthorized modification of threat records` | Connectors: `which leads to unauthorized modification` |

Use `comments` for evidence, implementation notes, and uncertainty. Use `tags` for grouping.

## STRIDE Values

Use only these enum values:

- `spoofing`
- `tampering`
- `repudiation`
- `information_disclosure`
- `denial_of_service`
- `elevation_of_privilege`

## DFD Node Types

Navigator currently supports only these node types:

- `actor`
- `process`
- `datastore`
- `trust_boundary`

Model external systems, SaaS platforms, identity providers, AI providers, repository hosts, and MCP clients as `actor` unless they are controlled internal processes or datastores.

Good nodes:

```json
{
  "mcp_client": {"data": {"id": "mcp_client", "label": "MCP Client", "type": "actor"}},
  "phoenix_app": {"data": {"id": "phoenix_app", "label": "Phoenix Application", "type": "process"}},
  "postgres": {"data": {"id": "postgres", "label": "PostgreSQL Database", "type": "datastore"}}
}
```

Bad nodes:

```json
{
  "github": {"data": {"id": "github", "label": "GitHub", "type": "external_entity"}},
  "browser": {"data": {"id": "browser", "label": "Browser", "type": "user"}}
}
```

## Write Strategy

Before writing:

1. Check whether a semantically equivalent record already exists.
2. Prefer update over duplicate creation when improving existing records.
3. Keep IDs stable when updating DFD nodes and edges.
4. Batch related changes, then re-read through MCP.

After writing:

1. Export Mermaid to catch unsupported node types.
2. Read threats to catch malformed rendered statements.
3. Verify entity links are directional and useful.
