## Context

Workspace access is currently represented by `Workspace.owner` plus a PostgreSQL map field whose keys are user identities and whose values are opaque strings. `Workspace.check_workspace_permissions/2` returns `owner` for the owner and otherwise returns the stored value. `Workspaces.list_workspaces_by_identity/1` checks only whether the identity key exists, while `ValentineWeb.Helpers.RbacHelper` permits every non-`nil` value and assigns it to the LiveView socket.

The collaboration screen writes `write` or removes access, but tests and the schema already demonstrate that `read` can be stored. There is no shared definition of what a role permits, unsupported strings are accepted, and most Composer mutation functions do not receive an actor identity. LiveViews generally trust the access check performed at mount time.

This matters beyond visible Save and Delete actions. Application-information and architecture changes enter workspace-scoped caches and PubSub before save, and data-flow interactions alter shared cached diagram state on drag, connect, import, undo, and related events. Readers must not be able to affect these shared drafts. Permission changes also need to affect already-connected LiveView sessions.

The principal implementation anchors are:

- `Valentine.Composer.Workspace` and `Valentine.Composer.Workspaces` for role resolution, validation, identity-scoped listing, and authorization.
- `ValentineWeb.Helpers.RbacHelper` and `ValentineWeb.Router` for route entry and socket capability assignment.
- Workspace LiveViews and components under `valentine/lib/valentine_web/live/workspace_live/` for write-only routes, mutation handlers, and read-only rendering.
- `Valentine.Composer.DataFlowDiagram`, the Quill hook, and the Cytoscape hook for shared draft behavior.
- `Valentine.ThreatModelQualityReview`, `Valentine.RepoAnalysis`, and `Valentine.Composer.ApiKeys` for privileged or persisted job and credential operations.
- `ValentineWeb.WorkspaceController` for read-authorized downloads.

## Goals / Non-Goals

**Goals:**

- Give workspace owners a supported `read` collaborator role.
- Define one role-capability model for read, write, and owner/manage authorization.
- Enforce current authorization on the server for every interactive workspace mutation, including shared cache and draft changes.
- Preserve read access to workspace pages, entity details, reports, filters, live updates, and exports.
- Make read-only state obvious and remove or disable mutation affordances without treating UI state as the security boundary.
- Apply permission downgrades and removals to connected sessions.
- Preserve current API-key and MCP authorization semantics.
- Avoid a database schema migration and remain compatible with the existing permissions map.

**Non-Goals:**

- Replacing the permissions map with a membership or invitation table.
- Adding comments, approvals, custom roles, or field-level authorization.
- Separating view and export permissions.
- Allowing invitations for identities that have never signed in.
- Reworking the identity-provider or API-key authentication models.
- Adding AI budget or quota policy.

## Decisions

### 1. Keep the permissions map and make role semantics explicit

`owner` remains an effective role derived from `Workspace.owner`. The only valid stored roles are `read` and `write`; `none` remains an update command that removes the identity key and is never stored. Unknown values resolve to no access.

`Valentine.Composer.Workspace` will expose pure role/capability functions, and `Valentine.Composer.Workspaces` will expose database-backed authorization functions for `:read`, `:write`, and `:manage`. The identity-scoped workspace query will require a valid readable stored value instead of accepting any key.

Permission updates will use a dedicated changeset or context operation rather than the general workspace update path. The operation will accept the acting identity, verify that it is the current workspace owner, validate the target role, and prevent arbitrary role strings from entering the map. Workspace creation can continue to initialize an empty map.

This retains the existing storage and query model while closing the current fail-open behavior. A normalized membership table was considered but deferred because it adds migration, association, and invitation semantics that are unnecessary for three roles.

### 2. Re-authorize at mutation boundaries

Mount-time authorization remains responsible for initial route access and for assigning presentation capabilities, but it is not authoritative for writes. Every workspace mutation initiated by an interactive user will pass the current identity and workspace identifier through a database-backed write or manage authorization check immediately before changing state.

Composer contexts should expose actor-aware, workspace-scoped command functions for web entry points. Existing low-level persistence functions may remain for trusted internal workflows, fixtures, imports, API-key-authenticated tools, and background jobs, but LiveViews and components must not call them without an authorization boundary. Checks must cover both `handle_event` mutations and mutation-producing `handle_info` messages from components such as Quill.

This is preferred over a global LiveView `handle_event` hook. A hook would require a fragile allowlist of local-only events, would not naturally cover component-generated messages, and could miss mutation paths that begin in `handle_info`. It is also preferred over UI-only hiding, which does not protect forged events or stale sockets.

Unauthorized mutations return a consistent error result, leave persistent and cached state unchanged, and provide a user-facing read-only or access-changed message where appropriate.

### 3. Derive presentation capabilities once, but pass them explicitly

`RbacHelper` will assign the effective role plus booleans such as `can_write` and `can_manage` for rendering. Workspace LiveViews will pass read-only state to nested LiveComponents rather than assuming component assigns are inherited.

Read-only users retain list/detail routes, filtering, local selection, reports, print views, downloads, and incoming real-time updates. Write-only routes such as create flows, relationship editors, categorization, reference-pack import, Mermaid confirmation, and API-key generation will redirect readers to the nearest readable route. Routes whose current LiveView action is named `:edit` but also serves as the only entity detail page, notably threat and evidence pages, remain readable and render without mutation controls.

The application layout will display a read-only indicator. Owner-only navigation such as API-key management is hidden from non-owners, while the collaboration page may remain readable so collaborators can see their role and workspace owner.

### 4. Make browser editors genuinely read-only

The Quill component and `assets/vendor/quill-hook.js` will accept a read-only data attribute. In read-only mode Quill disables editing and does not emit local change or save events, while still accepting server-pushed remote content updates.

The data-flow component and `assets/vendor/cytoscape-hook.js` will accept the same capability. Readers may select nodes and edges and inspect metadata, but nodes are not grabbable, edge creation and editing are disabled, and graph mutation events are not pushed. The LiveView still authorizes all server-side diagram mutations in case a client forges an event.

Brainstorm drag/drop, inline editing, clustering, status changes, item generation, and type reordering are disabled for readers. Filters, searches, local expansion, and inspection remain available.

### 5. Separate data-flow reads from initialization

`DataFlowDiagram.get/1` currently creates a persisted diagram when none exists. A read-only mount must not write merely by viewing a workspace. Add a non-creating load path that returns the existing diagram or an empty, unsaved representation suitable for rendering. Writers can initialize and persist a missing diagram on the first authorized mutation.

This avoids a data backfill and keeps rollout simple. Eager initialization at workspace creation was considered, but it would still require handling legacy workspaces and imported records that lack a diagram.

### 6. Broadcast permission changes and still distrust socket state

Successful permission updates will broadcast on a workspace permission topic. Connected workspace LiveViews will re-resolve the current role:

- Write-to-read downgrades switch to read-only presentation immediately.
- Read-to-write upgrades expose writer controls without reconnecting.
- Removal redirects or disconnects the collaborator from protected workspace routes.

PubSub is an experience optimization, not the authorization boundary. Database-backed checks on mutation protect against lost broadcasts, races, multi-node delivery delays, and forged socket state.

### 7. Treat persisted analysis jobs and privileged settings as writes

Readers can inspect existing repository-analysis and threat-model quality-review status and findings, but cannot start, retry, cancel, or delete jobs. Threat-model quality-review creation will require current write access. A workspace owner can manage workspace review runs; an initiating writer can manage their own run only while they retain write access.

Workspace metadata editing, collaboration updates, API-key listing/generation/deletion, and repository-import lifecycle actions remain owner-managed. API-key routes authorize before loading key records, and deletion receives the same owner check as generation.

Non-mutating, user-private assistant questions may remain available to readers. Any assistant action that inserts into a shared editor, changes workspace content, or starts a persisted job requires write access.

### 8. Keep exports readable and API-key behavior unchanged

Browser controller exports continue to use read authorization, so readers can download JSON, markdown, Excel, and Mermaid representations. There is no separate export role.

API and MCP calls continue to authenticate through active, workspace-scoped API keys. Interactive collaborator roles do not change the authority of an already-issued key. Because only owners can list or administer keys, read-only sharing does not expose credential-management capabilities.

## Risks / Trade-offs

- **[Missed mutation path]** A reader could alter an entity, relationship, cache, or job through an unguarded event or component message. → Inventory all workspace `handle_event` and mutation-producing `handle_info` paths, route them through actor-aware context commands, and add forged-event regression tests per mutation domain.
- **[Increased database queries]** Rechecking current permission before mutations adds a query to interactive writes. → Keep reads and local UI events query-free, centralize the indexed primary-key lookup, and optimize only after measuring; correctness under revocation takes priority.
- **[Stale UI after lost PubSub]** A socket may continue displaying obsolete controls. → Authorize writes from current database state and treat PubSub only as presentation synchronization.
- **[Legacy permission values]** Existing unknown values will stop granting access. → Audit distinct map values before enabling strict resolution, document affected identities, and convert only confirmed values to `read` or `write`.
- **[Deployment compatibility]** A node running older permission semantics would treat a stored `read` value as full access. → Ship Read assignment and enforcement together and verify the deployment does not retain nodes running the older semantics.
- **[Read-only editor regressions]** Disabling local events could accidentally prevent incoming collaborative updates or inspection. → Add JavaScript tests for remote Quill updates and selectable-but-nonmutable Cytoscape behavior, plus LiveView collaboration tests.
- **[Rollback hazard]** Rolling back to current code while `read` entries exist would turn those users into full collaborators. → Before rollback, remove or convert every stored `read` entry, or first deploy a compatibility patch that denies `read` on the old branch.
- **[Quality-review ownership edge cases]** A writer may lose permission while a run they started is active. → Permit the workspace owner to manage workspace review runs and require the initiating user to retain write access for lifecycle actions.

## Migration Plan

1. Audit stored permission values and confirm that production maps contain only expected values; resolve unknown values before strict authorization is enabled.
2. Deploy role resolution, current-state mutation authorization, read-only rendering support, permission PubSub, and the Read assignment control together. No feature flag or follow-up enablement is required.
3. Verify owner, writer, and reader behavior and exercise direct/forged reader mutation tests across all workspace domains.
4. Monitor unauthorized mutation logs, permission-change handling, LiveView disconnects, and editor collaboration behavior.

No database schema migration is required. If rollback is necessary after Read has been assigned, first remove or convert all `read` map entries or deploy a deny-read compatibility patch before restoring code that treats arbitrary non-`nil` roles as writable.

## Open Questions

None. This proposal selects strict no-mutation semantics for readers, permits exports and non-mutating personal assistant queries, and keeps API-key authorization independent from interactive collaborator roles.
