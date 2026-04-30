# Codebase Threat Modeling Checklist

Use this reference during a detailed codebase review. It is a prompt set, not a quota.

## Application Boundary

- Who can use the system: anonymous users, authenticated users, admins, API clients, MCP clients, background workers, external services.
- What trust boundary each request crosses: browser/session, API key, webhook, job queue, database, third-party integration, AI provider, repository provider.
- What data is sensitive: tenant/workspace data, source code, prompts, generated analysis, evidence, controls, logs, API keys, OAuth tokens, session cookies.

## Authentication And Session Review

- Login, logout, callback, session renewal, and passwordless/OAuth flows.
- Session cookie flags, CSRF handling, redirect validation, token lifetime, revocation, and replay handling.
- Differences between browser auth, API key auth, service auth, and internal job auth.

## Authorization And Tenant Isolation

- Every read/write path that accepts IDs belonging to workspace-scoped records.
- Update/delete/link/unlink actions, especially many-to-many relationships.
- Import/export operations that can smuggle IDs, ownership, or references.
- Tests proving cross-workspace denial for representative operations.

## Input, Rendering, And Import/Export

- Rich text, markdown, Mermaid, JSON import, diagram nodes/edges, tags, comments, file uploads.
- Stored XSS, content spoofing, unsafe HTML attributes, malformed graph data, large payloads.
- Export consumers: Markdown, JSON, Mermaid, PDF, browser UI, AI prompts.

## AI, Agentic, And MCP Workflows

- Prompt injection from repository content, workspace content, imported content, or external services.
- Tool misuse: destructive MCP calls, high-volume writes, update/delete/link loops, workspace confusion.
- Data minimization for prompts sent to providers.
- Provenance and user confirmation for generated suggestions that become records.

## Background Jobs And External Integrations

- Job enqueue authorization, job status visibility, cancellation, retries, idempotency, and fan-out.
- GitHub/repository tokens, OAuth scopes, URL validation, branch/ref handling, and source persistence.
- Provider failure modes, timeouts, rate limits, and partial writes.

## Storage, Secrets, Logs, And Operations

- API key storage, token hashing, last-used tracking, revocation, secret rotation.
- Database backups, logs, telemetry, crash reports, and exported artifacts.
- Migration defaults, unique constraints, foreign keys, cascading deletes, and soft-delete behavior.

## Threat Quality Rubric

Each threat should answer:

- Actor: who performs the action?
- Preconditions: what access or condition is required?
- Action: what do they do?
- Impact: what directly happens?
- Security goal: what is reduced?
- Asset: what concrete thing is harmed?
- Evidence: what code path, feature, or observed behavior supports it?
- Mitigation: what reduces the likelihood or impact?

Prioritize high when the threat can cross tenant boundaries, expose secrets/source/data at scale, enable destructive writes, or bypass a core authorization boundary.

Prioritize medium when exploitation is plausible but scoped, requires meaningful preconditions, or affects integrity/availability without broad compromise.

Prioritize low when impact is limited, already strongly mitigated, or mostly operational hygiene.
