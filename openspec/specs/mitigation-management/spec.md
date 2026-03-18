# mitigation-management Specification

## Purpose
This specification defines the current baseline behavior for listing, filtering, creating, editing, categorizing, and deleting mitigations within a Navigator workspace.

## Requirements

### Requirement: Workspace mitigation listing
Navigator SHALL provide a workspace-scoped mitigation listing ordered by the current numeric identifier sort used by the application.

#### Scenario: Loading the mitigation index
- **WHEN** the mitigation index mounts for a workspace
- **THEN** Navigator loads the workspace with mitigations and relationship candidates
- **AND** assigns the mitigations in descending numeric identifier order

### Requirement: Mitigation create and edit flows
Navigator SHALL expose separate create and edit entry points for mitigations in a workspace.

#### Scenario: Opening the new mitigation flow
- **WHEN** a user navigates to the new mitigation action
- **THEN** Navigator assigns the page title "New Mitigation"
- **AND** initializes a new mitigation with the current workspace identifier

#### Scenario: Opening the mitigation edit flow
- **WHEN** a user navigates to edit an existing mitigation
- **THEN** Navigator assigns the page title "Edit Mitigation"
- **AND** loads the existing mitigation for editing

### Requirement: Mitigation relationship and categorization entry points
Navigator SHALL expose mitigation-specific entry points for categorization and for linking assumptions and threats.

#### Scenario: Opening mitigation categorization
- **WHEN** a user navigates to the categorize action for a mitigation
- **THEN** Navigator assigns the page title "Categorize Mitigation"
- **AND** loads the mitigation together with its current threat associations

#### Scenario: Opening assumption-linking for a mitigation
- **WHEN** a user navigates to the mitigation assumptions action
- **THEN** Navigator assigns the page title "Link assumptions to mitigation"
- **AND** loads workspace assumption candidates together with the mitigation's current assumption links

#### Scenario: Opening threat-linking for a mitigation
- **WHEN** a user navigates to the mitigation threats action
- **THEN** Navigator assigns the page title "Link threats to mitigation"
- **AND** loads workspace threat candidates together with the mitigation's current threat links

### Requirement: Mitigation filtering and refresh
Navigator SHALL refresh the workspace mitigation listing when filters change, filters are cleared, saved messages arrive, or workspace broadcasts are received.

#### Scenario: Updating mitigation filters
- **WHEN** the mitigation index receives a filter update message
- **THEN** Navigator stores the updated filters
- **AND** reloads mitigations for the workspace using the filtered query

#### Scenario: Clearing mitigation filters
- **WHEN** a user clears mitigation filters
- **THEN** Navigator resets the filter state to an empty filter set
- **AND** reloads the unfiltered mitigation list for the workspace

#### Scenario: Refreshing mitigations after save or workspace broadcast
- **WHEN** the mitigation index receives either a saved mitigation message or a workspace broadcast
- **THEN** Navigator reloads the workspace data
- **AND** reassigns the sorted workspace mitigations

### Requirement: Mitigation deletion behavior
Navigator SHALL support deleting a mitigation from the workspace list with success and error feedback.

#### Scenario: Deleting an existing mitigation
- **WHEN** a user deletes an existing mitigation
- **THEN** Navigator removes the mitigation
- **AND** refreshes the sorted workspace mitigation list
- **AND** shows a success flash

#### Scenario: Handling failed mitigation deletion
- **WHEN** the mitigation does not exist or deletion fails
- **THEN** Navigator keeps the current state intact
- **AND** shows an error flash