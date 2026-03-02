## 1. Add Filter State Management

- [x] 1.1 Add `:evidence_filter` assign to socket in `mount/3` (initialize to `:all`)
- [x] 1.2 Add `:evidence_filter` assign reset to `:all` in `handle_info({:update_filter, filters}, socket)`
- [x] 1.3 Add `handle_event("select_evidence_filter", %{"filter" => filter}, socket)` to handle filter selection

## 2. Create Helper Functions

- [x] 2.1 Add `filter_in_scope_by_evidence/3` helper function to filter controls by evidence status
- [x] 2.2 Add `count_controls_by_evidence/2` helper function to calculate counts for all three filter options

## 3. Update Template with Filter UI

- [x] 3.1 Add evidence counts calculation in `:tab_content` slot (before filter UI)
- [x] 3.2 Add conditional check to only show filter in "In scope" tab
- [x] 3.3 Add `underline_nav` component with three filter items ("All", "Needs evidence", "Evidence attached")
- [x] 3.4 Add `counter` badges to each filter item displaying calculated counts
- [x] 3.5 Add `is_selected` binding based on `@evidence_filter` value
- [x] 3.6 Add `phx-click` and `phx-value-filter` attributes to each filter item

## 4. Apply Filtering to Control List

- [x] 4.1 Add filtered_controls variable that applies evidence filter for "In scope" tab
- [x] 4.2 Update control enumeration to use filtered_controls instead of @controls[tab]
- [x] 4.3 Add empty state check using `map_size(filtered_controls) == 0`
- [x] 4.4 Add blankslate component with "No results found" message for empty state

## 5. Testing and Verification

- [x] 5.1 Verify filter UI only appears in "In scope" tab
- [x] 5.2 Verify counter badges show correct counts on initial load
- [x] 5.3 Verify "All" filter shows all in-scope controls
- [x] 5.4 Verify "Needs evidence" filter shows only controls without evidence
- [x] 5.5 Verify "Evidence attached" filter shows only controls with evidence
- [x] 5.6 Verify empty state displays when filter returns no results
- [x] 5.7 Verify filter selection is visually indicated with underline
- [x] 5.8 Verify filter persists when switching between tabs
- [x] 5.9 Verify filter resets to "All" when changing Profile filter
- [x] 5.10 Verify filter resets to "All" when changing Type filter
- [x] 5.11 Verify filter resets to "All" when changing Class filter
- [x] 5.12 Verify filter resets to "All" when changing NIST Family filter
- [x] 5.13 Verify counter badges update when other filters change
- [x] 5.14 Verify evidence badges remain visible and clickable on filtered controls

## 6. Implementation Corrections

### 6.1 TabNavComponent State Preservation Issue

- [x] 6.1.1 Fixed TabNavComponent `update/2` to prevent empty string `""` from being used as `current_tab`
- [x] 6.1.2 Added validation helper `valid_value?/1` to check for non-empty string values
- [x] 6.1.3 Updated `current_tab` assignment logic to use `cond` with proper value validation
- [x] 6.1.4 Prevented nil propagation crash when `@controls[atom]` returned nil

**Issue:** TabNavComponent's `update/2` function used `||` operator which treated empty string `""` as truthy, causing `current_tab` to remain `""` instead of falling through to the first valid tab ID. This resulted in LiveView crashes with `BadMapError: expected a map, got: nil`.

**Solution:** Changed from `||` chain to `cond` with validation function that checks `is_binary(val) and val != ""`, ensuring only valid non-empty strings are used for `current_tab`.

**File Modified:** `lib/valentine_web/live/workspace_live/components/tab_nav_component.ex`

### 6.2 Defensive Button Type Attributes

- [x] 6.2.1 Added `type="button"` to all `underline_nav` filter items

**Rationale:** Follows codebase conventions and prevents potential form submission behavior.

**File Modified:** `lib/valentine_web/live/workspace_live/srtm/index.html.heex` (lines 154, 163, 172)
