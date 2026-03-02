## Why

Users working with SRTM (Security Requirements Traceability Matrix) need visibility into which in-scope controls have evidence attached and which still need documentation. Currently, all in-scope controls are shown in a single list without evidence status filtering, making it difficult to prioritize evidence collection and track completion progress.

## What Changes

- Add evidence-based filtering to the SRTM "In scope" controls view
- Introduce three filter options: "All", "Needs evidence", and "Evidence attached"
- Display counter badges showing the number of controls for each filter option
- Show empty state message when a filter returns no results
- Filter state persists when switching between SRTM tabs
- Filter resets to "All" when other SRTM filters (Profile, Type, Class, NIST Family) change

## Capabilities

### New Capabilities
- `srtm-evidence-filter`: Evidence-based filtering for in-scope controls with three mutually exclusive options (All, Needs evidence, Evidence attached), including counter badges and empty state handling

### Modified Capabilities
<!-- No existing spec-level behavior changes - this is a new isolated feature -->

## Impact

**Affected Files:**
- `lib/valentine_web/live/workspace_live/srtm/index.ex` - Add filter state management and helper functions
- `lib/valentine_web/live/workspace_live/srtm/index.html.heex` - Add underline_nav filter UI in "In scope" tab
- `lib/valentine_web/live/workspace_live/components/tab_nav_component.ex` - **[Implementation Correction]** Fixed state preservation logic in `update/2` to prevent nil crashes

**Dependencies:**
- Uses existing PrimerLive components (`underline_nav`, `counter`, `blankslate`)
- Uses existing `@evidence_by_control` socket assign
- No new dependencies required

**User Experience:**
- Improves evidence tracking workflow for compliance work
- Reduces cognitive load by allowing users to focus on controls needing attention
- Provides clear visual feedback on evidence completion status
