## Why

The Evidence index page currently has an inconsistent UX compared to other entity pages (Threats, Assumptions, Mitigations). The linking information is displayed as static inline text without interactive editing capabilities, unlike other entity pages that provide clickable buttons with modal-based editing. This inconsistency creates a fragmented user experience and makes the evidence page less intuitive to use.

## What Changes

- Replace inline "Linked to..." text displays with interactive icon buttons for Assumptions, Threats, and Mitigations
- Add modal-based linking editor using the existing EntityLinkerComponent (same UX as other entity pages)
- Create a dedicated EvidenceComponent to encapsulate evidence row rendering with action buttons
- Add Composer functions for bidirectional evidence linking (add/remove for assumptions, threats, mitigations)
- Extend EntityLinkerComponent to support evidence as a source entity type

## Capabilities

### New Capabilities
- `evidence-entity-linking`: Interactive UI for linking evidence to assumptions, threats, and mitigations with modal-based editing, counter badges, and bidirectional relationship management

### Modified Capabilities
_None - this change adds new UI patterns without modifying existing capability requirements_

## Impact

**UI Components:**
- `lib/valentine_web/live/workspace_live/evidence/index.html.heex` - Row rendering updates
- New: `lib/valentine_web/live/workspace_live/components/evidence_component.ex` - Evidence row component
- `lib/valentine_web/live/workspace_live/components/entity_linker_component.ex` - Add evidence support

**Backend:**
- `lib/valentine_web/live/workspace_live/evidence/index.ex` - New live actions for linking modals
- `lib/valentine/composer.ex` - Six new linking functions (add/remove for each entity type)

**Data Layer:**
- Uses existing join tables: `EvidenceAssumption`, `EvidenceThreat`, `EvidenceMitigation`
- No database migrations required

**User Workflow:**
- Evidence page now matches the UX patterns of Threats, Assumptions, and Mitigations pages
- Users can manage evidence relationships directly from the index page with interactive buttons and modals
