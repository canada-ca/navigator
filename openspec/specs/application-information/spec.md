# application-information Specification

## Purpose
This specification defines the current baseline behavior for collaboratively editing and persisting workspace application information in Navigator. It captures the rich-text editing flow that stores application context for a workspace.

## Requirements

### Requirement: Workspace application information editor
Navigator SHALL provide a workspace-scoped application information editor with a distinct route and page title.

#### Scenario: Opening the application information view
- **WHEN** a user opens the application information route for a workspace
- **THEN** Navigator assigns the page title "Application information"
- **AND** loads the workspace's current application information record or an empty application information struct

### Requirement: Collaborative rich-text cache replay
Navigator SHALL replay cached local rich-text operations when the application information editor mounts for a workspace.

#### Scenario: Rehydrating cached Quill operations
- **WHEN** the application information editor mounts and cached operations exist for the workspace
- **THEN** Navigator pushes those operations back to the client rich-text editor
- **AND** keeps the editor scoped to the current workspace cache only

### Requirement: Local edits are cached and broadcast
Navigator SHALL cache local application information changes and broadcast them to other clients connected to the same workspace.

#### Scenario: Applying a local rich-text change
- **WHEN** the editor receives a local application information change event
- **THEN** Navigator appends the operation to the workspace application information cache
- **AND** broadcasts the change on the workspace application information topic
- **AND** marks the editor as having unsaved changes

#### Scenario: Applying a remote rich-text change
- **WHEN** the editor receives a remote application information change broadcast
- **THEN** Navigator pushes the incoming operation to the client editor
- **AND** marks the editor as having unsaved changes

### Requirement: Save creates or updates workspace application information
Navigator SHALL create a new application information record when none exists and update the existing record otherwise.

#### Scenario: Saving application information
- **WHEN** a user triggers a save with application information content for a workspace
- **THEN** Navigator creates or updates the workspace application information record as needed
- **AND** flushes the workspace application information cache
- **AND** broadcasts a saved event for other connected clients
- **AND** marks the local editor as no longer touched

#### Scenario: Applying a remote save event
- **WHEN** the editor receives a remote saved event for the workspace
- **THEN** Navigator reloads the persisted application information content
- **AND** pushes a blob replacement event to the rich-text client
- **AND** marks the local editor as no longer touched