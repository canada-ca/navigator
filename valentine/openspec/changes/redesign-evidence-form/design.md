## Context

The current evidence form requires users to select an evidence type (blob_store_link or json_data) before creating evidence, even when they only want to add a text description. The form layout uses full-width dividers and larger spacing that doesn't match the GitHub-style design patterns used elsewhere in the application.

**Current state:**
- Evidence type is required and defaults to `:blob_store_link`
- Description field is optional
- Form uses h2 subheads (24px) for the name field
- Evidence attachment section is always visible based on selected type
- Uses larger spacing (mb-4, 32px) between sections

**Constraints:**
- Phoenix LiveView application using `primer_live` component library
- Database evidence_type field is `:string` (not PostgreSQL enum), allowing Ecto.Enum changes without migration
- Must maintain backward compatibility with existing evidence records
- GitHub Primer design system conventions

## Goals / Non-Goals

**Goals:**
- Make description-only evidence the default, simplest path
- Reduce visual hierarchy complexity with cleaner spacing and typography
- Make evidence attachment truly optional (not required)
- Maintain backward compatibility with existing evidence data
- Follow GitHub-style design patterns consistently

**Non-Goals:**
- Changing database schema (no migrations)
- Modifying existing evidence records or data migration
- Supporting bulk evidence operations
- Adding new evidence types beyond description_only

## Decisions

### 1. Add `:description_only` as Ecto.Enum value (not database enum)

**Decision:** Add `:description_only` to the `evidence_type` Ecto.Enum definition in the Evidence schema, making it the default for new evidence.

**Rationale:** 
- The database field is already `:string`, so no migration needed
- Ecto.Enum handles serialization/deserialization automatically
- Default to `:description_only` makes the form immediately usable
- Existing records with `:blob_store_link` or `:json_data` remain valid

**Alternatives considered:**
- Database-level PostgreSQL enum: Rejected - requires migration and ALTER TYPE operations
- Validation-only approach: Rejected - less type-safe, harder to maintain

### 2. Make description required for all evidence types

**Decision:** Add `:description` to required fields in changeset validation.

**Rationale:**
- Every evidence needs a description for context, regardless of attachments
- Aligns with GitHub issue pattern where description is primary content
- Prevents empty evidence records

**Alternatives considered:**
- Keep description optional: Rejected - leads to unclear evidence without context
- Require only for description_only type: Rejected - inconsistent validation rules

### 3. Use compact card buttons with horizontal icon+text layout

**Decision:** When in `:description_only` state, show two compact card buttons side-by-side with icon and text on the same line (not stacked).

**Rationale:**
- Matches design reference (design.png) and UI reference (ui-reference.js)
- Saves vertical space while maintaining clear affordance
- Icon + text on same line is more compact than stacked layout

**Implementation:**
- Use Primer's flex utilities: `d-flex flex-items-center`
- Icon positioned before text with gap spacing
- Button text: "Link URL" and "Paste JSON" (no help text)

**Alternatives considered:**
- Full-width buttons: Rejected - takes too much vertical space
- Dropdown select: Rejected - requires extra click to see options
- Stacked icon-above-text cards: Rejected - doesn't match design reference

### 4. State-based rendering for evidence attachment section

**Decision:** Render different UI based on `evidence_type` value with explicit state transitions:
- `:description_only` → Show two card buttons
- `:blob_store_link` → Show URL text input + Clear button
- `:json_data` → Show JSON textarea + Clear button
- Clear button → Reset to `:description_only`, clear related fields

**Rationale:**
- Clear, predictable state machine
- Users can always return to description-only state
- No need to hide/show complex UI conditionally

**LiveView events:**
- `set_evidence_type` - Sets type to blob_store_link or json_data
- `clear_evidence_type` - Resets to description_only, clears blob_store_link and json_data fields

### 5. Typography and spacing changes

**Decision:** 
- Name field: `.f3` (20px) - between f4 (16px) and h2 subhead (24px)
- Borderless name input with classes: `f3 border-0 px-0 py-2 color-fg-default`
- Subhead spacing: `mb-3` (16px) instead of `mb-4` (32px)
- No full-width divider after name field

**Rationale:**
- f3 provides prominence without overwhelming the page
- Borderless input creates cleaner, more integrated appearance
- Reduced spacing aligns with GitHub issue design patterns
- Removing divider reduces visual noise

**Alternatives considered:**
- Keep h2 (24px): Rejected - too prominent for a form field
- Use f4 (16px): Rejected - not prominent enough for primary field
- Keep mb-4: Rejected - too much whitespace for modern design

### 6. Two-column layout with sidebar starting at top

**Decision:** Right sidebar (NIST Controls/Tags) starts at the same vertical level as "Name" label, not after name field.

**Rationale:**
- Better use of horizontal space
- Matches GitHub issue sidebar pattern
- Keeps related metadata visible while scrolling

**Layout:**
- Left column: `.col-8` (name, description, attach evidence)
- Right column: `.col-3` (NIST controls, tags)

## Risks / Trade-offs

**[Risk: Breaking changes to form behavior]**
→ Mitigation: Existing evidence records unchanged; only new evidence defaults to `:description_only`

**[Risk: Users confused by state transitions in attach evidence section]**
→ Mitigation: Clear "Clear" button always visible when type is selected; returns to obvious two-button state

**[Risk: Description required breaks existing workflows]**
→ Mitigation: Description should have been required from start; this fixes data quality issue

**[Trade-off: Three evidence types increases validation complexity]**
→ Accepted: Clean separation of concerns in `validate_evidence_type_content/1` function handles each case explicitly

**[Trade-off: Borderless name input less obvious as input field]**
→ Accepted: Matches GitHub issue title pattern; focus state provides clear affordance
