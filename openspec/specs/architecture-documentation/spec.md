# architecture-documentation Specification

## Purpose
This specification defines the current baseline behavior for collaboratively editing and persisting workspace architecture documentation in Navigator. It covers the rich-text architecture narrative that complements diagram-based modeling.

## Requirements

### Requirement: Workspace architecture editor
Navigator SHALL provide a workspace-scoped architecture editor with a distinct route and page title.

#### Scenario: Opening the architecture view
- **WHEN** a user opens the architecture route for a workspace
- **THEN** Navigator assigns the page title "Architecture"
- **AND** loads the workspace's current architecture record or an empty architecture struct

### Requirement: Collaborative architecture cache replay
Navigator SHALL replay cached local rich-text operations when the architecture editor mounts for a workspace.

#### Scenario: Rehydrating cached architecture operations
- **WHEN** the architecture editor mounts and cached operations exist for the workspace
- **THEN** Navigator pushes those operations back to the client rich-text editor
- **AND** keeps the editor scoped to the current workspace cache only

### Requirement: Local architecture edits are cached and broadcast
Navigator SHALL cache local architecture changes and broadcast them to other clients connected to the same workspace.

#### Scenario: Applying a local architecture change
- **WHEN** the editor receives a local architecture change event
- **THEN** Navigator appends the operation to the workspace architecture cache
- **AND** broadcasts the change on the workspace architecture topic
- **AND** marks the editor as having unsaved changes

#### Scenario: Applying a remote architecture change
- **WHEN** the editor receives a remote architecture change broadcast
- **THEN** Navigator pushes the incoming operation to the client editor
- **AND** marks the editor as having unsaved changes

### Requirement: Save creates or updates workspace architecture
Navigator SHALL create a new architecture record when none exists and update the existing record otherwise.

#### Scenario: Saving architecture content
- **WHEN** a user triggers a save with architecture content for a workspace
- **THEN** Navigator creates or updates the workspace architecture record as needed
- **AND** flushes the workspace architecture cache
- **AND** broadcasts a saved event for other connected clients
- **AND** marks the local editor as no longer touched

#### Scenario: Applying a remote architecture save event
- **WHEN** the editor receives a remote saved event for the workspace architecture
- **THEN** Navigator reloads the persisted architecture content
- **AND** pushes a blob replacement event to the rich-text client
- **AND** marks the local editor as no longer touched