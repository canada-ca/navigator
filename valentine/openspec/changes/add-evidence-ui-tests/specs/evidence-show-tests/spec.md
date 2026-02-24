## ADDED Requirements

## Testing Scope Note

These requirements focus on user-facing behavior through both unit and integration tests.
Private helper functions (build_evidence_attrs, parse_json_content, encode_content,
normalize_evidence_type) are validated indirectly through create/update scenarios
rather than being tested directly, following Elixir best practices.

### Requirement: Evidence.Show mounts with proper initialization
The LiveView SHALL initialize with workspace context and empty form state when mounted.

#### Scenario: Mount for new evidence
- **WHEN** mounting with valid workspace_id
- **THEN** socket assigns workspace_id, workspace, empty errors, empty changes, and empty input fields

### Requirement: Evidence.Show handles new action
The LiveView SHALL set up form state for creating new evidence when action is :new.

#### Scenario: Handle params for new action
- **WHEN** handle_params is called with :new action
- **THEN** socket assigns page title "Create Evidence", empty evidence struct, and changes with workspace_id and default values

### Requirement: Evidence.Show handles edit action
The LiveView SHALL load existing evidence and populate form state when action is :edit.

#### Scenario: Handle params for edit action
- **WHEN** handle_params is called with :edit action and valid evidence ID
- **THEN** socket assigns page title "Edit Evidence", loaded evidence, changes from evidence struct, and encoded JSON content

### Requirement: Evidence.Show updates form fields
The LiveView SHALL update the changes map when form fields are modified by the user.

#### Scenario: Update content_raw field
- **WHEN** user modifies content_raw textarea
- **THEN** socket updates content_raw assign without modifying changes map

#### Scenario: Update evidence_type field
- **WHEN** user selects different evidence type
- **THEN** socket normalizes and updates evidence_type in changes map

#### Scenario: Update text fields
- **WHEN** user modifies name or description fields
- **THEN** socket updates corresponding keys in changes map

#### Scenario: Handle unknown field updates
- **WHEN** update_field receives unknown field name
- **THEN** socket ignores update gracefully without errors

### Requirement: Evidence.Show manages tags and NIST controls
The LiveView SHALL allow users to add and remove tags and NIST controls using input fields.

#### Scenario: Set tag input value
- **WHEN** user types in tags input field
- **THEN** socket updates tag_input assign

#### Scenario: Set NIST control input value
- **WHEN** user types in nist_controls input field
- **THEN** socket updates nist_control_input assign

#### Scenario: Add tag to list
- **WHEN** user submits non-empty tag input
- **THEN** socket adds tag to tags list in changes and clears input

#### Scenario: Add NIST control to list
- **WHEN** user submits non-empty NIST control input
- **THEN** socket adds control to nist_controls list in changes and clears input

#### Scenario: Prevent duplicate tags
- **WHEN** user tries to add existing tag
- **THEN** socket ignores duplicate without modification

#### Scenario: Ignore empty tag input
- **WHEN** user submits empty tag input
- **THEN** socket ignores submission without modification

#### Scenario: Remove tag from list
- **WHEN** user clicks remove on tag
- **THEN** socket removes tag from tags list in changes

#### Scenario: Remove NIST control from list
- **WHEN** user clicks remove on NIST control
- **THEN** socket removes control from nist_controls list in changes

### Requirement: Evidence.Show creates new evidence
The LiveView SHALL create evidence with proper validation when save is triggered for new evidence.

#### Scenario: Create evidence with valid json_data
- **WHEN** user saves new evidence with valid JSON content
- **THEN** system creates evidence, shows success flash, and navigates to evidence show page

#### Scenario: Create evidence with valid blob_store_link
- **WHEN** user saves new evidence with blob_store_link type and URL
- **THEN** system creates evidence with nil content and navigates to evidence show page

#### Scenario: Handle invalid JSON content
- **WHEN** user saves evidence with malformed JSON
- **THEN** socket assigns content validation errors without creating evidence

#### Scenario: Handle validation errors
- **WHEN** user saves evidence with invalid attributes
- **THEN** socket assigns changeset errors without creating evidence

### Requirement: Evidence.Show updates existing evidence
The LiveView SHALL update evidence and apply entity linking when save is triggered for existing evidence.

#### Scenario: Update evidence successfully
- **WHEN** user saves changes to existing evidence
- **THEN** system updates evidence, applies linking, shows success flash, and navigates to evidence show page

#### Scenario: Handle update validation errors
- **WHEN** user saves invalid changes to existing evidence
- **THEN** socket assigns changeset errors without updating evidence
