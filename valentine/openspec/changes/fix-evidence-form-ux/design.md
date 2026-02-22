## Context

The evidence form uses PrimerLive components (`.text_input`, `.textarea`, `.select`) which provide an `is_full_width` attribute for consistent full-width styling. Currently, the Name field and Evidence type dropdown use `is_full_width`, but the Description and JSON content textarea fields only use `class="form-control"` without `is_full_width`, causing width misalignment.

The form also has inconsistent label styling: basic form fields (Name, Description, Evidence type) use `<label class="form-label text-small text-bold">` while NIST Controls and Tags sections use `<h3>` headings.

When creating new evidence, the LiveView initializes with an empty changes map that doesn't include a default `evidence_type`, so the conditional fields (JSON content and Blob store URL) remain hidden until the user explicitly selects an evidence type.

## Goals / Non-Goals

**Goals:**
- Make all form inputs the same width for visual consistency
- Ensure new evidence forms show the JSON content field by default
- Use consistent heading/label styles across all form sections
- Maintain existing component behavior and attributes

**Non-Goals:**
- Changing form validation logic or backend behavior
- Modifying the PrimerLive component library itself
- Adding new form fields or changing form structure beyond styling
- Refactoring other evidence-related pages beyond the create/edit form

## Decisions

### Decision 1: Add `is_full_width` to textarea components
**Rationale:** The PrimerLive `.textarea` component supports `is_full_width` attribute (confirmed by checking other forms like assumption form). This is the standard way to make components full-width in this codebase. The `class="form-control"` is redundant when using `is_full_width`.

**Alternatives considered:**
- Custom CSS classes: Would be inconsistent with how other forms use PrimerLive components
- Modifying component defaults: Too broad, would affect other usages

**Decision:** Add `is_full_width` to both Description textarea (line 35) and JSON content textarea (line 65), remove `class="form-control"`.

### Decision 2: Set default evidence_type in LiveView mount
**Rationale:** The Evidence schema defines two evidence types (`:json_data` and `:blob_store_link`) with `:json_data` listed first in the enum. Setting this as the default provides a better initial experience since most users likely use JSON data. The default is set in the `apply_action/3` function for the `:new` action where the changes map is initialized.

**Alternatives considered:**
- Always show both fields: Confusing UX, unclear which field to use
- No default (current state): Poor UX, hidden field is unexpected
- Use `:blob_store_link` as default: Less common use case based on the schema definition order

**Decision:** Add `evidence_type: :json_data` to the changes map initialization in `apply_action(socket, :new, _params)` on line 32.

### Decision 3: Standardize on h3 headings for all sections
**Rationale:** NIST Controls and Tags sections already use `<h3>` headings. Standardizing all form sections to use `<h3>` creates visual hierarchy and consistency. The existing sections are already wrapped in separate `.box` containers, so h3 headings work well for section titles.

**Alternatives considered:**
- Keep labels for basic fields, h3 for complex sections: Maintains current pattern but perpetuates inconsistency
- Use labels everywhere: Would require changing NIST Controls/Tags sections, more invasive
- Use form_control component labels: PrimerLive pattern but would require more refactoring

**Decision:** Replace `<label>` tags with `<h3>` tags for Name, Description, and Evidence type sections. Remove the `for` attribute (not used with h3). Keep the `id` attributes on inputs for accessibility.

## Risks / Trade-offs

**Risk:** Changing label elements to h3 could affect accessibility (screen readers, form associations)
→ **Mitigation:** Maintain input `id` attributes and ensure h3 text clearly identifies the field purpose. The inputs are immediately following the headings, maintaining clear visual and semantic relationships.

**Risk:** Default evidence_type might confuse users who primarily use blob store links
→ **Mitigation:** The dropdown is prominently displayed and easy to change. Users can immediately see and switch the evidence type if needed.

**Risk:** Removing `class="form-control"` from textareas might cause unexpected styling
→ **Mitigation:** The `is_full_width` attribute should handle all necessary styling. Other forms in the codebase use `is_full_width` without `class="form-control"` successfully (e.g., assumption form).

**Trade-off:** Using h3 for all sections creates stronger visual hierarchy but less distinction between "basic" fields and "complex" sections
→ This is acceptable since it improves consistency and the sections are already visually separated by `.box` containers.
