## Why

The current evidence create/edit form requires users to scroll significantly to access NIST Controls and Tags fields, which are frequently used metadata fields. This creates unnecessary friction in the workflow. By splitting the form into a two-column layout (similar to the threat create/edit page), we can make these fields immediately visible and accessible.

## What Changes

- Restructure the evidence form from a single-column (`col-10`) layout to a two-column layout (`col-8` + `col-3`)
- Move the main form fields (Name, Evidence Type, conditional fields, Description) to the left column
- Move NIST Controls and Tags sections to a right sidebar
- Add visual section dividers to the right sidebar for consistency with the threat page design
- Maintain all existing functionality and form behavior

## Capabilities

### New Capabilities

None - this is a UI restructuring change only.

### Modified Capabilities

None - no requirement changes. This is an implementation-level UI improvement that doesn't change the underlying capabilities or requirements of the evidence form.

## Impact

**Affected Files:**
- `lib/valentine_web/live/workspace_live/evidence/show.html.heex` - Primary template requiring layout restructuring

**User Experience:**
- Users will no longer need to scroll to access NIST Controls and Tags
- Form layout will be consistent with the threat create/edit page
- No changes to form behavior, validation, or data handling
