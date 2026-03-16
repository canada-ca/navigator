# threat-management Specification

## Purpose
This specification defines the current baseline behavior for listing, filtering, creating, editing, deleting, and contextually enriching threat statements inside a Navigator workspace. It captures the current threat-management contract exposed through the workspace threat views.

## Requirements

### Requirement: Workspace threat listing and filtering
Navigator SHALL provide a workspace-scoped threat listing that supports filter updates and filter reset, including classification-aware filtering by STRIDE categories, assigned Deliberate Threat Level, and MITRE ATT&CK tactic.

#### Scenario: Loading the threat index
- **WHEN** the threat index mounts for a workspace
- **THEN** Navigator loads the workspace together with related assumptions and mitigations
- **AND** assigns the current list of threats for that workspace

#### Scenario: Updating threat filters
- **WHEN** the threat index receives a filter update message
- **THEN** Navigator stores the new filter state
- **AND** reloads the threat list using the updated filters

#### Scenario: Filtering threats by STRIDE category
- **WHEN** a user applies a STRIDE category filter from the threat index
- **THEN** Navigator reloads the threat list showing only threats tagged with the selected STRIDE category

#### Scenario: Filtering threats by assigned Td level
- **WHEN** a user applies a Deliberate Threat Level filter from the threat index
- **THEN** Navigator reloads the threat list showing only threats whose assigned `threat_level` matches the selected Td value

#### Scenario: Filtering threats by MITRE ATT&CK tactic
- **WHEN** a user applies a MITRE ATT&CK tactic filter from the threat index
- **THEN** Navigator reloads the threat list showing only threats whose stored tactic matches the selected value

#### Scenario: Clearing threat filters
- **WHEN** a user clears filters from the threat index
- **THEN** Navigator resets the filter state to an empty filter set
- **AND** reloads the full workspace threat list

### Requirement: Threat create and edit flows
Navigator SHALL expose distinct create and edit flows for threat statements within a workspace. Each threat form SHALL preserve the existing STRIDE categorization input and include optional classification fields for MITRE ATT&CK tactic, kill chain phase, and assigned Deliberate Threat Level (Td1-Td7).

#### Scenario: Opening the new threat flow
- **WHEN** a user navigates to the new threat action for a workspace
- **THEN** Navigator assigns the page title "Create new threat statement"
- **AND** initializes a new threat with the current workspace identifier in the pending changes
- **AND** the form includes optional MITRE ATT&CK tactic, kill chain phase, and assigned Td level fields alongside the existing STRIDE categorization controls

#### Scenario: Opening the threat edit flow
- **WHEN** a user navigates to edit an existing threat
- **THEN** Navigator assigns the page title "Edit threat statement"
- **AND** loads the threat together with its linked assumptions and mitigations
- **AND** pre-populates the stored classification metadata

#### Scenario: Creating a new threat with classification metadata
- **WHEN** a user saves a valid new threat with one or more classification fields filled in
- **THEN** Navigator creates the threat in the current workspace with the classification metadata stored
- **AND** broadcasts a workspace threat change event
- **AND** navigates to the created threat detail route with a success flash

#### Scenario: Creating a new threat without classification metadata
- **WHEN** a user saves a valid new threat leaving the optional classification fields empty
- **THEN** Navigator creates the threat with null classification metadata
- **AND** does not require classification data for threat creation to succeed

#### Scenario: Updating an existing threat with classification metadata
- **WHEN** a user saves changes to an existing threat including updated classification fields
- **THEN** Navigator updates that threat with the new classification values
- **AND** broadcasts a workspace threat change event
- **AND** navigates to the updated threat detail route with a success flash

### Requirement: Threat deletion updates dependent views
Navigator SHALL remove deleted threats from both the workspace threat listing and any linked data flow diagram references.

#### Scenario: Deleting an existing threat
- **WHEN** a user deletes an existing threat from the threat index
- **THEN** Navigator deletes the threat record
- **AND** removes linked threat references from the workspace data flow diagram
- **AND** refreshes the threat list with a success flash

#### Scenario: Handling delete failures
- **WHEN** threat deletion fails or the threat cannot be found
- **THEN** Navigator leaves the workspace state unchanged
- **AND** shows an error flash instead of pretending the deletion succeeded

### Requirement: Threat editing can use data flow context
Navigator SHALL derive threat form helper data from the workspace data flow diagram when the relevant fields depend on diagram content.

#### Scenario: Deriving threat sources from the diagram
- **WHEN** the threat form requests data for the threat source field
- **THEN** Navigator returns labels from actor nodes in the current workspace diagram

#### Scenario: Deriving impacted assets from the diagram
- **WHEN** the threat form requests data for impacted assets
- **THEN** Navigator returns labels from process and datastore nodes in the current workspace diagram

### Requirement: Threat flows expose related-item entry points
Navigator SHALL expose threat-specific entry points for linking or creating related assumptions and mitigations from threat-oriented views.

#### Scenario: Opening assumption-linking for a threat
- **WHEN** a user navigates to the threat assumptions action
- **THEN** Navigator assigns the page title "Link assumptions to threat"
- **AND** loads the workspace assumption candidates together with the threat's current assumption links

#### Scenario: Opening mitigation-linking for a threat
- **WHEN** a user navigates to the threat mitigations action
- **THEN** Navigator assigns the page title "Link mitigations to threat"
- **AND** loads the workspace mitigation candidates together with the threat's current mitigation links

### Requirement: Threat classification fields are displayed in the threat detail view
Navigator SHALL display the threat's classification metadata with human-readable labels, showing "Not set" for any unclassified metadata fields.

#### Scenario: Viewing a classified threat
- **WHEN** a user views a threat that has classification metadata set
- **THEN** Navigator displays the MITRE ATT&CK tactic, kill chain phase, and assigned Td level with human-readable labels
- **AND** keeps the existing STRIDE categorization visible through the standard threat detail controls

#### Scenario: Viewing a threat with no classification metadata
- **WHEN** a user views a threat that has no classification metadata set
- **THEN** Navigator displays "Not set" for each unclassified metadata field rather than leaving them blank or hidden