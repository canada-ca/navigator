## ADDED Requirements

### Requirement: Evidence row displays linking buttons

The Evidence index page SHALL display interactive icon buttons for each relationship type (Assumptions, Threats, Mitigations) on every evidence row.

#### Scenario: Linking buttons are visible
- **WHEN** user views the Evidence index page with evidence items
- **THEN** each evidence row displays three linking buttons: Assumptions, Threats, and Mitigations
- **AND** each button shows an appropriate icon (discussion-closed-16, squirrel-16, check-circle-16)
- **AND** each button displays the relationship type name as text

#### Scenario: Counter badges show relationship counts
- **WHEN** an evidence item has linked entities
- **THEN** each linking button displays a counter badge with the number of linked entities of that type
- **AND** the counter shows "0" when no entities of that type are linked

#### Scenario: Buttons are positioned consistently
- **WHEN** user views an evidence row
- **THEN** linking buttons are displayed in a float-right container
- **AND** buttons appear in order: Assumptions, Threats, Mitigations, Edit, Delete
- **AND** linking buttons appear before the Edit and Delete buttons

### Requirement: Clicking linking button opens modal

The system SHALL open a modal dialog when a user clicks any linking button on an evidence row.

#### Scenario: Open Assumptions linking modal
- **WHEN** user clicks the Assumptions button on an evidence row
- **THEN** a modal dialog opens with title "Link evidence to assumptions"
- **AND** the URL changes to `/workspaces/:workspace_id/evidence/:evidence_id/assumptions`
- **AND** the modal displays a dropdown to select assumptions and currently linked assumptions as tags

#### Scenario: Open Threats linking modal
- **WHEN** user clicks the Threats button on an evidence row
- **THEN** a modal dialog opens with title "Link evidence to threats"
- **AND** the URL changes to `/workspaces/:workspace_id/evidence/:evidence_id/threats`
- **AND** the modal displays a dropdown to select threats and currently linked threats as tags

#### Scenario: Open Mitigations linking modal
- **WHEN** user clicks the Mitigations button on an evidence row
- **THEN** a modal dialog opens with title "Link evidence to mitigations"
- **AND** the URL changes to `/workspaces/:workspace_id/evidence/:evidence_id/mitigations`
- **AND** the modal displays a dropdown to select mitigations and currently linked mitigations as tags

#### Scenario: Browser back button closes modal
- **WHEN** user opens a linking modal and clicks browser back button
- **THEN** the modal closes
- **AND** the URL returns to `/workspaces/:workspace_id/evidence`
- **AND** the evidence list remains displayed without page reload

### Requirement: User can add entity links in modal

The system SHALL allow users to add new entity links through the dropdown in the linking modal.

#### Scenario: Add assumption link
- **WHEN** user opens the Assumptions linking modal
- **AND** selects an assumption from the dropdown
- **THEN** the selected assumption appears as a tag button below the dropdown
- **AND** the assumption is removed from the dropdown options
- **AND** the link is not persisted until user clicks Save

#### Scenario: Add multiple links before saving
- **WHEN** user selects multiple entities from the dropdown
- **THEN** each selected entity appears as a tag button
- **AND** all selections remain in the modal until Save is clicked
- **AND** user can continue selecting more entities

#### Scenario: Dropdown shows only unlinkable entities
- **WHEN** user opens a linking modal
- **THEN** the dropdown shows only entities that are not already linked
- **AND** entities that are already linked appear as tag buttons, not in dropdown

### Requirement: User can remove entity links in modal

The system SHALL allow users to remove existing entity links through the linking modal.

#### Scenario: Remove linked entity
- **WHEN** user opens a linking modal with existing linked entities
- **AND** clicks the X button on a linked entity tag
- **THEN** the tag disappears from the linked entities section
- **AND** the entity reappears in the dropdown as selectable
- **AND** the link is not removed from database until user clicks Save

#### Scenario: Remove multiple links before saving
- **WHEN** user removes multiple entity tags
- **THEN** all removed entities reappear in the dropdown
- **AND** changes remain in the modal until Save is clicked

### Requirement: Saving modal persists link changes

The system SHALL persist all link additions and removals when the user saves the linking modal.

#### Scenario: Save new links
- **WHEN** user adds new entity links and clicks Save
- **THEN** the links are persisted to the database via join tables
- **AND** the modal closes
- **AND** the evidence list refreshes showing updated counter badges
- **AND** a success flash message displays

#### Scenario: Save link removals
- **WHEN** user removes entity links and clicks Save
- **THEN** the links are deleted from the database join tables
- **AND** the modal closes
- **AND** the evidence list refreshes showing updated counter badges
- **AND** a success flash message displays

#### Scenario: Save mixed additions and removals
- **WHEN** user adds some links and removes others, then clicks Save
- **THEN** all additions are inserted to join tables
- **AND** all removals are deleted from join tables
- **AND** the modal closes with updated counter badges

#### Scenario: Cancel discards changes
- **WHEN** user makes changes in the modal and clicks Cancel
- **THEN** the modal closes without persisting any changes
- **AND** the evidence list shows original counter badges
- **AND** no database operations occur

### Requirement: Evidence component encapsulates row rendering

The system SHALL use a dedicated EvidenceComponent LiveComponent to render each evidence row.

#### Scenario: Evidence row renders via component
- **WHEN** the Evidence index page displays evidence items
- **THEN** each row is rendered using the EvidenceComponent
- **AND** the component receives the evidence struct with preloaded associations
- **AND** the component displays evidence details: name, type, description, tags, NIST controls, timestamps

#### Scenario: Component handles action buttons
- **WHEN** EvidenceComponent renders
- **THEN** it includes the three linking buttons with correct phx-click handlers
- **AND** it includes Edit and Delete buttons with correct behavior
- **AND** all buttons use consistent styling (is_icon_button)

### Requirement: Backend supports evidence linking operations

The system SHALL provide Composer functions for managing evidence-entity relationships.

#### Scenario: Add assumption to evidence
- **WHEN** system calls `Composer.add_assumption_to_evidence(evidence, assumption)`
- **THEN** a record is inserted into the EvidenceAssumption join table
- **AND** the operation is idempotent (duplicate inserts are ignored)

#### Scenario: Remove assumption from evidence
- **WHEN** system calls `Composer.remove_assumption_from_evidence(evidence, assumption)`
- **THEN** the corresponding record is deleted from the EvidenceAssumption join table
- **AND** the operation succeeds even if no record exists

#### Scenario: Add threat to evidence
- **WHEN** system calls `Composer.add_threat_to_evidence(evidence, threat)`
- **THEN** a record is inserted into the EvidenceThreat join table
- **AND** the operation is idempotent

#### Scenario: Remove threat from evidence
- **WHEN** system calls `Composer.remove_threat_from_evidence(evidence, threat)`
- **THEN** the corresponding record is deleted from the EvidenceThreat join table

#### Scenario: Add mitigation to evidence
- **WHEN** system calls `Composer.add_mitigation_to_evidence(evidence, mitigation)`
- **THEN** a record is inserted into the EvidenceMitigation join table
- **AND** the operation is idempotent

#### Scenario: Remove mitigation from evidence
- **WHEN** system calls `Composer.remove_mitigation_from_evidence(evidence, mitigation)`
- **THEN** the corresponding record is deleted from the EvidenceMitigation join table

### Requirement: EntityLinkerComponent supports evidence source

The existing EntityLinkerComponent SHALL be extended to handle evidence as a source entity type.

#### Scenario: Evidence linking uses EntityLinkerComponent
- **WHEN** user clicks a linking button on an evidence row
- **THEN** the EntityLinkerComponent is rendered with source_entity_type: :evidence
- **AND** the component receives the correct target_entity_type (:assumptions, :threats, or :mitigations)

#### Scenario: Save handler processes evidence relationships
- **WHEN** user saves changes in the evidence linking modal
- **THEN** EntityLinkerComponent's save handler matches on {:evidence, :assumptions}
- **OR** matches on {:evidence, :threats}
- **OR** matches on {:evidence, :mitigations}
- **AND** calls the appropriate Composer add/remove functions

#### Scenario: Entity content helper supports evidence
- **WHEN** EntityLinkerComponent displays evidence in dropdowns or tags
- **THEN** the entity_content helper returns evidence.name
- **AND** does not attempt to access evidence.content (which doesn't exist)
