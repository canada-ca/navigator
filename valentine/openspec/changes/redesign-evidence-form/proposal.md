## Why

Improve the evidence creation UX by making description-only evidence the default workflow, simplifying the form layout, and adopting a cleaner GitHub-issue-style interface. This addresses the current friction where users must choose an evidence type before they can create simple text-based evidence.

## What Changes

- Add `:description_only` evidence type to support evidence without attachments
- Make description field required for all evidence types
- Redesign form layout with cleaner two-column structure
- Simplify evidence attachment workflow (make it optional, not required)
- Update form styling to match GitHub-style design reference
- Add evidence number display (`#EVD-{numeric_id}`)
- Update LiveView event handlers to support new evidence type workflow

## Capabilities

### New Capabilities

- `evidence-type-description-only`: Support for description-only evidence type that doesn't require file attachments or links. Includes backend schema changes, validation logic, and default behavior for new evidence.

- `evidence-form-ui`: New evidence form layout and interaction patterns including name field styling, optional evidence attachment section with compact card buttons, two-column layout, and tab navigation for description field.

### Modified Capabilities

<!-- No existing specs to modify -->

## Impact

**Files affected:**
- `lib/valentine/composer/evidence.ex` - Add `:description_only` enum value, update validation
- `lib/valentine_web/live/workspace_live/evidence/show.ex` - Add event handlers, update defaults
- `lib/valentine_web/live/workspace_live/evidence/show.html.heex` - Complete form redesign
- `lib/valentine_web/live/workspace_live/evidence/components/evidence_helpers.ex` - Add label for new type

**Systems affected:**
- Evidence creation/editing workflow - New default type changes user flow
- Form validation - Description becomes required field
- User experience - Simpler default workflow, clearer visual hierarchy

**Testing:**
- Update existing tests to handle `:description_only` type
- Add test coverage for new event handlers (`set_evidence_type`, `clear_evidence_type`)
- Test validation for description-only evidence
- Test state transitions between evidence types

**Backward compatibility:**
- Existing evidence records unchanged (database field is string, not enum)
- All existing `:blob_store_link` and `:json_data` evidence continue to work
- No database migration required
