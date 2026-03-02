## Why

Auditors and compliance reviewers need to quickly identify which evidence supports each NIST control requirement in the Security Requirements Traceability Matrix (SRTM). Currently, the SRTM shows control IDs and their related mitigations/threats/assumptions, but doesn't surface the evidence that validates compliance with each control. This creates friction during audits as reviewers must manually search through evidence records to find supporting documentation.

## What Changes

- Add clickable evidence reference labels (e.g., `[#1]`, `[#2]`) next to NIST control IDs in the SRTM "In scope" tab
- Evidence labels link to the corresponding evidence detail page in a new browser tab
- Hovering over evidence labels displays a tooltip showing the evidence name
- Evidence is grouped by NIST control ID and sorted by numeric ID for consistent display
- Only evidence with matching NIST control IDs in the "In scope" tab are displayed (not in "Out of scope" or "Not allocated" tabs)

## Capabilities

### New Capabilities
- `srtm-evidence-display`: Display evidence reference labels linked to NIST control IDs in the SRTM view, with proper data loading, grouping, and rendering

### Modified Capabilities
<!-- No existing specs are being modified - this is a new display capability -->

## Impact

**Affected Code:**
- `lib/valentine/composer/workspace.ex` - New helper function to group evidence by NIST control IDs
- `lib/valentine_web/live/workspace_live/srtm/index.ex` - Preload evidence, add evidence mapping to socket assigns
- `lib/valentine_web/live/workspace_live/srtm/index.html.heex` - Template changes to render evidence labels in "In scope" tab

**User Experience:**
- SRTM page load includes evidence data (minimal performance impact due to preloading)
- Evidence updates require manual page refresh (consistent with current behavior for mitigations/threats/assumptions)

**No Breaking Changes**
