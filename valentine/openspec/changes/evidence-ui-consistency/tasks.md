## 1. Backend: Add Composer Linking Functions

- [x] 1.1 Add `add_assumption_to_evidence/2` function to Composer after line 890
- [x] 1.2 Add `remove_assumption_from_evidence/2` function to Composer
- [x] 1.3 Add `add_threat_to_evidence/2` function to Composer
- [x] 1.4 Add `remove_threat_from_evidence/2` function to Composer
- [x] 1.5 Add `add_mitigation_to_evidence/2` function to Composer
- [x] 1.6 Add `remove_mitigation_from_evidence/2` function to Composer

## 2. Component: Extend EntityLinkerComponent for Evidence

- [x] 2.1 Add case pattern for `{:evidence, :assumptions}` in handle_event("save") around line 78-105
- [x] 2.2 Add case pattern for `{:evidence, :threats}` in handle_event("save")
- [x] 2.3 Add case pattern for `{:evidence, :mitigations}` in handle_event("save")
- [x] 2.4 Add entity_content/1 helper pattern for Evidence struct to return `evidence.name` around line 152

## 3. Component: Create EvidenceComponent

- [x] 3.1 Create new file `lib/valentine_web/live/workspace_live/components/evidence_component.ex`
- [x] 3.2 Implement render/1 function with evidence row layout (details left, actions right)
- [x] 3.3 Add three linking buttons (Assumptions, Threats, Mitigations) with correct icons and counter badges
- [x] 3.4 Add Edit and Delete buttons
- [x] 3.5 Configure phx-click handlers to use JS.patch for modal URLs
- [x] 3.6 Style buttons consistently with is_icon_button and float-right layout

## 4. LiveView: Update Evidence Index

- [x] 4.1 Add Repo alias to imports in `lib/valentine_web/live/workspace_live/evidence/index.ex` (lines 5-7)
- [x] 4.2 Update mount/3 to preload assumptions, threats, mitigations on evidence list
- [x] 4.3 Update get_workspace/1 to preload related entities (lines 117-119)
- [x] 4.4 Add apply_action/3 pattern for `:assumptions` live action
- [x] 4.5 Add apply_action/3 pattern for `:threats` live action
- [x] 4.6 Add apply_action/3 pattern for `:mitigations` live action
- [x] 4.7 Add handle_info/2 for EntityLinkerComponent save events

## 5. Template: Update Evidence Index Template

- [x] 5.1 Replace `:row` slot content in `index.html.heex` (lines 71-192) to use EvidenceComponent
- [x] 5.2 Add EntityLinkerComponent instance for assumptions linking after PaginatedListComponent
- [x] 5.3 Add EntityLinkerComponent instance for threats linking
- [x] 5.4 Add EntityLinkerComponent instance for mitigations linking
- [x] 5.5 Remove old inline "Linked to..." text display code

## 6. Verification and Testing

- [x] 6.1 Verify linking buttons appear on evidence rows with correct icons
- [x] 6.2 Verify counter badges display correct counts for each relationship type
- [x] 6.3 Test clicking Assumptions button opens modal with correct URL
- [x] 6.4 Test clicking Threats button opens modal with correct URL
- [x] 6.5 Test clicking Mitigations button opens modal with correct URL
- [x] 6.6 Test adding links in modal and saving persists to database
- [x] 6.7 Test removing links in modal and saving deletes from database
- [x] 6.8 Test counter badges update correctly after save
- [x] 6.9 Test browser back button closes modals correctly
- [x] 6.10 Verify no N+1 query issues with preloading
