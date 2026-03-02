## Context

The SRTM view is implemented as a Phoenix LiveView component in `lib/valentine_web/live/workspace_live/srtm/index.html.heex`. The current layout displays three categories of security controls (Not allocated, Out of scope, In scope) in both a percentage summary section and as navigable tabs.

**Current Layout Structure:**
- Top section: Three percentage boxes showing control distribution
  - Left (col-md-4): Not allocated (solo)
  - Right (col-md-8): Out of scope + In scope (split into two col-md-6 boxes)
- Bottom section: Tab navigation for detailed control views
  - Tab order: Not allocated, Out of scope, In scope

The backend logic in `index.ex` calculates control allocation and is order-agnostic - it stores controls in a map with keys `:not_allocated`, `:out_of_scope`, and `:in_scope`.

## Goals / Non-Goals

**Goals:**
- Reorder visual presentation to prioritize in-scope controls
- Maintain consistent ordering between percentage display and tabs
- Preserve all existing functionality (evidence filtering, control display, export)
- Keep responsive layout working across mobile and desktop

**Non-Goals:**
- Changes to backend calculation logic or data structure
- Changes to export functionality or order
- Changes to filtering behavior or control grouping logic
- Changes to the component architecture or state management

## Decisions

### Decision 1: Template-only change
**Choice:** Modify only the HTML template (`index.html.heex`), not the Elixir module (`index.ex`)

**Rationale:** The backend already stores controls in a map structure that is order-agnostic. The display order is entirely determined by the template's iteration and rendering logic. This minimizes risk and keeps the change localized.

**Alternative considered:** Creating a new helper function to define display order - rejected as unnecessarily complex for a simple reordering.

### Decision 2: Layout structure (Option A)
**Choice:** Maintain the 8-4 column split, but swap which categories occupy each side
- Left (col-md-8): In scope + Out of scope (split into two col-md-6 boxes)
- Right (col-md-4): Not allocated (solo)

**Rationale:** Gives more visual weight to the two "allocated" states while de-emphasizing "not allocated". Maintains the existing visual pattern where related items are grouped together.

**Alternative considered:** Three equal boxes (col-md-4 each) - rejected because it doesn't provide visual hierarchy.

### Decision 3: Border and border-radius classes
**Choice:** Swap the border classes to maintain proper rendering:
- In scope: `border border-right-0 rounded-left-2` (previously on Out of scope)
- Out of scope: `border rounded-right-2` (previously on In scope)
- Not allocated: Keep `border rounded-2` (no shared border)

**Rationale:** When two boxes are adjacent horizontally, the left box needs `border-right-0 rounded-left-2` and the right needs `border rounded-right-2` to create a single unified visual block. This maintains the current visual design intent.

## Risks / Trade-offs

**Risk:** Users accustomed to the old order may be temporarily disoriented
→ Mitigation: The new order is more intuitive (most important first), so the learning curve should be minimal. Consider adding a release note if this is customer-facing.

**Risk:** CSS classes might not render correctly if not swapped properly
→ Mitigation: Manual testing of the layout in both desktop and mobile views before deployment. Visual QA checklist included in tasks.

**Risk:** Tab component state might not handle the new order correctly
→ Mitigation: The `TabNavComponent` is data-driven and order-agnostic - it simply iterates over the provided tabs array. No special handling required.

**Trade-off:** Not allocated information is now "buried" on the right
→ Accepted: This is intentional. Not allocated controls represent work not yet started, which is less important than in-scope controls (active work) or out-of-scope controls (documented assumptions).

## Migration Plan

**Deployment:**
1. Deploy template changes (no backend changes required)
2. No database migrations needed
3. No environment variable or configuration changes
4. LiveView will hot-reload the changes automatically in development

**Rollback:**
If issues arise, revert the commit to restore the previous order. Since this is template-only, rollback is instant with no data implications.

**Testing:**
- Visual QA on desktop viewport (col-md-* classes active)
- Visual QA on mobile viewport (col-12 fallback)
- Verify tab navigation works correctly
- Verify evidence filtering in "In scope" tab still functions
- Verify export functionality includes controls in correct logical order (not display order)

## Open Questions

None - the change scope is well-defined and straightforward.
