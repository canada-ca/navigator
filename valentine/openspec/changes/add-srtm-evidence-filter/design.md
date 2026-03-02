## Context

The SRTM (Security Requirements Traceability Matrix) view displays controls categorized as "Not allocated", "Out of scope", and "In scope". The "In scope" tab shows controls with their associated evidence badges. Currently, users must manually scan through all in-scope controls to identify which ones need evidence documentation.

**Current State:**
- Evidence is displayed as numbered badges (#1, #2, etc.) next to control IDs
- `@evidence_by_control` map already exists, grouping evidence by control NIST ID
- SRTM uses TabNavComponent with three tabs
- Existing filters (Profile, Type, Class, NIST Family) work globally across all tabs

**Constraints:**
- Must use existing PrimerLive components (no custom components unless absolutely necessary)
- Follow existing codebase patterns (filter state management, helper functions)
- Filter should only affect "In scope" tab (evidence is only relevant there)
- Must preserve existing evidence badge display functionality

## Goals / Non-Goals

**Goals:**
- Enable users to filter in-scope controls by evidence attachment status
- Provide clear visual feedback via counter badges showing control counts
- Maintain filter simplicity with three mutually exclusive options
- Use built-in PrimerLive components for consistency

**Non-Goals:**
- Filtering by specific evidence types or tags
- Multi-select filtering (combining "needs evidence" with other criteria)
- Evidence filtering in "Not allocated" or "Out of scope" tabs
- Creating custom filter components
- Adding evidence filtering to other workspace views

## Decisions

### Decision 1: Use `underline_nav` instead of `button_group` or custom component

**Rationale:**
- PrimerLive's `underline_nav` is semantically designed for tab-like filtering navigation
- Provides built-in selected state with underline styling
- Lighter visual weight than button_group, appropriate for filtering use case
- No custom component needed - follows "use existing patterns" principle
- User explicitly requested underline_nav after consideration

**Alternatives considered:**
- `button_group`: More action-oriented semantics, heavier visual weight
- Custom component: Unnecessary complexity, violates codebase conventions
- Dropdown filter: Less discoverable for only 3 options, requires more clicks

### Decision 2: Place filter inside "In scope" tab content, not in global header

**Rationale:**
- Evidence is only displayed in "In scope" tab
- Placing filter in tab keeps it contextually relevant
- Avoids confusing users with a filter that has no effect on other tabs
- Matches user's explicit requirement for placement

**Alternatives considered:**
- Global header: Would be misleading since it only affects one tab
- Separate filter bar above tabs: Adds unnecessary visual separation

### Decision 3: Filter state persists across tab switches, resets on other filter changes

**Rationale:**
- Simplest implementation - no additional reset logic needed in tab switching
- Prevents confusing "no results" state when changing other filters
- User can switch between tabs and return to see their evidence filter still active
- User requested "whichever is easiest to implement"

**Alternatives considered:**
- Reset on tab switch: Requires additional state management, more complex
- Never reset: Could cause confusion when other filters change data set

### Decision 4: Calculate counts in template, not in LiveView state

**Rationale:**
- Counts are derived from existing `@controls[:in_scope]` and `@evidence_by_control`
- Recalculating on render is performant for typical control list sizes
- Avoids state synchronization complexity
- Simpler code: one helper function vs managing multiple assigns

**Alternatives considered:**
- Store counts in socket assigns: Requires updating in multiple handle_info/event handlers
- Calculate once in mount: Would need recalculation on every filter change anyway

### Decision 5: Use atoms for filter values (`:all`, `:needs_evidence`, `:has_evidence`)

**Rationale:**
- Follows Elixir conventions for internal state
- Type-safe pattern matching in case statements
- Consistent with how the codebase handles enum-like values

**Alternatives considered:**
- Strings: Less idiomatic Elixir, no compile-time checking

## Risks / Trade-offs

**[Risk]** Filter counts recalculated on every render of "In scope" tab
→ **Mitigation**: Count calculation is O(n) where n = in-scope controls. Typical workspaces have < 100 in-scope controls, making this negligible. If performance becomes an issue, can memoize in socket assigns.

**[Risk]** Users might expect filter to persist when navigating away from SRTM and returning
→ **Mitigation**: Filter state lives in socket assigns which are reset on LiveView unmount. This is consistent with other filters in the app. Document in specs that state doesn't persist across navigation.

**[Trade-off]** Filter only works in "In scope" tab, not a global SRTM filter
→ **Accepted**: Evidence is only displayed in "In scope" tab. Filtering other tabs by evidence status would be confusing since those controls don't show evidence badges.

**[Trade-off]** Counter badges always show all three counts, even when filter is active
→ **Accepted**: This provides users with full context (e.g., "12 of 45 controls need evidence"). Alternative of hiding counts would remove valuable information.

**[Risk]** Component state can be lost or become invalid if parent LiveView updates component without explicit state override
→ **Mitigation**: Implemented validation in TabNavComponent to check that preserved state values are not just present but also valid (non-empty strings). This prevents empty/invalid values from being used and ensures proper fallback to default values.

## Implementation Approach

### Data Flow

1. **State Management:**
   - Add `:evidence_filter` to socket assigns (values: `:all`, `:needs_evidence`, `:has_evidence`)
   - Initialize to `:all` in `mount/3`
   - Update via `handle_event("select_evidence_filter", %{"filter" => filter}, socket)`
   - Reset to `:all` in `handle_info({:update_filter, filters}, socket)` when other filters change

2. **Filtering Logic:**
   - Helper function `filter_in_scope_by_evidence/3` takes in-scope controls, evidence map, and filter atom
   - Uses `Map.filter/2` to filter controls based on presence in `evidence_by_control` map
   - Applied in template before rendering control list

3. **Count Calculation:**
   - Helper function `count_controls_by_evidence/2` returns map with counts for all three filter options
   - Calculated in template before rendering `underline_nav`
   - Uses `Enum.count/2` to count controls with/without evidence

### UI Structure

```heex
<:tab_content :let={tab}>
  <!-- Calculate counts once -->
  <% evidence_counts = if :in_scope, do: count_controls_by_evidence(...), else: %{} %>
  
  <!-- Show filter only in "In scope" tab -->
  <%= if :in_scope do %>
    <.underline_nav>
      <:item phx-click="select_evidence_filter" phx-value-filter="all">
        <span>All</span>
        <.counter>{evidence_counts.all}</.counter>
      </:item>
      <!-- ... other items ... -->
    </.underline_nav>
  <% end %>
  
  <!-- Apply filter -->
  <% filtered_controls = if :in_scope, do: filter_in_scope_by_evidence(...), else: @controls[tab] %>
  
  <!-- Show empty state or controls -->
  <%= if empty, do: blankslate, else: render_controls %>
</:tab_content>
```

### Helper Functions

```elixir
defp filter_in_scope_by_evidence(in_scope_controls, evidence_by_control, :all), do: in_scope_controls
defp filter_in_scope_by_evidence(in_scope_controls, evidence_by_control, :needs_evidence) do
  Map.filter(in_scope_controls, fn {nist_id, _} -> 
    Map.get(evidence_by_control, nist_id, []) == []
  end)
end
defp filter_in_scope_by_evidence(in_scope_controls, evidence_by_control, :has_evidence) do
  Map.filter(in_scope_controls, fn {nist_id, _} -> 
    Map.get(evidence_by_control, nist_id, []) != []
  end)
end

defp count_controls_by_evidence(in_scope_controls, evidence_by_control) do
  total = map_size(in_scope_controls)
  has_evidence = Enum.count(in_scope_controls, fn {nist_id, _} -> 
    Map.get(evidence_by_control, nist_id, []) != []
  end)
  %{all: total, has_evidence: has_evidence, needs_evidence: total - has_evidence}
end
```

### Critical Implementation Notes

**Component State Validation:** The TabNavComponent must validate that `current_tab` is a valid non-empty string before using it. Invalid values (including empty strings from initialization) must fall through to the default first tab ID.

**Nil Safety:** Template uses `map_size(filtered_controls)` which requires `filtered_controls` to never be nil. This is ensured by:
1. TabNavComponent validates `current_tab` is a valid non-empty string
2. `mount/3` ensures `@controls` always contains all three keys (`:not_allocated`, `:out_of_scope`, `:in_scope`)
3. `String.to_existing_atom(tab)` always receives a valid tab ID string

## Open Questions

### Resolved During Implementation

**Q: Are there edge cases where component state preservation could fail?**
→ **A:** Yes. Discovered that `TabNavComponent.update/2` was not properly validating preserved state values. Empty strings were treated as valid, causing downstream nil crashes. Fixed by adding validation logic that checks for non-empty strings before using preserved values.

**Q: Should we add defensive nil checks in the template?**
→ **A:** The proper fix is at the component level (TabNavComponent), not in the template. Template assumes valid state is provided by components. However, added `type="button"` attributes as defensive programming practice following codebase conventions.

## Lessons Learned

### LiveView Component State Preservation

During implementation, we discovered a critical issue in the `TabNavComponent` that affected this feature. The component's `update/2` function was not properly preserving component state across parent LiveView updates.

**Problem:** Using the `||` operator for fallback values treats empty strings as truthy, causing invalid values to be used instead of falling through to valid defaults.

**Solution:** Validate that values are not only present but also semantically valid before using them. Use `cond` with explicit validation instead of relying on truthiness.

**Key Insight:** When preserving stateful component values across updates, always validate that the value is not just present but also semantically valid for your use case. Empty strings, while truthy in Elixir, may not be valid values in your domain.

**Impact:** This pattern should be considered for other stateful LiveView components in the codebase.
