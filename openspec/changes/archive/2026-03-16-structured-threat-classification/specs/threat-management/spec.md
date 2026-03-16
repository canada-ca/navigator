## MODIFIED Requirements

### Requirement: Threat create and edit flows
Navigator SHALL expose distinct create and edit flows for threat statements within a workspace. Each threat form SHALL preserve the existing STRIDE categorization input and include optional classification fields for MITRE ATT&CK tactic, kill chain phase, and assigned Deliberate Threat Level (Td1–Td7).

#### Scenario: Opening the new threat flow
- **WHEN** a user navigates to the new threat action for a workspace
- **THEN** Navigator assigns the page title "Create new threat statement"
- **AND** initializes a new threat with the current workspace identifier in the pending changes
- **AND** the form includes optional MITRE ATT&CK tactic, kill chain phase, and assigned Td level fields alongside the existing STRIDE categorization controls

#### Scenario: Opening the threat edit flow
- **WHEN** a user navigates to edit an existing threat
- **THEN** Navigator assigns the page title "Edit threat statement"
- **AND** loads the threat together with its linked assumptions and mitigations
- **AND** the form pre-populates the classification fields with the stored values

#### Scenario: Creating a new threat with classification fields
- **WHEN** a user saves a valid new threat with one or more classification fields filled in
- **THEN** Navigator creates the threat in the current workspace with the classification metadata stored
- **AND** broadcasts a workspace threat change event
- **AND** navigates to the created threat detail route with a success flash

#### Scenario: Creating a new threat without classification fields
- **WHEN** a user saves a valid new threat leaving all classification fields empty
- **THEN** Navigator creates the threat with null classification fields
- **AND** does not require classification metadata for threat creation to succeed

#### Scenario: Updating an existing threat with classification fields
- **WHEN** a user saves changes to an existing threat including updated classification fields
- **THEN** Navigator updates that threat with the new classification values
- **AND** broadcasts a workspace threat change event
- **AND** navigates to the updated threat detail route with a success flash

## ADDED Requirements

### Requirement: Threat index supports filtering by classification fields
Navigator SHALL allow threats to be filtered by the existing STRIDE categories, assigned Deliberate Threat Level, and MITRE ATT&CK tactic from the threat listing.

#### Scenario: Filtering threats by STRIDE category
- **WHEN** a user applies a STRIDE category filter from the threat index
- **THEN** Navigator reloads the threat list showing only threats tagged with the selected STRIDE category

#### Scenario: Filtering threats by assigned Td level
- **WHEN** a user applies a Deliberate Threat Level filter from the threat index
- **THEN** Navigator reloads the threat list showing only threats whose assigned `threat_level` matches the selected Td value

#### Scenario: Clearing classification filters
- **WHEN** a user clears all classification filters
- **THEN** Navigator resets the filter state and reloads the full workspace threat list

### Requirement: Threat classification fields are displayed in the threat detail view
Navigator SHALL display the threat's classification metadata with human-readable labels, showing "Not set" for any unclassified metadata fields.

#### Scenario: Viewing a classified threat
- **WHEN** a user views a threat that has classification fields set
- **THEN** Navigator displays the MITRE ATT&CK tactic, kill chain phase, and assigned Td level with their human-readable labels
- **AND** keeps the existing STRIDE categorization visible through the standard threat detail controls

#### Scenario: Viewing a threat with no classification data
- **WHEN** a user views a threat that has no classification fields set
- **THEN** Navigator displays "Not set" (or equivalent) for each unclassified field rather than leaving them blank or hidden
