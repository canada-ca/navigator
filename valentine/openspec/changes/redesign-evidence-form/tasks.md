## 1. Backend: Evidence Schema Updates

- [x] 1.1 Add `:description_only` to evidence_type Ecto.Enum in `lib/valentine/composer/evidence.ex`
- [x] 1.2 Add `:description` to required fields in changeset function
- [x] 1.3 Update `validate_evidence_type_content/1` to handle `:description_only` case (no attachment fields required)
- [x] 1.4 Verify existing validation cases for `:blob_store_link` and `:json_data` remain unchanged

## 2. Backend: Evidence Helpers

- [x] 2.1 Add "Description Only" label for `:description_only` type in `evidence_helpers.ex`
- [x] 2.2 Verify helper functions return correct labels for all three evidence types

## 3. Backend: LiveView Event Handlers

- [x] 3.1 Add `handle_event("set_evidence_type", %{"type" => type}, socket)` in `show.ex`
- [x] 3.2 Add `handle_event("clear_evidence_type", _, socket)` to reset to `:description_only` and clear attachment fields
- [x] 3.3 Update `apply_action(:new, _params)` to default evidence_type to `:description_only`
- [x] 3.4 Update `build_evidence_attrs/1` to handle `:description_only` case (exclude attachment fields from params)

## 4. Frontend: Template Structure Reorganization

- [x] 4.1 Restructure template to use two-column layout with `.col-8` (left) and `.col-3` (right) from the start
- [x] 4.2 Move NIST Controls and Tags sections to right sidebar at top level
- [x] 4.3 Remove full-width divider between name and description sections
- [x] 4.4 Update all subhead spacing from `mb-4` to `mb-3`

## 5. Frontend: Name Field Updates

- [x] 5.1 Add "Name *" label above name input field
- [x] 5.2 Update name input to use classes: `f3 border-0 px-0 py-2 color-fg-default`
- [x] 5.3 Add evidence number display `#EVD-{numeric_id}` below name field (conditional on existing evidence)
- [x] 5.4 Style evidence number with muted text color

## 6. Frontend: Description Field Updates

- [x] 6.1 Add "Description *" label above description section
- [x] 6.2 Verify TabNavComponent (Write/Preview) remains functional
- [x] 6.3 Remove any box wrapper around tab navigation if present

## 7. Frontend: Attach Evidence Section Redesign

- [x] 7.1 Add "Attach Evidence (Optional)" subhead with `mb-3` spacing
- [x] 7.2 Implement conditional rendering based on evidence_type:
  - When `:description_only`: Show two card buttons
  - When `:blob_store_link`: Show URL input + Clear button
  - When `:json_data`: Show JSON textarea + Clear button
- [x] 7.3 Create compact card buttons with horizontal layout (icon + text on same line)
- [x] 7.4 Add "Link URL" card button with `phx-click="set_evidence_type"` and `phx-value-type="blob_store_link"`
- [x] 7.5 Add "Paste JSON" card button with `phx-click="set_evidence_type"` and `phx-value-type="json_data"`
- [x] 7.6 Style card buttons using `d-flex flex-items-center` for horizontal icon+text layout
- [x] 7.7 Add "Clear" button to URL and JSON sections with `phx-click="clear_evidence_type"`
- [x] 7.8 Ensure Clear button resets form to show card buttons again

## 8. Testing: Backend Validation

- [x] 8.1 Test creating description-only evidence with valid attributes succeeds
- [x] 8.2 Test creating description-only evidence with attachment fields fails validation
- [x] 8.3 Test creating evidence without description fails validation for all types
- [x] 8.4 Test existing blob_store_link and json_data evidence validation unchanged

## 9. Testing: LiveView Event Handlers

- [ ] 9.1 Test set_evidence_type event changes evidence type and updates form state
- [ ] 9.2 Test clear_evidence_type event resets to description_only and clears attachment fields
- [ ] 9.3 Test new evidence form initializes with description_only type
- [ ] 9.4 Test evidence can transition between all three types

## 10. Testing: Evidence Form Integration

- [ ] 10.1 Test creating new description-only evidence through the form succeeds
- [ ] 10.2 Test creating evidence with URL attachment through the form succeeds
- [ ] 10.3 Test creating evidence with JSON attachment through the form succeeds
- [ ] 10.4 Test editing existing evidence preserves evidence type and data
- [ ] 10.5 Test switching evidence type clears previous attachment data
- [ ] 10.6 Test evidence number displays when editing existing evidence
- [ ] 10.7 Test form validates required fields (name, description)

## 11. Final Verification

- [ ] 11.1 Run full test suite and ensure all tests pass
- [ ] 11.2 Manually test creating new description-only evidence
- [ ] 11.3 Manually test editing existing evidence of all types
- [ ] 11.4 Manually test state transitions between evidence types
- [ ] 11.5 Verify backward compatibility with existing evidence records
- [ ] 11.6 Verify form styling matches design reference
