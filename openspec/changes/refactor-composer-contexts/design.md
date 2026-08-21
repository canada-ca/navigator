## Context

`Valentine.Composer` is the application's established business context and the public API used by LiveViews, controllers, MCP tools, AI workflows, exports, fixtures, and tests. The module is currently 2,856 lines and owns workspace access, analysis jobs, core threat-model entities, cross-entity relationships, narrative documents, reference material, controls, users, API keys, evidence, and brainstorming. Those capabilities already have separate Ecto schemas, but their query and persistence functions share one source file and one compile dependency.

The refactor must preserve all externally observable behavior. In particular, workspace scoping and permission checks, preload shapes, bang/non-bang behavior, changesets, return tuples, PubSub effects triggered by callers, and function defaults are compatibility constraints. No schemas, migrations, routes, authorization rules, AI-provider integrations, or real-time collaboration flows are being changed.

The primary implementation anchors are `valentine/lib/valentine/composer.ex`, the schemas under `valentine/lib/valentine/composer/`, Composer DataCase tests under `valentine/test/valentine/`, workspace LiveViews under `valentine/lib/valentine_web/live/workspace_live/`, and export/report behavior in `ValentineWeb.WorkspaceController`.

## Goals / Non-Goals

**Goals:**

- Give each persistence/query capability a small, discoverable owner under `Valentine.Composer`.
- Preserve the complete public `Valentine.Composer` API so existing callers require no coordinated rewrite.
- Centralize only genuinely shared query mechanics, especially workspace scoping and enum filters.
- Make cross-capability dependencies explicit and acyclic.
- Reduce source-file size, compile blast radius, merge conflicts, and the amount of unrelated code needed to understand a change.
- Verify compatibility through compilation, existing behavioral tests, and facade/structure-focused tests.

**Non-Goals:**

- Changing domain behavior, persisted data, Ecto schemas, database constraints, or associations.
- Renaming public functions or changing arguments, defaults, return values, exceptions, ordering, or preload shapes.
- Rewriting application callers to use the new capability modules in this change.
- Introducing a new generic repository abstraction, protocol, macro-based context generator, or external dependency.
- Reworking permissions, authentication, PubSub, AI providers, routes, UI workflows, reports, or exports.

## Decisions

### 1. Keep `Valentine.Composer` as a compatibility facade

`valentine/lib/valentine/composer.ex` will retain every existing public function and delegate to capability modules. `defdelegate` will be used where it preserves the exact arity and defaults; explicit thin wrappers will be used for overloaded, guarded, or defaulted APIs where delegation would make the contract less clear. Module documentation will identify the facade as stable and point new code toward capability modules.

This avoids a repository-wide caller migration and separates architectural movement from behavioral change. Removing or immediately bypassing the facade was rejected because it would enlarge the diff, couple unrelated callers to the refactor, and make regressions harder to localize.

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

`Valentine.Composer.QueryHelpers` will contain shared workspace-scoped lookup/preload helpers and enum filter construction. It will be documented as internal infrastructure and will not become part of the `Valentine.Composer` facade.

Capability modules will continue to own domain-specific queries. A generic repository layer was rejected because it would hide Ecto semantics, add indirection, and make capability-specific preload and ordering behavior harder to see.

### 4. Make cross-capability calls direct and acyclic

When one extracted capability needs another, it will call the owning capability module directly rather than routing through the compatibility facade. For example, evidence association orchestration can use `Threats`, `Assumptions`, and `Mitigations` lookups; relationship operations remain in `Relationships`. The facade depends on all capability modules, while no capability module depends on the facade.

This creates a one-way dependency graph and prevents circular compilation. Routing internal calls through the facade was rejected because it obscures ownership and risks cycles.

### 5. Preserve code before simplifying it further

The first extraction will move existing function bodies with only the alias, import, helper, and cross-module changes required to compile. Query rewrites and behavioral simplifications are deferred unless needed to remove duplication introduced by the split.

This keeps the change reviewable and lets the existing test suite act as a behavioral characterization. Combining extraction with query redesign was rejected because failures would no longer clearly distinguish movement errors from semantic changes.

### 6. Verify both behavior and architecture

Existing DataCase, ConnCase, LiveView, MCP, export, and AI workflow tests remain the principal behavioral regression suite. Focused tests will additionally prove that representative capability APIs work directly and through the facade, and a structural test will guard against accidentally moving persistence implementation back into the facade.

No route, schema, export format, or real-time collaboration test expectation is intentionally changed.

## Risks / Trade-offs

- [Risk] A delegated function loses a default argument, guard, clause order, documentation, or exception behavior. → Inventory every public name/arity before extraction, prefer explicit wrappers for ambiguous APIs, compile with warnings treated as errors where supported, and run the existing suite through the facade.
- [Risk] Moving private helpers changes query ordering, workspace scoping, or preload shapes. → Move bodies unchanged, centralize only byte-for-byte equivalent shared mechanics, and run focused context tests after each capability group.
- [Risk] Cross-capability references create compile cycles. → Enforce the dependency direction `Composer facade -> capability modules -> QueryHelpers/schemas/Repo`, with direct capability-to-capability calls only where necessary and never back through the facade.
- [Risk] The larger number of modules makes navigation noisier. → Use capability-level modules matching existing product vocabulary and keep closely related schemas together.
- [Risk] The facade preserves a broad API and therefore does not immediately force better caller boundaries. → Treat it as a compatibility seam; future changes can adopt capability modules incrementally without coupling that migration to this refactor.
- [Risk] A large mechanical move creates merge conflicts. → Complete the extraction on the dedicated branch, keep application caller files unchanged, format once boundaries stabilize, and maintain an OpenSpec checklist with independently verifiable checkpoints.

## Migration Plan

1. Record the public Composer API and establish a clean baseline test result.
2. Add `QueryHelpers` and extract capability modules in dependency order, running focused compilation/tests after each coherent group.
3. Replace implementation in `Valentine.Composer` with compatibility delegates/wrappers only after all capability modules compile.
4. Add facade parity and architectural boundary tests.
5. Run formatter checks, focused Composer tests, and the complete test suite.
6. Deploy normally. There are no migrations, feature flags, data backfills, route changes, or configuration changes.

Rollback consists of deploying the preceding application release or reverting this code change. Persisted data is fully compatible in both directions.

## Open Questions

None blocking. Direct caller adoption of capability modules and any future deprecation policy for the facade are intentionally deferred to separate changes.
