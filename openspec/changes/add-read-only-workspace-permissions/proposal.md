## Why

Navigator currently treats every non-empty workspace permission as full workspace access, so the existing permissions map can store `read` but cannot enforce read-only behavior. Workspace owners need to share threat models with reviewers and stakeholders who can inspect live content and exports without being able to change persisted records, shared drafts, relationships, diagrams, permissions, API keys, or analysis jobs.

## What Changes

- Define explicit workspace roles and capabilities: owners can manage and edit, writers can edit workspace threat-model content, readers can view, receive live updates, and export, and unknown or absent roles have no access.
- Add `Read` as an owner-selectable collaboration permission alongside `Write` and `None`, and reject unsupported stored permission values.
- Enforce current write permission at server-side mutation boundaries instead of relying on mount-time LiveView assigns or hidden controls.
- Render workspace editors and entity surfaces in a clearly indicated read-only mode, while retaining navigation, filtering, reporting, inspection, real-time updates, and downloads.
- Prevent readers from changing persistent records, relationships, workspace-scoped caches or draft state, diagrams, reference-pack imports, brainstorm content, API keys, collaboration settings, or persisted/background analysis jobs.
- Re-evaluate connected sessions when permissions change so downgrades take effect without requiring a reconnect and removals end workspace access.
- Ensure read-only page loads do not create missing workspace records as a side effect, including an absent data flow diagram.
- Preserve owner-only workspace settings, collaboration management, repository-analysis lifecycle actions, and API-key administration.
- Preserve API-key-authenticated API and MCP behavior; API keys remain owner-managed and workspace-scoped rather than inheriting an interactive collaborator role.

Non-goals:

- Replacing the existing workspace permissions map with invitations or a normalized membership table.
- Adding commenter, approver, custom, or field-level roles.
- Adding a separate export/download permission.
- Redesigning user discovery or allowing invitations before a user has signed in.
- Introducing AI-spend controls; non-mutating, user-private assistant interactions may remain available to readers, but they cannot persist generated content or start persisted workspace analysis jobs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `collaboration-and-access`: Define read-only workspace access, explicit role capabilities, owner-managed Read assignment, write-time authorization, read-only presentation, live permission changes, and owner-only settings behavior.
- `ai-assisted-analysis`: Require write access for workspace-persisted brainstorm changes and threat-model quality-review creation while allowing readers to inspect existing results.
- `threat-model-quality-review`: Require write access to start a quality-review run and preserve read access to completed or active review information without allowing lifecycle mutations.

## Impact

- Affects workspace permission resolution and updates under `Valentine.Composer.Workspace` and `Valentine.Composer.Workspaces`.
- Adds reusable authorization checks at workspace-scoped mutation boundaries across Composer contexts and workspace LiveViews/components.
- Affects workspace routes and user interfaces for rich-text documents, data flow diagrams, assumptions, mitigations, threats, evidence, threat agents, brainstorm items, reference packs, relationship linking, quality reviews, collaboration, API keys, and workspace settings.
- Requires read-only support in the Quill and Cytoscape browser hooks while preserving incoming collaborative updates.
- Requires permission-change PubSub behavior for connected sessions and protection against stale mount-time roles.
- No permission-schema migration is required because the existing map can store `read` and `write`. A compatibility check or data cleanup should treat unknown legacy values as unauthorized; a DFD backfill is optional if implementation chooses eager diagram initialization instead of a non-writing read path.
- Requires domain, ConnCase, LiveView, and JavaScript tests, followed by `make fmt`, `make test`, and manual role-matrix verification.
