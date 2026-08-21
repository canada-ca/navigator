## Context

`Valentine.Composer` began as the application's 2,856-line business context. Its implementations have now been extracted into capability modules, leaving a broad compatibility facade used by LiveViews, controllers, MCP tools, AI workflows, exports, fixtures, and tests. The remaining migration removes that indirection by moving all callers to the capability that owns each operation and then deleting the facade.

The refactor must preserve all externally observable behavior. In particular, workspace scoping and permission checks, preload shapes, bang/non-bang behavior, changesets, return tuples, PubSub effects triggered by callers, and function defaults are compatibility constraints. No schemas, migrations, routes, authorization rules, AI-provider integrations, or real-time collaboration flows are being changed.

The primary implementation anchors are the capability modules and schemas under `valentine/lib/valentine/composer/`, domain tests under `valentine/test/valentine/`, workspace LiveViews under `valentine/lib/valentine_web/live/workspace_live/`, MCP tools, repository-analysis and quality-review workflows, and export/report behavior in `ValentineWeb.WorkspaceController`.

## Goals / Non-Goals

**Goals:**

- Give each persistence/query capability a small, discoverable owner under `Valentine.Composer`.
- Make every repository caller depend directly on the narrow capability it uses.
- Remove the `Valentine.Composer` facade once the caller inventory reaches zero.
- Centralize only genuinely shared query mechanics, especially workspace scoping and enum filters.
- Make cross-capability dependencies explicit and acyclic.
- Reduce source-file size, compile blast radius, merge conflicts, and the amount of unrelated code needed to understand a change.
- Verify behavior through compilation, existing behavioral tests, and capability-boundary structural tests.

**Non-Goals:**

- Changing domain behavior, persisted data, Ecto schemas, database constraints, or associations.
- Renaming public functions or changing arguments, defaults, return values, exceptions, ordering, or preload shapes.
- Retaining or deprecating the compatibility facade after all callers have migrated.
- Introducing a new generic repository abstraction, protocol, macro-based context generator, or external dependency.
- Reworking permissions, authentication, PubSub, AI providers, routes, UI workflows, reports, or exports.

## Decisions

### 1. Remove `Valentine.Composer` after an atomic caller migration

Every `Composer.function(...)` and fully qualified `Valentine.Composer.function(...)` call will be mapped to the capability owner established by the extracted modules. Files will alias only the capability modules they use. Once production code, fixtures, and tests compile without facade references, `valentine/lib/valentine/composer.ex` will be deleted.

The earlier compatibility-facade stage provided a safe behavioral checkpoint while implementations moved. Keeping it permanently was rejected because it preserves the broad dependency, obscures ownership at call sites, and allows new code to continue coupling itself to unrelated capabilities. The migration is atomic because a partially retained facade would make completion difficult to enforce.

### 2. Split by existing domain capabilities

The implementation will create these concrete owners under `valentine/lib/valentine/composer/`:

- `Valentine.Composer.Workspaces`: workspace CRUD, invitation/ownership updates, permission checks, and workspace changesets.
- `Valentine.Composer.AnalysisJobs`: repository analysis agents and threat-model quality review runs/findings.
- `Valentine.Composer.Threats`: threats and threat agents.
- `Valentine.Composer.Assumptions`: assumptions.
- `Valentine.Composer.Mitigations`: mitigations.
- `Valentine.Composer.Relationships`: assumption/threat/mitigation links and evidence links.
- `Valentine.Composer.Documents`: application information, data-flow diagrams, and architecture documents.
- `Valentine.Composer.ReferencePacks`: reference packs and their entries.
- `Valentine.Composer.Controls`: controls.
- `Valentine.Composer.Users`: users and provider identity lookups.
- `Valentine.Composer.ApiKeys`: API key lifecycle and verification.
- `Valentine.Composer.EvidenceManagement`: evidence CRUD, bulk creation, and association orchestration. The `Evidence` name remains reserved for the existing Ecto schema.
- `Valentine.Composer.Brainstorm`: brainstorm sessions, ideas, voting, grouping, and workspace-scoped operations.

These boundaries follow current function groupings and schema ownership rather than inventing a second domain vocabulary. Fewer, broader modules were considered, but would leave several modules with unrelated responsibilities. One module per schema was also considered, but would fragment cohesive workflows such as analysis jobs and narrative documents.

### 3. Use a small internal query helper module

`Valentine.Composer.QueryHelpers` contains shared workspace-scoped lookup/preload helpers and enum filter construction. It remains internal infrastructure used only by capability modules.

Capability modules will continue to own domain-specific queries. A generic repository layer was rejected because it would hide Ecto semantics, add indirection, and make capability-specific preload and ordering behavior harder to see.

### 4. Make cross-capability calls direct and acyclic

When one extracted capability needs another, it calls the owning capability module directly. For example, evidence association orchestration uses `Threats`, `Assumptions`, and `Mitigations` lookups; relationship operations remain in `Relationships`. Application callers follow the same direct dependency rule.

This creates a one-way dependency graph and prevents circular compilation. Routing internal calls through the facade was rejected because it obscures ownership and risks cycles.

### 5. Preserve code before simplifying it further

The first extraction will move existing function bodies with only the alias, import, helper, and cross-module changes required to compile. Query rewrites and behavioral simplifications are deferred unless needed to remove duplication introduced by the split.

This keeps the change reviewable and lets the existing test suite act as a behavioral characterization. Combining extraction with query redesign was rejected because failures would no longer clearly distinguish movement errors from semantic changes.

### 6. Verify both behavior and architecture

Existing DataCase, ConnCase, LiveView, MCP, export, and AI workflow tests remain the principal behavioral regression suite. Focused tests prove representative capability APIs directly, and structural checks require zero facade calls, aliases, or module definitions.

No route, schema, export format, or real-time collaboration test expectation is intentionally changed.

## Risks / Trade-offs

- [Risk] A caller is mapped to the wrong capability or a facade alias remains hidden in a less common code path. → Generate the mapping from the compiled facade ownership, scan all `.ex` and `.exs` files, force a clean compilation, and enforce zero facade references structurally.
- [Risk] Moving private helpers changes query ordering, workspace scoping, or preload shapes. → Move bodies unchanged, centralize only byte-for-byte equivalent shared mechanics, and run focused context tests after each capability group.
- [Risk] Cross-capability references create compile cycles. → Keep capability-to-capability calls explicit and one-way where necessary, and keep shared query behavior directed toward `QueryHelpers`, schemas, and `Repo`.
- [Risk] The larger number of modules makes navigation noisier. → Use capability-level modules matching existing product vocabulary and keep closely related schemas together.
- [Risk] Files using several Composer capabilities gain multiple aliases. → Alias only the capability modules used by each file and retain the established domain vocabulary.
- [Risk] A large mechanical caller migration creates merge conflicts. → Complete it atomically on the dedicated branch, format once aliases stabilize, and keep behavior changes out of the migration.

## Migration Plan

1. Record the public Composer API and establish a clean baseline test result.
2. Add `QueryHelpers` and extract capability modules in dependency order, running focused compilation/tests after each coherent group.
3. Use the facade ownership map to migrate production callers, fixtures, and tests to capability modules.
4. Require a zero-result repository scan for facade calls and aliases, then delete `valentine/lib/valentine/composer.ex`.
5. Replace facade parity checks with direct capability and no-facade structural tests.
6. Run formatter checks, a forced warnings-as-errors compilation, focused capability tests, and the complete backend and frontend suites.
7. Deploy normally. There are no migrations, feature flags, data backfills, route changes, or configuration changes.

Rollback consists of deploying the preceding application release or reverting this code change. Persisted data is fully compatible in both directions.

## Open Questions

None blocking. The user has selected immediate removal rather than a deprecation period.
