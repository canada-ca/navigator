# reference-packs Specification

## Purpose
This specification defines the current baseline behavior for listing, importing, reviewing, and applying reference packs in Navigator. It covers the reusable collection flows that seed workspaces with shared modeling content.

## Requirements

### Requirement: Reference pack listing
Navigator SHALL provide a workspace-scoped listing of available reference pack collections.

#### Scenario: Opening the reference pack index
- **WHEN** a user opens the reference pack index for a workspace
- **THEN** Navigator assigns the page title "Reference packs"
- **AND** loads the grouped reference pack collections returned by the reference pack listing query

#### Scenario: Opening the reference pack import route
- **WHEN** a user opens the reference pack import route for a workspace
- **THEN** Navigator assigns the page title "Import reference pack"
- **AND** keeps the workspace context available for the import flow

### Requirement: Reference pack collection deletion
Navigator SHALL support deleting a reference pack collection from the reference pack index.

#### Scenario: Deleting a reference pack collection
- **WHEN** a user deletes a reference pack collection from the index
- **THEN** Navigator removes that collection
- **AND** refreshes the reference pack listing
- **AND** shows a success flash

### Requirement: Reference pack detail review
Navigator SHALL provide a detail view for a selected reference pack collection.

#### Scenario: Opening a reference pack detail view
- **WHEN** a user opens a specific reference pack collection for a workspace
- **THEN** Navigator assigns the page title "Reference pack"
- **AND** loads the items belonging to the selected collection
- **AND** initializes the selected-reference list as empty

### Requirement: Applying selected reference items to a workspace
Navigator SHALL allow users to select one or more reference pack items from a collection and add them to the current workspace.

#### Scenario: Updating the selected reference set
- **WHEN** the reference pack detail view receives a selected-items message
- **THEN** Navigator stores the selected reference item identifiers in the detail view state

#### Scenario: Adding selected reference items to a workspace
- **WHEN** a user saves selected reference items from the reference pack detail view
- **THEN** Navigator attempts to add each selected reference item to the current workspace
- **AND** counts the successfully added items
- **AND** shows a flash summarizing how many reference items were added
- **AND** navigates back to the workspace reference pack index

### Requirement: Reference-pack import strips unsupported linked fields
Navigator SHALL import reference-pack items into workspaces using only the fields appropriate to the target entity type.

#### Scenario: Importing an assumption reference item
- **WHEN** Navigator imports an assumption reference-pack item into a workspace
- **THEN** it copies the assumption data into the target workspace
- **AND** omits linked threat and mitigation fields from the imported assumption payload

#### Scenario: Importing a threat reference item
- **WHEN** Navigator imports a threat reference-pack item into a workspace
- **THEN** it copies the threat data into the target workspace
- **AND** omits linked assumptions, linked mitigations, and workflow-only priority or status fields from the imported threat payload

#### Scenario: Importing a mitigation reference item
- **WHEN** Navigator imports a mitigation reference-pack item into a workspace
- **THEN** it copies the mitigation data into the target workspace
- **AND** omits linked assumptions, linked threats, and workflow-only status fields from the imported mitigation payload