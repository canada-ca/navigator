## Context

The evidence create/edit form currently uses a single-column layout that stacks all form fields vertically. The threat create/edit page has already established a successful two-column pattern (`col-8` + `col-3`) that places primary content on the left and metadata/secondary actions on the right. This design extends that pattern to the evidence form.

**Current State:**
- Evidence form uses `col-10` single column
- NIST Controls and Tags sections appear at the bottom, requiring scrolling
- All fields are in `.box` containers with consistent spacing

**Reference Implementation:**
- `lib/valentine_web/live/workspace_live/threat/show.html.heex` (lines 16-373) demonstrates the target layout pattern

## Goals / Non-Goals

**Goals:**
- Apply the same two-column layout pattern used in the threat page to the evidence form
- Eliminate scrolling needed to access NIST Controls and Tags
- Maintain visual consistency across create/edit forms in the workspace
- Preserve all existing form behavior and functionality

**Non-Goals:**
- Changing form validation or data handling logic
- Adding new fields or removing existing fields
- Modifying the LiveView event handlers or backend logic
- Responsive/mobile layout changes (maintain existing responsive behavior)

## Decisions

### Decision 1: Use `col-8` + `col-3` layout (matching threat page)

**Rationale:** User explicitly requested to match the threat page layout. This provides:
- Visual consistency across the application
- Proven usability pattern
- Adequate space for both main form and sidebar content

**Alternatives Considered:**
- `col-7` + `col-4`: Rejected - user preference for exact match with threat page
- `col-8` + `col-4`: Rejected - would total 12 columns (over the grid limit)
- Keep single column, reorder fields: Rejected - doesn't solve the core UX issue

### Decision 2: Move NIST Controls and Tags to right sidebar

**Rationale:**
- These are metadata fields, similar in nature to Status/Priority/STRIDE on threat page
- Frequently accessed but secondary to the primary evidence content
- Grouping them in the sidebar keeps the left column focused on core evidence data

**Alternatives Considered:**
- Keep them at bottom of left column: Rejected - doesn't solve scrolling problem
- Split them across columns: Rejected - would fragment related metadata

### Decision 3: Use `.action_list_section_divider` components in sidebar

**Rationale:**
- Matches the visual style of the threat page right sidebar
- Provides clear visual separation between NIST Controls and Tags sections
- Component already exists and is established pattern

**Alternatives Considered:**
- Plain `<h3>` headers: Rejected - inconsistent with threat page
- No dividers: Rejected - less visual clarity

### Decision 4: Keep all form logic and event handlers unchanged

**Rationale:**
- This is purely a presentational change
- All `phx-*` attributes and form structure remain identical
- Reduces risk of introducing bugs

## Risks / Trade-offs

**Risk:** Two-column layout may not work as well on smaller screens
→ **Mitigation:** The existing responsive grid classes should handle this (the threat page already works responsively). Monitor for any issues post-deployment.

**Trade-off:** Right sidebar content is less prominent than main column
→ **Mitigation:** This is intentional - NIST Controls and Tags are important but secondary. The improved accessibility (no scrolling) outweighs the slightly reduced prominence.

**Risk:** Error messages may need positioning adjustments
→ **Mitigation:** Keep error alerts in the main left column where they currently appear. They relate to form fields, not metadata.
