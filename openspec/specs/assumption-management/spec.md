# assumption-management Specification

## Purpose
This specification defines the current baseline behavior for listing, filtering, creating, editing, deleting, and preparing assumptions for relationship workflows inside a Navigator workspace.

## Requirements

### Requirement: Workspace assumption listing
Navigator SHALL provide a workspace-scoped assumption listing ordered by the current numeric identifier sort used by the application.

#### Scenario: Loading the assumption index
- **WHEN** the assumption index mounts for a workspace
- **THEN** Navigator loads the workspace with assumptions and relationship candidates
- **AND** assigns the assumptions in descending numeric identifier order

### Requirement: Assumption create and edit flows
Navigator SHALL expose separate create and edit entry points for assumptions in a workspace.

#### Scenario: Opening the new assumption flow
- **WHEN** a user navigates to the new assumption action
- **THEN** Navigator assigns the page title "New Assumption"
- **AND** initializes a new assumption with the current workspace identifier

#### Scenario: Opening the assumption edit flow
- **WHEN** a user navigates to edit an existing assumption
- **THEN** Navigator assigns the page title "Edit Assumption"
- **AND** loads the existing assumption for editing

### Requirement: Assumption filtering and refresh
Navigator SHALL refresh the workspace assumption listing when filters change, filters are cleared, saved messages arrive, or workspace broadcasts are received.

#### Scenario: Updating assumption filters
- **WHEN** the assumption index receives a filter update message
- **THEN** Navigator stores the updated filters
- **AND** reloads the assumptions using the filtered workspace query

#### Scenario: Clearing assumption filters
- **WHEN** a user clears assumption filters
- **THEN** Navigator resets the filter state to an empty filter set
- **AND** reloads the unfiltered assumption list for the workspace

#### Scenario: Refreshing assumptions after save or workspace broadcast
- **WHEN** the assumption index receives either a saved assumption message or a workspace broadcast
- **THEN** Navigator reloads the workspace data
- **AND** reassigns the sorted workspace assumptions

### Requirement: Assumption relationship entry points
Navigator SHALL expose assumption-specific entry points for linking mitigations and threats.

#### Scenario: Opening mitigation-linking for an assumption
- **WHEN** a user navigates to the assumption mitigations action
- **THEN** Navigator assigns the page title "Link mitigations to assumption"
- **AND** loads workspace mitigation candidates together with the assumption's current mitigation links

#### Scenario: Opening threat-linking for an assumption
- **WHEN** a user navigates to the assumption threats action
- **THEN** Navigator assigns the page title "Link threats to assumption"
- **AND** loads workspace threat candidates together with the assumption's current threat links

### Requirement: Assumption deletion behavior
Navigator SHALL support deleting an assumption from the workspace list with success and error feedback.

#### Scenario: Deleting an existing assumption
- **WHEN** a user deletes an existing assumption
- **THEN** Navigator removes the assumption
- **AND** refreshes the sorted workspace assumption list
- **AND** shows a success flash

#### Scenario: Handling failed assumption deletion
- **WHEN** the assumption does not exist or deletion fails
- **THEN** Navigator keeps the current state intact
- **AND** shows an error flash