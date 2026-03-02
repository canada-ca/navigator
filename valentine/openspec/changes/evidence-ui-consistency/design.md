## Context

The Evidence index page currently displays linking relationships as static inline text (e.g., "Linked to Assumption #1, Threat #2"). Other entity pages (Threats, Assumptions, Mitigations) use a consistent pattern of interactive icon buttons with counter badges and modal-based editing via the EntityLinkerComponent. This design brings Evidence into alignment with that established pattern.

**Current State:**
- Evidence rows show a `<div>` with inline spans displaying linked entities as non-interactive text
- No way to edit links from the index page
- EntityLinkerComponent supports 6 relationship pairs (assumption↔mitigation, assumption↔threat, mitigation↔threat) but not evidence relationships
- Database join tables already exist (`EvidenceAssumption`, `EvidenceThreat`, `EvidenceMitigation`)

**Constraints:**
- Must follow existing patterns from ThreatComponent, AssumptionComponent, MitigationComponent
- Must use existing EntityLinkerComponent modal UI (no new modal component)
- No database schema changes allowed
- Must maintain backward compatibility with existing evidence data

## Goals / Non-Goals

**Goals:**
- Replace inline "Linked to..." text with interactive icon buttons for Assumptions, Threats, and Mitigations
- Enable modal-based link editing from the Evidence index page
- Match the UX patterns used on Threats, Assumptions, and Mitigations pages
- Support bidirectional linking (evidence can link to entities, visible from evidence page)

**Non-Goals:**
- Adding evidence linking buttons to other entity pages (Threats/Assumptions/Mitigations pages)
- Changes to evidence create/edit pages
- Performance optimization of evidence queries
- Unidirectional vs bidirectional linking from other pages to evidence

## Decisions

### Decision 1: Create EvidenceComponent (following existing pattern)

**Choice:** Create a new LiveComponent (`EvidenceComponent`) to render evidence rows with action buttons

**Rationale:**
- Follows established pattern: `ThreatComponent`, `AssumptionComponent`, `MitigationComponent` all use dedicated components
- Encapsulates rendering logic and keeps index template clean
- Easier to maintain and test in isolation
- Allows reuse if evidence rows need to appear elsewhere

**Alternatives Considered:**
- Keep inline rendering in index.html.heex → Rejected: Would make template complex and hard to maintain, breaks pattern consistency
- Use a shared generic EntityComponent → Rejected: Each entity type has unique display needs (evidence shows name vs threats show statement)

### Decision 2: Extend EntityLinkerComponent (reuse existing modal)

**Choice:** Add evidence support to the existing EntityLinkerComponent by adding case patterns to the save handler

**Rationale:**
- EntityLinkerComponent is already generic and handles all entity type pairs
- Avoids code duplication of modal UI, dropdown selection, tag-style removal
- Maintains consistent UX across all entity types
- Simple addition of 3 case patterns in the save event handler

**Alternatives Considered:**
- Create a new EvidenceLinkingComponent → Rejected: Would duplicate 90% of EntityLinkerComponent logic
- Modify each entity component to handle evidence → Rejected: Out of scope, unnecessary complexity

### Decision 3: Add six Composer functions (mirroring existing linking functions)

**Choice:** Add three pairs of functions to Composer:
- `add_assumption_to_evidence/2` and `remove_assumption_from_evidence/2`
- `add_threat_to_evidence/2` and `remove_threat_from_evidence/2`
- `add_mitigation_to_evidence/2` and `remove_mitigation_from_evidence/2`

**Rationale:**
- Mirrors the naming convention of existing linking functions (e.g., `add_assumption_to_threat/2`)
- Provides clean API for EntityLinkerComponent to use
- Handles join table operations in a single place
- Uses `:on_conflict :nothing` for idempotent inserts

**Alternatives Considered:**
- Generic `add_entity_link/3` function → Rejected: Would require dynamic module resolution, less explicit, harder to trace
- Inline join table operations in LiveView → Rejected: Violates separation of concerns, harder to test

### Decision 4: Use JS.patch for modal URLs (consistent with other pages)

**Choice:** Link buttons use `JS.patch` to change URL to `/workspaces/:id/evidence/:id/assumptions|threats|mitigations`

**Rationale:**
- Matches behavior of ThreatComponent, AssumptionComponent, MitigationComponent
- Enables browser back button to close modals
- Makes modal state shareable via URL
- No page reload, maintains LiveView state

**Alternatives Considered:**
- Use JS.show to toggle modal visibility → Rejected: Doesn't update URL, breaks back button, not consistent with other pages

### Decision 5: Row structure with float-right action buttons

**Choice:** Evidence row displays details on the left, action buttons float right (linking buttons + edit + delete)

**Rationale:**
- Exactly matches layout of ThreatComponent, AssumptionComponent, MitigationComponent
- Users already familiar with this pattern from other entity pages
- Clear visual separation between content and actions
- Action buttons always visible regardless of content length

**Alternatives Considered:**
- Actions below content → Rejected: Requires more scrolling, inconsistent with other pages
- Actions on hover → Rejected: Not mobile-friendly, accessibility concerns

## Risks / Trade-offs

**Risk:** EntityLinkerComponent's `entity_content/1` helper assumes `content` field  
→ **Mitigation:** Add pattern match for Evidence struct that returns `evidence.name` instead of `content`

**Risk:** Evidence index may not preload related entities in all code paths  
→ **Mitigation:** Update `get_workspace/1` to always preload `:assumptions`, `:threats`, `:mitigations` and add to mount assigns

**Risk:** New live actions may conflict with existing routes  
→ **Mitigation:** Verify router.ex has or can support `/evidence/:id/assumptions|threats|mitigations` routes

**Trade-off:** Creating EvidenceComponent adds one more component file  
→ **Benefit:** Consistency, maintainability, and testability outweigh the cost of one additional file

**Trade-off:** Three linking buttons add visual density to evidence rows  
→ **Benefit:** Provides immediate visibility of relationship counts and quick access to editing, matches user expectations from other pages

## Migration Plan

**Deployment Steps:**
1. Add six Composer linking functions (backward compatible, not called until UI deployed)
2. Extend EntityLinkerComponent with evidence case patterns (no effect until UI uses it)
3. Create EvidenceComponent
4. Update Evidence index LiveView with new live actions and handle_info
5. Update Evidence index template to use EvidenceComponent and EntityLinkerComponent
6. Verify routes support new live actions (add if needed)

**No data migration needed** - join tables already exist with data

**Rollback Strategy:**
- Revert template and LiveView changes to restore inline text display
- Composer functions can remain (unused, no side effects)
- No database rollback needed

**Testing:**
- Verify linking buttons appear with correct counts
- Verify clicking each button opens modal
- Verify adding/removing links persists correctly
- Verify counter badges update after save
- Test browser back button closes modals
- Verify no N+1 queries from preloading

## Open Questions

_None - implementation approach is clear based on existing patterns_
