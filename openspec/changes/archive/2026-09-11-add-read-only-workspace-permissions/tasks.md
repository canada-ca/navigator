## 1. Role Model and Persistence Boundaries

- [x] 1.1 Add explicit `owner`, `write`, and `read` role resolution plus read/write/manage capability predicates to the workspace domain model, treating unknown stored values as unauthorized.
- [x] 1.2 Update identity-scoped workspace queries so only ownership or a valid `read`/`write` map value lists a workspace, and add DataCase coverage for valid, missing, and legacy-invalid values.
- [x] 1.3 Separate permission mutation from general workspace changes, validate `read`, `write`, and the non-stored `none` removal command, and prevent ordinary workspace updates from changing owner or permissions.
- [x] 1.4 Make permission updates actor-aware and owner-only, including tests for Read assignment, Write assignment, removal, unsupported values, forged non-owner updates, and owner-target edge cases.
- [x] 1.5 Add database-backed `:read`, `:write`, and `:manage` authorization functions with consistent unauthorized results and unit tests covering the complete role-capability matrix.

## 2. Route Access and Connected Permission State

- [x] 2.1 Update `ValentineWeb.Helpers.RbacHelper` to accept only valid readable roles and assign the effective role plus read/write/manage presentation capabilities.
- [x] 2.2 Add write- and manage-capability route guards for direct access to create, link, categorize, import, generation, workspace-settings, and API-key routes while preserving readable threat and evidence detail routes that use edit actions.
- [x] 2.3 Add ConnCase and LiveView tests for owner, writer, reader, unknown-role, and unshared identities across readable, write-only, manage-only, and export routes.
- [x] 2.4 Publish permission updates on a workspace-scoped topic and add a shared LiveView permission handler that re-resolves connected users, updates role capabilities on upgrades/downgrades, and redirects users whose access is removed.
- [x] 2.5 Test connected Write-to-Read, Read-to-Write, and removal transitions, including a stale writer socket whose next forged mutation is rejected from current database state.
- [x] 2.6 Add a global read-only indicator and capability-aware workspace navigation, including hiding API-key administration from non-owners without hiding readable collaboration ownership information.

## 3. Authorized Workspace Mutation Pattern

- [x] 3.1 Add reusable web/context helpers for invoking actor-aware workspace mutations and returning consistent read-only or access-changed errors without changing persistent or cached state.
- [x] 3.2 Inventory every workspace `handle_event` and mutation-producing `handle_info` path and classify it as local read interaction, content write, or owner/manage operation.
- [x] 3.3 Route interactive content writes through current database-backed write authorization and route settings, permission, credential, and owner-only job actions through manage authorization.
- [x] 3.4 Add shared forged-event test helpers that assert a reader mutation leaves the relevant record, association, cache, PubSub stream, or job unchanged.

## 4. Workspace Settings, Collaboration, and API Keys

- [x] 4.1 Add the Read radio option and explanatory copy to the collaboration screen, show collaborators only their role and owner information, and broadcast successful owner-managed changes.
- [x] 4.2 Enforce current owner authorization for workspace metadata updates and deletion, and hide or reject workspace edit/delete controls for writers and readers.
- [x] 4.3 Authorize API-key routes before loading key records and enforce current owner authorization for key generation and deletion as well as rendering.
- [x] 4.4 Add collaboration, workspace-form, workspace-deletion, and API-key LiveView tests for owner success plus reader/writer forged-event rejection.

## 5. Rich-Text Application and Architecture Documents

- [x] 5.1 Pass read-only capability through the application-information and architecture LiveViews into the Quill component, hide Save controls for readers, and continue applying incoming remote updates.
- [x] 5.2 Update the Quill browser hook to initialize non-editable readers without emitting local change or save events while preserving server-pushed blob and delta updates.
- [x] 5.3 Require current write authorization before application-information or architecture cache insertion, broadcast, create, update, save, flush, or assistant-driven shared insertion.
- [x] 5.4 Add LiveView tests proving forged reader Quill messages do not alter records, caches, or broadcasts and writer behavior remains collaborative.
- [x] 5.5 Add JavaScript tests for editable writer Quill behavior and non-editable reader behavior, including remote update handling in both modes.

## 6. Data Flow Diagram Read-Only Mode

- [x] 6.1 Add a non-creating data-flow load path that returns an empty renderable representation when no diagram exists, and test that a reader mount creates no database record.
- [x] 6.2 Require current write authorization for diagram cache mutations, history changes, persistence, raw-image updates, Mermaid confirmation, threat helper persistence, metadata changes, and linked-threat changes initiated by the web UI.
- [x] 6.3 Render diagram editing toolbars, metadata controls, Mermaid import confirmation, threat generation, and linking controls only for writers while keeping reader selection and inspection available.
- [x] 6.4 Update the Cytoscape hook so readers cannot drag, connect, delete, group, import, undo, redo, or emit mutation events but can select elements and receive remote graph refreshes.
- [x] 6.5 Add LiveView and Composer tests covering forged reader diagram events, shared-cache invariants, non-creating reads, writer persistence, and incoming collaborative updates.
- [x] 6.6 Add JavaScript tests for selectable non-mutating reader diagrams and unchanged writer graph-editing behavior.

## 7. Core Threat-Model Entities and Relationships

- [x] 7.1 Enforce current write authorization and read-only rendering for assumption and mitigation create, edit, delete, tags, comments, categorization, and nested component messages, with reader/writer LiveView tests.
- [x] 7.2 Enforce current write authorization and read-only rendering for threat create, edit, delete, inline fields, tags, comments, and nested assumption/mitigation changes while keeping threat detail inspection readable.
- [x] 7.3 Enforce current write authorization and read-only rendering for evidence create, edit, delete, tags, controls, and relationship changes while keeping evidence detail inspection readable.
- [x] 7.4 Enforce current write authorization and read-only rendering for threat-agent create, edit, and delete operations, with direct-route and forged-event tests.
- [x] 7.5 Make shared entity-linker, categorizer, label/tag, and related-item components capability-aware and require write authorization before persisting any relationship, tag, comment, or control change.
- [x] 7.6 Add cross-workspace and reader-forgery regression tests for assumptions, mitigations, threats, evidence, threat agents, and every supported relationship pair.

## 8. Brainstorm, Reference Packs, and Assistant Actions

- [x] 8.1 Render brainstorm cards in reader mode without create, edit, delete, restore, status, drag/drop, type-order, clustering, or threat-builder actions while retaining filters, search, and incoming updates.
- [x] 8.2 Require current write authorization for every persisted or shared brainstorm mutation and add tests proving reader filters remain usable while forged mutation events are inert.
- [x] 8.3 Require current write authorization for reference-pack import, deletion, selection persistence, and adding reference items to a workspace while keeping pack listings and item inspection readable.
- [x] 8.4 Keep non-mutating assistant questions available to readers but gate assistant-driven insertion, entity creation, imports, threat generation, and other shared results behind current write authorization.
- [x] 8.5 Add LiveView tests for reader and writer behavior across brainstorm, reference packs, and assistant-triggered shared actions.

## 9. Analysis and Job Lifecycle Authorization

- [x] 9.1 Require current write access to start a threat-model quality review and add service tests proving readers cannot create or launch review runs.
- [x] 9.2 Allow the workspace owner to manage workspace quality-review runs and allow an initiating writer to manage their own run only while retaining write access, preserving workspace scoping.
- [x] 9.3 Render repository-analysis and quality-review status and findings for readers without start, retry, cancel, or delete controls, and reject forged lifecycle events server-side.
- [x] 9.4 Add tests for reader inspection, writer-owned lifecycle actions, workspace-owner management, downgraded initiators, cross-workspace run identifiers, and unchanged job state after rejected operations.

## 10. Reports, Exports, and Read Regression Coverage

- [x] 10.1 Verify that readers can open the workspace dashboard, threat-model report, quality-review findings, SRTM, controls, printable views, and other non-mutating workspace surfaces.
- [x] 10.2 Add controller tests proving readers can download whole-workspace JSON, entity reference packs, markdown, Excel, and Mermaid exports while unauthorized identities remain redirected.
- [x] 10.3 Verify that report/export reads do not initialize missing mutable workspace records and adjust read paths where a getter currently persists defaults.
- [x] 10.4 Add an end-to-end role matrix covering owner, writer, reader, revoked, and invalid-role behavior across representative workspace domains.

## 11. Rollout, Specification Sync, and Verification

- [x] 11.1 Add an operational audit query or documented release check for distinct stored permission values and document how unsupported values are resolved before rollout.
- [x] 11.2 Make Read assignment available with role enforcement in the same release, without a rollout feature flag, and document the compatibility check and rollback cleanup for existing `read` entries.
- [x] 11.3 Review the accepted implementation against the collaboration-and-access, AI-assisted-analysis, and threat-model-quality-review delta specs and update the delta specs if an approved behavior decision changed during implementation.
- [x] 11.4 Run `openspec validate add-read-only-workspace-permissions --strict` and resolve every proposal, design, or specification validation issue.
- [x] 11.5 Run `make fmt` and resolve all formatting failures.
- [x] 11.6 Run `make test` and the frontend JavaScript test suite, fixing all regressions.
- [x] 11.7 Manually verify owner assignment of Read/Write/None, reader navigation and exports, writer editing, live permission transitions, forged-event rejection, Quill collaboration, diagram inspection, entity workflows, brainstorm, reference packs, API-key isolation, and quality-review behavior.
