## Why

Navigator threat statements currently lack structured classification metadata, making it impossible to scope a threat model to a realistic adversary posture, filter threats by severity class or actor realism, or align with established taxonomies such as the Deliberate Threat Level (Td1–Td7) scale used by Canadian government security practitioners. This gap prevents teams from communicating risk tolerance clearly to executives, performing scoped workshops, and generating taxonomy-based analytics and heatmaps.

## What Changes

- **Workspace level**: Add a `max_threat_level` field (Td1–Td7) to the workspace create/edit form so organizations can declare the maximum deliberate threat level they realistically defend against. The field includes inline descriptions (e.g., Td4 = "Organized Criminal Group", Td6 = "Nation-State") to guide selection.
- **Threat-agent level**: Introduce a `ThreatAgent` schema (linked to a workspace) that captures Threat Agent Class, Capability level, Motivation, and Mapped Deliberate Threat Level (Td). Predefined examples (e.g., "GC End User" → Td2, "Contractor Insider" → Td3) are provided.
- **Threat level**: Extend the `Threat` schema with classification fields for MITRE ATT&CK tactic, cyber kill chain phase, and an assigned Deliberate Threat Level (Td). Existing STRIDE categorization remains in place and continues to support filtering and reporting alongside the new metadata.
- Database migrations are required for the new `threat_agents` table and the new columns on `workspaces` and `threats`.
- The threat index listing and filtering UI is extended to support filtering by the existing STRIDE categories, MITRE tactic, and Td level.

## Capabilities

### New Capabilities

- `deliberate-threat-level`: Defines the Td1–Td7 taxonomy enum, its labels (e.g., Td1 = "Script Kiddie", Td7 = "Peer Nation-State"), and workspace-level scoping behavior for max Td.
- `threat-agent-classification`: Defines the `ThreatAgent` entity (Class, Capability, Motivation, Td mapping) at the workspace level, including CRUD flows and the predefined agent catalogue.

### Modified Capabilities

- `workspace-management`: Create/Edit workspace forms gain a `max_threat_level` dropdown (Td1–Td7 with inline descriptions). Existing workspaces default to no Td level set (null/unset, meaning "not scoped").
- `threat-management`: Threat create/edit forms gain new optional classification fields for MITRE ATT&CK tactic, kill chain phase, and assigned Deliberate Threat Level (Td1–Td7). Existing STRIDE categorization is preserved rather than duplicated, and threat index filtering is extended to support the existing STRIDE categories plus the new Td and MITRE fields.

## Impact

- **Database**: New migration to add `max_threat_level` to `workspaces`, add `mitre_tactic`, `kill_chain_phase`, and `threat_level` to `threats`, and create a new `threat_agents` table.
- **Schemas**: `Valentine.Composer.Workspace`, `Valentine.Composer.Threat`, new `Valentine.Composer.ThreatAgent`.
- **LiveViews**: `WorkspaceLive.FormComponent`, `WorkspaceLive.ThreatLive.FormComponent`, new `WorkspaceLive.ThreatAgentLive.*`.
- **No breaking changes** to existing workspace or threat data; all new fields are optional and nullable.
- Existing exports and reports are unaffected in this change (taxonomy-based heatmaps and bulk filtering are explicitly out of scope here).

### Non-Goals

- Automated Td level assignment or AI-driven threat agent suggestions (future work).
- Bulk filtering, heatmaps, or cross-workspace reporting using Td fields (future work).
- Changes to NIST control mapping, mitigations, or assumptions.
