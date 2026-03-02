## Context

Evidence exists in the data model with NIST controls and auto-linking logic, but the UI only exposes an index view. The repository uses LiveView for full-page editors (notably the threat editor) and modal form components for simpler CRUD. This change adds a full-page evidence editor that mirrors the threat experience while keeping linking drawers and right-side metadata panels out of scope.

## Goals / Non-Goals

**Goals:**
- Provide full-page evidence create and edit views in the workspace UI.
- Use tag-style inputs for NIST controls and tags.
- Trigger NIST-based auto-linking on both create and edit saves.
- Follow existing LiveView patterns, routes, and UI conventions used in threats.

**Non-Goals:**
- Manual linking UI (drawers, dropdowns, entity linkers).
- Evidence file upload or blob storage integration beyond URL input.
- Reworking evidence index layout or filtering behavior.

## Decisions

- **Full-page LiveView over modal form components.** The threat editor is the closest pattern, so evidence editing should use a dedicated LiveView route with subhead actions and a single-column layout.
- **Tag-style NIST controls input.** Aligns with the tag interaction used elsewhere and makes control entry explicit and editable.
- **Auto-linking on save for create and edit.** Reuses Composer linking logic to apply NIST-based linking after persistence; edits should re-run linking to include new control additions.
- **No right sidebar for metadata.** Keep the page focused on evidence content and required inputs; future metadata can be added if the UI expands.

## Risks / Trade-offs

- **Repeated auto-linking on edit could create duplicates** → Mitigated by existing join-table constraints and idempotent insert handling in Composer.
- **NIST tag entry errors** (invalid control IDs) → Mitigated by schema validation errors surfaced in the LiveView form.
- **Limited linking visibility** (no manual linking UI) → Accepted for this change; evidence index still shows linked entities.
