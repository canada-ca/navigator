## Why

Evidence can only be created via the API today, which blocks UI-driven workflows and makes it hard to curate evidence alongside threats. A first-class evidence editor unlocks faster, more consistent evidence capture with automatic NIST-based linking.

## What Changes

- Add a full-page evidence create experience in the workspace UI, aligned with the patterns on the threats page.
- Add a full-page evidence edit experience that mirrors the create flow.
- Provide tag-style input for NIST controls and use those controls to auto-link evidence to assumptions, threats, and mitigations after saving the changes.
- Keep linking UI (drawers, dropdowns) out of scope for this change.

## Capabilities

### New Capabilities
- `evidence-ui`: Evidence creation and editing UI with NIST control tagging and auto-linking behavior.

### Modified Capabilities

## Impact

- LiveView routes and templates for evidence create/edit.
- Evidence UI components and validation feedback in the web layer.
- Composer evidence linking behavior invoked on create and edit.
