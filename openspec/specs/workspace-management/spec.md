# workspace-management Specification

## Purpose
This specification defines the current baseline behavior for listing, creating, editing, importing, and deleting Navigator workspaces. It captures the workspace lifecycle behavior exposed in the workspace index and related entry points.

## Requirements

### Requirement: Identity-scoped workspace listing
Navigator SHALL show each user only the workspaces that are accessible to their identity rather than an unfiltered global list.

#### Scenario: Loading the workspace index
- **WHEN** the workspace index LiveView mounts for the current user
- **THEN** Navigator loads workspaces through the identity-aware workspace query
- **AND** the resulting list is assigned to the workspace index state

### Requirement: Workspace lifecycle entry points
Navigator SHALL expose separate entry points for listing, creating, editing, and importing workspaces from the workspace area.

#### Scenario: Opening the standard new workspace flow
- **WHEN** a user navigates to the new workspace action
- **THEN** Navigator assigns the page title "New Workspace"
- **AND** initializes a blank workspace struct for the form flow

#### Scenario: Opening the workspace edit flow
- **WHEN** a user navigates to edit an existing workspace
- **THEN** Navigator assigns the page title "Edit Workspace"
- **AND** loads the existing workspace for editing

#### Scenario: Opening supported import flows
- **WHEN** a user navigates to either the generic import flow or the GitHub import flow
- **THEN** Navigator assigns an import-specific page title for that flow
- **AND** initializes a blank workspace struct for import-driven creation

### Requirement: Owner-only workspace deletion
Navigator SHALL allow workspace deletion only for the workspace owner.

#### Scenario: Deleting a workspace as the owner
- **WHEN** the workspace owner requests deletion from the workspace index
- **THEN** Navigator deletes the workspace
- **AND** shows a success flash message
- **AND** refreshes the visible workspace list for the current user

#### Scenario: Rejecting deletion by a non-owner
- **WHEN** a non-owner requests deletion of a workspace
- **THEN** Navigator does not delete the workspace
- **AND** shows an error indicating the user is not the owner

### Requirement: Workspace list refresh after save flows
Navigator SHALL refresh the workspace listing after workspace creation or import flows report a successful save.

#### Scenario: Refreshing after a workspace form save
- **WHEN** the workspace index receives a saved message from the standard workspace form component
- **THEN** Navigator reloads the current user's accessible workspaces
- **AND** updates the workspace list shown in the index

#### Scenario: Refreshing after a GitHub import save
- **WHEN** the workspace index receives a saved message from the GitHub import component
- **THEN** Navigator reloads the current user's accessible workspaces
- **AND** updates the workspace list shown in the index