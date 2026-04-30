---
name: navigator-threat-modeler
description: Create detailed, codebase-driven threat models in Navigator through the Navigator MCP server. Use when a user asks Codex to review an application or repository, inspect architecture/security-relevant code, populate or refine Navigator application information, architecture, DFDs, assumptions, threats, mitigations, and links, or run a thorough long-running threat-modeling workflow without losing quality across phases.
---

# Navigator Threat Modeler

## Overview

Use this skill to turn a codebase review into a high-quality Navigator threat model through MCP calls. Treat Navigator as the system of record, and use the repository as evidence for architecture, trust boundaries, threats, assumptions, and mitigations.

Do not treat this as a single prompt-writing exercise. Run it as a phased review with checkpoints, small write batches, and verification after every meaningful model update.

## Required Inputs

- A target Navigator workspace reachable through the `navigator` MCP tools.
- A repository or codebase to inspect.
- Permission to write threat-model records through MCP.

If the MCP tools are unavailable, ask the user to configure the Navigator MCP server before writing model records. If the codebase is unavailable, create only a high-level model and mark uncertain statements as assumptions.

## Workflow

### 1. Establish Scope

1. Call `get_workspace` and read existing application information, architecture, DFD, assumptions, mitigations, and threats.
2. Identify whether the task is to create a new model, deepen an existing one, or repair quality issues.
3. Define review scope in plain terms: application boundaries, deployment assumptions, external services, user roles, sensitive assets, and what will not be reviewed.
4. Use `update_plan` for long jobs. Keep exactly one step in progress.

### 2. Inspect The Codebase

Start with fast inventory before reading deeply:

```bash
rg --files
```

Then inspect security-relevant entry points and data paths. For Phoenix/Navigator-style apps, prioritize:

- Router, endpoint, plugs, controllers, LiveViews, channels, and API controllers.
- Authentication, authorization, API key, session, CSRF, CORS, and rate-limit code.
- Domain contexts, schemas, migrations, relationship/linking functions, and import/export code.
- Background jobs, external integrations, AI/provider calls, repository access, file uploads, markdown/HTML rendering, Mermaid/diagram rendering, and logging/telemetry.
- Tests covering authz, cross-workspace access, imports, destructive actions, and API/MCP behavior.

Capture evidence as short notes: file path, behavior, trust boundary, data type, and security implication. Do not create threats from vibes alone.

### 3. Draft The Architecture And DFD

Create or update application information and architecture only after codebase inventory. Keep them factual, concise, and evidence-backed.

For DFDs, use only Navigator-supported node types:

- `actor`
- `process`
- `datastore`
- `trust_boundary`

Model external services as `actor` unless they are internal processes or datastores controlled by the application. Read `references/mcp-field-contracts.md` before updating DFD nodes, edges, or threats.

### 4. Discover Threats In Passes

Work by trust boundary and data flow, not by guessing a list of generic web risks. For each flow or boundary, check:

- Spoofing: identity, API keys, sessions, OAuth, webhook authenticity.
- Tampering: imports, rich text, DFD data, relationship links, background jobs, generated outputs.
- Repudiation: auditability, destructive operations, API key attribution, job provenance.
- Information disclosure: tenant data, repository content, prompts, logs, exports, backups.
- Denial of service: expensive analysis, uploads/imports, tool loops, fan-out jobs, large diagrams.
- Elevation of privilege: cross-workspace access, role/permission bypass, confused deputy paths.

Also consider prompt injection and agentic misuse when MCP, AI analysis, repository analysis, or generated recommendations can write back into the model.

Use `references/review-checklist.md` for detailed prompts and quality gates.

### 5. Write To Navigator In Batches

Prefer this order:

1. Update application information and architecture.
2. Update the DFD.
3. Create assumptions.
4. Create mitigations.
5. Create threats in batches of 5 to 8.
6. Link threats to assumptions and mitigations.
7. Re-read and repair records after each batch.

Use MCP tools only for Navigator writes. Do not write directly to the database or bypass Navigator validations.

### 6. Threat Statement Contract

Navigator renders threat statements from structured fields. Do not include the words Navigator adds for you.

Use this grammar:

`A/An [threat_source] [prerequisites] can [threat_action], which leads to [threat_impact], resulting in reduced [impacted_goal], negatively impacting [impacted_assets].`

Field rules:

- `threat_source`: actor phrase only. No leading `a`, `an`, or `the`.
- `prerequisites`: condition phrase only. Do not include `can`.
- `threat_action`: verb phrase only. No subject, no modal verb, no leading `can`.
- `threat_impact`: direct impact phrase only. Do not include `which leads to`.
- `impacted_goal`: use security goals such as `confidentiality`, `integrity`, `availability`, `accountability`, `privacy`.
- `impacted_assets`: concrete assets such as workspace data, sessions, source code, API keys, prompts, exports, or database records.

Good:

```text
threat_source: attacker with access to a leaked MCP API key
prerequisites: who has obtained a valid workspace-scoped bearer token
threat_action: call mutating MCP tools to alter model records
threat_impact: unauthorized modification of threat model records
```

Bad:

```text
threat_source: An attacker with access to a leaked MCP API key
threat_action: can call mutating MCP tools
threat_impact: which leads to unauthorized modification
```

### 7. Verify And Repair

After each batch:

1. Re-read the affected records through MCP.
2. Check rendered threat statements for duplicated articles, duplicated `can`, or duplicated `which leads to`.
3. Export Mermaid and confirm every DFD node uses a supported type.
4. Confirm all high-priority threats have at least one mitigation or an explicit explanation.
5. Confirm assumptions are not being used to hide known gaps.
6. Confirm links are useful and not just dense.

If the export shows awkward statements or unsupported DFD nodes, repair them before continuing.

## Long-Running Job Guardrails

- Make progress in visible phases. Report what was reviewed, what remains, and what was written.
- Do not hoard all findings until the end. Commit batches to Navigator after they have passed a quick local quality check.
- Keep each threat evidence-backed with a short comment. Include a file path or implementation area when possible.
- Avoid duplicate threats. Merge when the same actor/action/impact repeats across multiple features.
- Prefer fewer precise threats over many generic ones, but do not stop at a compact model if the user asked for a thorough review.
- If context becomes large, summarize the current inventory, completed MCP writes, unresolved questions, and next batch before continuing.

## Completion Criteria

A detailed Navigator threat model is complete when:

- Application information and architecture reflect the reviewed codebase.
- The DFD covers major actors, processes, datastores, external services, trust boundaries, and security-relevant data flows.
- Assumptions describe uncertain deployment, operational, and trust facts.
- Threats cover important trust boundaries and high-risk code paths with valid Navigator grammar.
- Mitigations are linked to the threats they address.
- The final verification pass finds no malformed threat statements, unsupported DFD node types, or obvious orphaned high-priority risks.
