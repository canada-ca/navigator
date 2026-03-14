# threat-management Specification

## Purpose
This specification defines the current baseline behavior for listing, filtering, creating, editing, deleting, and contextually enriching threat statements inside a Navigator workspace. It captures the current threat-management contract exposed through the workspace threat views.

## Requirements

### Requirement: Workspace threat listing and filtering
Navigator SHALL provide a workspace-scoped threat listing that supports filter updates and filter reset.

#### Scenario: Loading the threat index
- **WHEN** the threat index mounts for a workspace
- **THEN** Navigator loads the workspace together with related assumptions and mitigations
- **AND** assigns the current list of threats for that workspace

#### Scenario: Updating threat filters
- **WHEN** the threat index receives a filter update message
- **THEN** Navigator stores the new filter state
- **AND** reloads the threat list using the updated filters

#### Scenario: Clearing threat filters
- **WHEN** a user clears filters from the threat index
- **THEN** Navigator resets the filter state to an empty filter set
- **AND** reloads the full workspace threat list

### Requirement: Threat create and edit flows
Navigator SHALL expose distinct create and edit flows for threat statements within a workspace.

#### Scenario: Opening the new threat flow
- **WHEN** a user navigates to the new threat action for a workspace
- **THEN** Navigator assigns the page title "Create new threat statement"
- **AND** initializes a new threat with the current workspace identifier in the pending changes

#### Scenario: Opening the threat edit flow
- **WHEN** a user navigates to edit an existing threat
- **THEN** Navigator assigns the page title "Edit threat statement"
- **AND** loads the threat together with its linked assumptions and mitigations

#### Scenario: Creating a new threat
- **WHEN** a user saves a valid new threat
- **THEN** Navigator creates the threat in the current workspace
- **AND** broadcasts a workspace threat change event
- **AND** navigates to the created threat detail route with a success flash

#### Scenario: Updating an existing threat
- **WHEN** a user saves changes to an existing threat
- **THEN** Navigator updates that threat
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