## Why

The Evidence create/edit form has three UX inconsistencies that create a confusing user experience: textarea fields (Description and JSON content) are not full-width and misaligned with other form inputs, no default evidence type is selected when creating new evidence (causing the JSON content field to be hidden initially), and form labels use inconsistent styling (small labels vs. h3 headings for different sections).

## What Changes

- Add `is_full_width` attribute to Description and JSON content textarea fields to match the width of other form inputs
- Set default `evidence_type: :json_data` when creating new evidence so the JSON content field appears by default
- Standardize label styling across all form sections (Name, Description, Evidence type, NIST Controls, and Tags) to use consistent heading styles

## Capabilities

### New Capabilities

None - this is a UX bug fix that doesn't introduce new capabilities.

### Modified Capabilities

None - this change only affects UI styling and default values, not functional requirements.

## Impact

**Files Modified:**
- `lib/valentine_web/live/workspace_live/evidence/show.html.heex` - Add `is_full_width` to textarea components, update label styling
- `lib/valentine_web/live/workspace_live/evidence/show.ex` - Set default `evidence_type` in `apply_action/3` for `:new` action

**User Impact:**
- Improved visual consistency on evidence forms
- Better initial experience when creating new evidence (JSON content field visible by default)
- No breaking changes or functional changes

**Testing Impact:**
- Visual/UI testing recommended to verify alignment
- No new tests required as functionality is unchanged
