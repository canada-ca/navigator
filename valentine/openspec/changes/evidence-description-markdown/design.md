## Context

**Current State:**
- Evidence form (`show.html.heex`) has a single `.box` containing all fields wrapped in one `<form>` element
- Description field is a plain textarea (4 rows) within this form
- The threats page uses a different pattern: multiple `.box` components, with comments in a separate box with TabNavComponent for Write/Preview
- TabNavComponent and MarkdownComponent already exist and are proven in the threats/assumptions/mitigations pages
- Database already stores description as `:text` which supports markdown content

**Problem:**
- Adding TabNavComponent inside the existing form would create nested forms (TabNavComponent contains its own `<form phx-change="update_field">`)
- Nested forms cause unpredictable browser behavior and event bubbling issues
- Inconsistent UX: threats have rich markdown editing, evidence has plain text

**Constraint:**
- Must maintain backward compatibility - existing plain text descriptions should render correctly

## Goals / Non-Goals

**Goals:**
- Eliminate nested form structure by separating description into its own box
- Provide markdown editing experience matching threats comments (Write/Preview tabs)
- Reuse existing components (TabNavComponent, MarkdownComponent) without modification
- Maintain backward compatibility with existing plain text descriptions
- Keep database schema unchanged

**Non-Goals:**
- Not adding a separate "comments" field to evidence (description serves this purpose)
- Not changing the NIST Controls or Tags sidebar structure
- Not modifying how evidence_type-specific fields (JSON/Blob) work
- Not changing backend validation or save logic

## Decisions

### Decision 1: Separate Description into Second Box

**Choice:** Move description out of the main form box into a dedicated second `.box` below the main evidence details.

**Rationale:**
- Follows the threats page pattern where comments are in a separate box
- Eliminates nested forms - each box has its own independent form
- Gives description more visual weight and prominence
- Cleaner separation: "core metadata" (box 1) vs. "rich content" (box 2)

**Alternatives Considered:**
- Keep description in main box and wrap TabNavComponent without a form → Would break the Write tab's live preview functionality since the textarea needs `phx-change`
- Use a different event name for the description form → Still a nested form, just with different handlers
- Remove outer form entirely → Would require refactoring all fields to use LiveComponents

### Decision 2: Use TabNavComponent Pattern from Threats

**Choice:** Copy the exact TabNavComponent + MarkdownComponent pattern from `threat/show.html.heex` lines 149-183.

**Rationale:**
- Proven pattern already used in 3+ places (threats, assumptions, mitigations)
- Users familiar with threats will instantly recognize the interface
- No need to modify or create new components
- Consistent behavior and styling across the app

**Implementation Pattern:**
```heex
<.box class="p-4 mt-2">
  <h3>{gettext("Description")}</h3>
  <.live_component module={TabNavComponent} ...>
    <:tab_content :let={tab}>
      <% "tab1" -> %>
        <form phx-change="update_field">
          <.textarea name="description" ... />
        </form>
      <% "tab2" -> %>
        <div class="markdown-body">
          <MarkdownComponent.render text={@changes[:description]} />
        </div>
    </:tab_content>
  </.live_component>
</.box>
```

### Decision 3: Render Markdown in Evidence Component

**Choice:** Update `evidence_component.ex` to render description using MarkdownComponent instead of plain text.

**Rationale:**
- Makes list/detail views show formatted markdown, not raw markdown syntax
- Backward compatible: MDEx renders plain text without any markdown syntax correctly
- Consistent with how threats/assumptions/mitigations display their markdown content

### Decision 4: Keep Database Schema Unchanged

**Choice:** Continue using the `description` field as `:text` type, store markdown as plain text.

**Rationale:**
- `:text` type already supports markdown content (it's just text)
- No migration needed
- No breaking changes to API or existing data
- MDEx.to_html! safely converts both plain text and markdown at render time

## Risks / Trade-offs

### Risk: Users might paste rich HTML that breaks rendering
**Mitigation:** MDEx library escapes HTML by default - malicious HTML won't render as executable code. Markdown is the supported input format.

### Risk: Existing plain text descriptions might have characters that markdown interprets specially
**Mitigation:** Tested - MDEx renders plain text correctly. Special chars like `*`, `_`, `#` only trigger markdown formatting if used in proper syntax patterns. Random text with these characters displays normally.

### Risk: Increased vertical space on evidence form
**Mitigation:** This is intentional and matches the threats pattern. Description gets more prominence which is appropriate for a free-text field. Users can collapse/scroll if needed.

### Trade-off: Two separate forms means two separate phx-change events
**Impact:** Minimal - both trigger the same `handle_event("update_field", ...)` handler with different field names. The handler already supports this pattern. Changes update `@changes` assign independently.

### Trade-off: Description box always visible (not collapsible like assumptions comments)
**Justification:** Description is a primary field for evidence (unlike comments which are supplementary). Should be immediately accessible for editing, not hidden in a details disclosure.

## Migration Plan

**Deployment:**
1. Deploy code changes - purely additive UI changes
2. No database migration required
3. No data backfill needed
4. Existing plain text descriptions render correctly in markdown component

**Rollback:**
- Simple code revert - no database changes to undo
- Existing data unaffected in either direction

**Testing:**
- Create new evidence with markdown in description
- Edit existing evidence and add markdown
- Verify preview tab renders correctly
- Verify evidence list shows rendered markdown
- Test with empty description
- Test switching between Write/Preview tabs

## Open Questions

None - the implementation path is clear using proven patterns from the threats page.
