## 1. Data Layer - Workspace Module

- [x] 1.1 Add `get_evidence_by_controls/1` helper function to `lib/valentine/composer/workspace.ex` after `get_tagged_with_controls/1` (line 70)
- [x] 1.2 Function SHALL filter evidence by non-nil nist_controls
- [x] 1.3 Function SHALL validate control IDs using existing `@nist_id_regex`
- [x] 1.4 Function SHALL return map with control IDs as keys and evidence lists as values
- [x] 1.5 Function SHALL follow exact pattern of `get_tagged_with_controls/1` for consistency

## 2. LiveView Controller - SRTM Index

- [x] 2.1 Update `get_workspace/1` in `lib/valentine_web/live/workspace_live/srtm/index.ex` to add `evidence: []` to preload list (line 136-140)
- [x] 2.2 Add `:evidence_by_control` assign in `mount/3` function calling `Workspace.get_evidence_by_controls(workspace.evidence)` (line 26)
- [x] 2.3 Add `:evidence_by_control` assign in `handle_info({:update_filter, filters}, socket)` to keep evidence in sync when filters change (line 58)
- [x] 2.4 Add `sort_evidence_by_numeric_id/1` private helper function before final `end` (line 177)
- [x] 2.5 Function SHALL use `Enum.sort_by(evidence_list, & &1.numeric_id)` for consistent ordering

## 3. Template - SRTM View

- [x] 3.1 Locate "In scope" tab control display in `lib/valentine_web/live/workspace_live/srtm/index.html.heex` (line 154-156)
- [x] 3.2 Modify the `<div class="">{control.nist_id}</div>` line to include evidence labels
- [x] 3.3 Add for loop iterating over `sort_evidence_by_numeric_id(Map.get(@evidence_by_control, control.nist_id, []))`
- [x] 3.4 Each evidence SHALL render as `<a>` tag with href using `~p` sigil path `/workspaces/#{@workspace.id}/evidence/#{evidence.id}`
- [x] 3.5 Link SHALL have `target="_blank"` attribute to open in new tab
- [x] 3.6 Link SHALL have `class="ml-1 cursor-pointer"` for left margin spacing and pointer cursor
- [x] 3.7 Link SHALL have `title={evidence.name}` for native browser tooltip
- [x] 3.8 Link SHALL contain `<.state_label is_small is_open>#{evidence.numeric_id}</.state_label>` component
- [x] 3.9 Verify "Out of scope" and "Not allocated" tabs remain unchanged (no evidence labels)

## 4. Testing

- [x] 4.1 Create test workspace with NIST controls in "In scope" category
- [x] 4.2 Create evidence records with nist_controls containing test control IDs (e.g., ["AC-1", "SC-7"])
- [x] 4.3 Navigate to SRTM page and verify evidence labels appear next to control IDs in "In scope" tab
- [x] 4.4 Verify evidence labels are sorted by numeric_id in ascending order
- [x] 4.5 Verify clicking evidence label opens evidence detail page in new tab
- [x] 4.6 Verify hovering over evidence label shows tooltip with evidence name
- [x] 4.7 Verify control with no evidence displays only control ID (no errors)
- [x] 4.8 Verify "Out of scope" tab shows no evidence labels
- [x] 4.9 Verify "Not allocated" tab shows no evidence labels
- [x] 4.10 Apply filters and verify evidence labels persist correctly
- [x] 4.11 Test with nil nist_controls on evidence (should be ignored)
- [x] 4.12 Test with invalid control ID format (should be filtered out)
- [x] 4.13 Test with 10+ evidence on one control (verify all display correctly)

## 5. Edge Cases & Performance

- [x] 5.1 Verify page loads successfully with 0 evidence records
- [x] 5.2 Verify page loads successfully with 100+ evidence records
- [x] 5.3 Verify no N+1 queries occur (evidence preloaded once)
- [x] 5.4 Update evidence to remove NIST control, refresh page, verify label removed
- [x] 5.5 Add NIST control to evidence, refresh page, verify label appears
- [x] 5.6 Delete evidence, refresh page, verify label removed
- [x] 5.7 Verify evidence with multiple control IDs appears under each control
- [x] 5.8 Verify long evidence names in tooltips display correctly

## 6. Documentation & Cleanup

- [x] 6.1 Add docstring to `get_evidence_by_controls/1` explaining purpose and return value
- [x] 6.2 Verify code follows Elixir style guide and existing codebase conventions
- [x] 6.3 Verify all function names use snake_case
- [x] 6.4 Verify private functions use `defp` keyword
- [x] 6.5 Remove any debugging code or console logs
