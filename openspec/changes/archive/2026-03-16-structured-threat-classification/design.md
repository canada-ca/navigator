## Context

Navigator workspaces currently store threats with free-text fields and a STRIDE-based grammar but no structured classification metadata. There is no concept of adversary capability tiers, kill chain phases, or MITRE ATT&CK alignment. The `Valentine.Composer` context owns all domain entities; `WorkspaceLive` covers all user-facing flows; `Valentine.Composer.Workspace` and `Valentine.Composer.Threat` hold the relevant schemas.

This change introduces:
1. A workspace-scoped maximum Deliberate Threat Level (Td1–Td7).
2. A new `ThreatAgent` entity (workspace-scoped) carrying adversary classification metadata.
3. Three new optional classification fields on each `Threat`, while preserving the existing STRIDE categorization model.

Relevant existing files:
- `valentine/lib/valentine/composer/workspace.ex`
- `valentine/lib/valentine/composer/threat.ex`
- `valentine/lib/valentine/composer.ex` (context module)
- `valentine/lib/valentine_web/live/workspace_live/form_component.ex`
- `valentine/lib/valentine_web/live/workspace_live/threat_live/form_component.ex`
- `valentine/priv/repo/migrations/`

## Goals / Non-Goals

**Goals:**
- Store a workspace-level `max_threat_level` (Td1–Td7 atom, nullable).
- Store `mitre_tactic`, `kill_chain_phase`, `threat_level` on threats (all optional, nullable).
- Introduce `ThreatAgent` schema with full CRUD under `Valentine.Composer`.
- Expose all new fields through existing LiveView form patterns.
- Extend threat index filtering to support the existing STRIDE categories, plus MITRE tactic and Td level.

**Non-Goals:**
- AI-assisted Td level suggestion or automatic classification.
- Cross-workspace analytics, heatmaps, or bulk operations on Td data.
- Changes to NIST control mapping, assumption, mitigation, or evidence flows.
- Mandatory / non-nullable enforcement of classification fields on existing or new threats.

## Decisions

### Decision 1: Enum representation — module attributes over PostgreSQL enum types

**Chosen**: Represent Td levels, STRIDE categories, and kill chain phases as string columns validated in the Ecto changeset against a module-defined list of atom-strings, rather than PostgreSQL `enum` types.

**Rationale**: Navigator's existing schema patterns (e.g., assumption status, mitigation status) use string columns with domain logic enforced at the changeset level. PostgreSQL enums require separate `ALTER TYPE` migrations when adding values, which is harder to manage. Module attributes keep the taxonomy in Elixir code where it is versioned and readable.

**Alternatives considered**: PostgreSQL `CREATE TYPE` enum — rejected due to migration fragility when taxonomy values evolve.

### Decision 2: ThreatAgent as a first-class schema in `Valentine.Composer`

**Chosen**: Create `Valentine.Composer.ThreatAgent` with a `belongs_to :workspace` association, mirroring the pattern used by `Assumption`, `Mitigation`, and `Evidence`. CRUD is exposed through new functions in `Valentine.Composer` (the existing context module).

**Rationale**: Reuses the established workspace-scoped entity pattern. Avoids a separate context module, which would be an unnecessary abstraction given the existing single-context design.

**Alternatives considered**: Embedding threat agents as a JSONB array on the workspace — rejected because it prevents individual CRUD operations, real-time broadcasts, and future relational joins (e.g., linking a threat to its agent).

### Decision 3: `threat_level` field name for Td on threats

**Chosen**: Name the Td field on `Threat` as `threat_level` (string, nullable) to match the `max_threat_level` naming on `Workspace`, making the relationship evident.

**Rationale**: Symmetry makes code readable. The value domain is identical (Td1–Td7 atoms or nil).

### Decision 4: ThreatAgent LiveView under `WorkspaceLive.ThreatAgentLive`

**Chosen**: Add `index.ex` and `form_component.ex` under `valentine/lib/valentine_web/live/workspace_live/threat_agent_live/`, following the same directory structure as `threat_live`, `assumption_live`, and `mitigation_live`.

**Rationale**: Consistent with the existing workspace sub-entity pattern. Router entry points follow the existing `/workspaces/:workspace_id/threat_agents` pattern.

### Decision 5: Preserve the existing STRIDE model on Threat

**Chosen**: Do not add a separate `stride_category` field. Reuse the application's existing STRIDE categorization support and pair it with the new MITRE ATT&CK tactic, kill chain phase, and Td fields.

**Rationale**: Navigator already stores STRIDE in the threat model and exposes it in the UI. Adding a second STRIDE field would duplicate semantics, create migration noise, and make filtering behavior ambiguous.

## Risks / Trade-offs

- **Migration on existing data**: New columns are nullable, so existing workspaces and threats require no backfill. Risk is low.
- **Td taxonomy evolution**: If the Td scale definition changes (e.g., GC adds Td8), a code change is required. Mitigation: the taxonomy is small (7 values) and defined in a single module attribute list, making updates trivial.
- **Real-time collaboration**: Adding fields to existing broadcast events does not require broadcast schema changes — LiveView assigns are additive. Risk is low.
- **ThreatAgent orphan risk**: Deleting a workspace cascades (via foreign key `ON DELETE CASCADE`) to threat agents. This must be verified in the migration.

## Migration Plan

1. Generate and run a single Ecto migration that adds:
   - `max_threat_level :string` to `workspaces`
   - `mitre_tactic :string`, `kill_chain_phase :string`, `threat_level :string` to `threats`
   - New `threat_agents` table with `workspace_id` (FK, cascade delete), `name`, `agent_class`, `capability`, `motivation`, `td_level`, `timestamps`
2. Update `Workspace`, `Threat`, and new `ThreatAgent` schemas and changesets.
3. Update `Valentine.Composer` with `ThreatAgent` CRUD functions.
4. Update `WorkspaceLive.FormComponent` to render the `max_threat_level` dropdown.
5. Update `ThreatLive.FormComponent` to render the new classification fields while preserving the existing STRIDE controls.
6. Add `ThreatAgentLive.Index` and `ThreatAgentLive.FormComponent` LiveViews with router entries.
7. Add navigation entry for Threat Agents in the workspace sidebar.
8. Extend threat index filter handling for new fields.
9. Run `make fmt && make test`. Rollback: run `mix ecto.rollback` to revert the migration.

## Open Questions

- Should `mitre_tactic` be constrained to a known list of ATT&CK tactics (14 values in ATT&CK v14) or remain a free-text/searchable string? Free-text is simpler to implement and avoids binding Navigator to a specific ATT&CK version; a curated list can be added later.
- Should a predefined set of Threat Agent records (the canonical catalogue: "GC End User" Td2, "Contractor Insider" Td3, etc.) be seeded via `priv/repo/seeds.exs` or left for the operator to create? Seeding makes the first-run experience richer but couples the code to specific values.
