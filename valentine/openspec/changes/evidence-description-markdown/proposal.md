## Why

The evidence description field currently lacks markdown support, unlike the threats comments section which supports rich text formatting via Write/Preview tabs. This creates an inconsistent user experience and limits users' ability to provide well-formatted, structured descriptions for evidence. Additionally, the current implementation has a nested form structure that can cause unintended behaviors when adding markdown support.

## What Changes

- Separate the evidence description field from the main evidence form into its own dedicated box
- Add Write/Preview tab navigation to the description field (matching threats comments pattern)
- Enable markdown rendering in the Preview tab using the existing MarkdownComponent
- Update the evidence list/detail view to render description as markdown instead of plain text
- Eliminate nested form issue by having independent forms for core evidence fields vs. description
- Maintain backward compatibility - existing plain text descriptions will render correctly

## Capabilities

### New Capabilities
- `evidence-description-markdown`: Evidence descriptions support markdown formatting with Write/Preview tabs, following the same UX pattern as threat comments

### Modified Capabilities
<!-- No existing spec-level requirements are changing - this is a new capability addition -->

## Impact

**Affected Files:**
- `lib/valentine_web/live/workspace_live/evidence/show.html.heex` - Refactor form structure, add description box with TabNavComponent
- `lib/valentine_web/live/workspace_live/components/evidence_component.ex` - Render description as markdown

**Reused Components:**
- `ValentineWeb.WorkspaceLive.Components.TabNavComponent` - Existing tab navigation
- `ValentineWeb.WorkspaceLive.Components.MarkdownComponent` - Existing markdown renderer
- `MDEx` library - Already in dependencies

**No Changes Needed:**
- Database schema - `:text` column type already supports markdown storage
- Backend logic - Existing `update_field` event handler works with new structure
- API - Evidence description field remains the same in JSON responses
