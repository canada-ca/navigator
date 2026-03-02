## Context

The SRTM (Security Requirements Traceability Matrix) LiveView displays NIST controls grouped into three categories: "Not allocated", "Out of scope", and "In scope". Currently, it shows controls with their related mitigations, threats, and assumptions by matching NIST control IDs in the `tags` field of those entities.

Evidence records have a separate `nist_controls` field (array of strings) that links them to NIST controls. However, this evidence data is not currently displayed in the SRTM view, requiring auditors to manually cross-reference evidence records.

**Existing Patterns:**
- The codebase uses `Workspace.get_tagged_with_controls/1` to group mitigations/threats/assumptions by NIST control IDs from their `tags` field
- The SRTM view preloads associations using Ecto's preload syntax
- The application uses GitHub Primer CSS (PrimerLive) for UI components
- Evidence component already displays numeric IDs and NIST controls as secondary labels

**Constraints:**
- Must follow existing codebase patterns and conventions
- No PubSub for real-time updates (consistent with current SRTM behavior)
- Performance must remain acceptable (currently loads mitigations/threats/assumptions)

## Goals / Non-Goals

**Goals:**
- Display all evidence tagged with each NIST control ID in the "In scope" tab
- Provide one-click navigation from control to evidence detail page
- Show evidence name in tooltip for quick context
- Use consistent styling matching the existing evidence component
- Maintain acceptable page load performance

**Non-Goals:**
- Real-time updates when evidence is modified (manual refresh is acceptable)
- Displaying evidence in "Out of scope" or "Not allocated" tabs (future enhancement)
- Filtering or grouping evidence by type
- Evidence preview modal or inline display

## Decisions

### 1. Data Loading: Preload Evidence in `get_workspace/1`

**Decision:** Add `evidence: []` to the existing preload list in `get_workspace/1`

**Rationale:**
- Consistent with current pattern for mitigations/threats/assumptions
- Single database query via Ecto preload (no N+1)
- Evidence data needed for all controls, so eager loading is appropriate
- Simple and follows established codebase patterns

**Alternatives Considered:**
- Lazy load evidence per control: Would cause N+1 queries, poor performance
- Separate API call: Over-engineering for simple display need
- GraphQL/DataLoader: Not used elsewhere in codebase

### 2. Evidence Grouping: Mirror `get_tagged_with_controls/1` Pattern

**Decision:** Create `Workspace.get_evidence_by_controls/1` helper function following the exact pattern of `get_tagged_with_controls/1`

**Rationale:**
- Maintains consistency - developers already understand this pattern
- Reuses existing `@nist_id_regex` for validation
- Returns same map structure `%{nist_id => [items]}`
- Clear separation of concerns - Workspace module handles data transformations

**Implementation:**
```elixir
def get_evidence_by_controls(evidence_collection) do
  evidence_collection
  |> Enum.filter(&(&1.nist_controls != nil))
  |> Enum.reduce(%{}, fn evidence, acc ->
    evidence.nist_controls
    |> Enum.filter(&Regex.match?(@nist_id_regex, &1))
    |> Enum.reduce(acc, fn control_id, acc ->
      Map.update(acc, control_id, [evidence], &(&1 ++ [evidence]))
    end)
  end)
end
```

**Alternatives Considered:**
- Database query with JOIN: Over-optimization, evidence already loaded
- LiveView helper function: Breaks separation of concerns
- Inline in template: Not reusable, harder to test

### 3. Styling: Small State Labels with Tooltips

**Decision:** Use `<.state_label is_small is_open>` with `title` attribute for tooltips

**Rationale:**
- State label with "open" status provides visual indication of available/active evidence
- Small size maintains visual hierarchy (control ID is primary)
- Green color is more visually distinct than gray secondary labels
- Native `title` attribute provides tooltips without JavaScript
- Consistent with Primer CSS design system

**Visual Pattern:**
```
AC-1 #1 #3 #7
     ^^ ^^ ^^ Green state labels (small, open status), clickable
```

**Alternatives Considered:**
- Secondary labels: Less visually distinct, gray color less noticeable
- Primary labels: Too prominent, competes with control ID
- Plain text links: Less clear that they're interactive
- Icon prefix: Adds visual clutter, not needed
- Custom tooltip component: Over-engineering, browser tooltips sufficient

### 4. Link Behavior: Open in New Tab

**Decision:** Use `target="_blank"` to open evidence pages in new tabs

**Rationale:**
- Preserves SRTM context - users don't lose their place
- Consistent with other export/external links in the app (Excel export, threat model export)
- Simple to implement - standard HTML attribute
- User expectation for reference links

**Alternatives Considered:**
- Same tab navigation: Loses SRTM context, requires back button
- Modal preview: More complex, requires additional component development
- JS.patch: Stays in same LiveView, but loses SRTM state

### 5. Scope: "In Scope" Tab Only

**Decision:** Only add evidence labels to the "In scope" tab

**Rationale:**
- "In scope" controls are the primary focus for compliance and audits
- Evidence is most relevant for controls being actively implemented
- Simpler initial implementation, easier to test
- Can expand to other tabs in future if needed

**Alternatives Considered:**
- All tabs: More comprehensive, but "Out of scope" evidence is less relevant
- Configurable per tab: Over-engineering for initial feature

### 6. Update Strategy: Manual Refresh

**Decision:** No PubSub or automatic updates - users refresh page manually

**Rationale:**
- Consistent with current SRTM behavior for mitigations/threats/assumptions
- Simpler implementation - no broadcast logic needed
- Evidence changes are infrequent (not real-time collaboration scenario)
- Matches user expectations - SRTM is a report view, not a live dashboard

**Alternatives Considered:**
- PubSub broadcasts: Added complexity, inconsistent with current SRTM
- Polling: Unnecessary for infrequent updates
- WebSocket: Over-engineering

## Risks / Trade-offs

### Risk: Multiple Evidence per Control (10+)
**Impact:** UI could become cluttered with many evidence labels
**Mitigation:** 
- Sort by numeric_id for predictable order
- Future: Add count badge `Evidence (12)` if >5 evidence
- Current: Acceptable for initial release, most controls have <5 evidence

### Risk: Performance with Large Evidence Sets (100+)
**Impact:** Preloading and grouping could slow page load
**Mitigation:**
- Evidence already has numeric_id index for fast sorting
- Map grouping is O(n) operation, acceptable for reasonable dataset sizes
- Future: Pagination or lazy loading if becomes an issue
- Current: Preloading pattern works well for mitigations/threats/assumptions

### Trade-off: No Real-time Updates
**Impact:** Evidence changes don't appear until page refresh
**Benefit:** Simpler implementation, consistent with current behavior
**Acceptable Because:** Evidence modifications are infrequent, SRTM is primarily a read-only view

### Trade-off: "In Scope" Tab Only
**Impact:** Evidence for "Out of scope" controls not visible
**Benefit:** Cleaner initial implementation, focused on primary use case
**Acceptable Because:** Can be extended to other tabs in future if users request it

## Migration Plan

**Deployment Steps:**
1. Deploy code changes (no database migrations required)
2. Existing SRTM pages continue to work (backwards compatible)
3. New evidence labels appear immediately for users with evidence records
4. No data migration or seeding needed

**Rollback Strategy:**
- Simple code revert (3 files modified)
- No database changes to undo
- Zero downtime rollback possible

**Verification:**
- Check SRTM page loads successfully
- Verify evidence labels appear for controls with evidence
- Test clicking evidence labels opens correct pages
- Verify tooltips show evidence names on hover
