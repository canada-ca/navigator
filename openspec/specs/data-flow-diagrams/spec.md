# data-flow-diagrams Specification

## Purpose
This specification defines the current baseline behavior for editing, saving, synchronizing, and exporting workspace data flow diagrams in Navigator. It covers the collaborative graph-editing surface that supports downstream threat work.

## Requirements

### Requirement: Workspace-scoped diagram state
Navigator SHALL load a workspace-specific data flow diagram state and subscribe connected clients to workspace-specific diagram updates.

#### Scenario: Mounting the data flow editor
- **WHEN** the data flow editor mounts for a workspace
- **THEN** Navigator loads the workspace and current data flow diagram state
- **AND** initializes saved state, selected elements, and threat helper toggles for that workspace
- **AND** subscribes connected clients to the workspace-specific data flow PubSub topic

### Requirement: Selection state management
Navigator SHALL track selected nodes and edges inside the editor state.

#### Scenario: Selecting an element
- **WHEN** a user selects a node or edge in the data flow editor
- **THEN** Navigator records that element in the selected-elements state under the correct group

#### Scenario: Unselecting an element
- **WHEN** a user unselects a previously selected node or edge
- **THEN** Navigator removes that element from the selected-elements state

### Requirement: Diagram mutations are collaborative
Navigator SHALL apply supported diagram mutation events through the data flow diagram module and broadcast resulting changes to other clients in the same workspace.

#### Scenario: Handling a generic graph mutation
- **WHEN** the editor receives a supported graph event such as a view or graph mutation
- **THEN** Navigator dispatches the event to the data flow diagram module for the current workspace
- **AND** broadcasts the resulting event and payload to the workspace data flow topic
- **AND** pushes the corresponding client update unless the event was marked local-only

#### Scenario: Receiving a remote graph mutation
- **WHEN** the editor receives a remote workspace data flow event through PubSub
- **THEN** Navigator forwards the event to the client canvas update channel
- **AND** updates the saved flag based on whether the incoming event represents a persisted save

### Requirement: Save and export persistence
Navigator SHALL support explicit diagram saving and export-related persistence from the editor.

#### Scenario: Saving a diagram
- **WHEN** a user triggers the save action in the data flow editor
- **THEN** Navigator persists the current workspace diagram state
- **AND** broadcasts a saved event for that workspace
- **AND** marks the editor state as saved

#### Scenario: Persisting exported image data
- **WHEN** the editor receives exported base64 image data from the client
- **THEN** Navigator stores that raw image against the workspace data flow diagram record

### Requirement: Undo and redo refresh the canvas state
Navigator SHALL support undo and redo for workspace diagram edits and refresh the graph state after either action.

#### Scenario: Undoing a diagram change
- **WHEN** a user triggers undo and the underlying diagram module can apply it
- **THEN** Navigator reloads the updated diagram state
- **AND** broadcasts the undo result to the workspace data flow topic
- **AND** pushes a full graph refresh to the client canvas
- **AND** marks the diagram as having unsaved changes

#### Scenario: Redoing a diagram change
- **WHEN** a user triggers redo and the underlying diagram module can apply it
- **THEN** Navigator reloads the updated diagram state
- **AND** broadcasts the redo result to the workspace data flow topic
- **AND** pushes a full graph refresh to the client canvas
- **AND** marks the diagram as having unsaved changes

### Requirement: Threat helper toggles preserve diagram state first
Navigator SHALL save the current diagram state before opening threat-statement generator or linker helpers from the data flow editor.

#### Scenario: Opening the threat statement generator
- **WHEN** a user toggles the threat statement generator from the data flow editor
- **THEN** Navigator saves the current workspace diagram state first
- **AND** toggles the generator visibility state

#### Scenario: Opening the threat statement linker
- **WHEN** a user toggles the threat statement linker from the data flow editor
- **THEN** Navigator saves the current workspace diagram state first
- **AND** toggles the linker visibility state

### Requirement: Keyboard shortcuts for history navigation
Navigator SHALL support keyboard shortcuts that map to undo and redo behavior in the data flow editor.

#### Scenario: Triggering undo and redo from the keyboard
- **WHEN** a user presses the supported keyboard shortcuts for undo or redo in the editor
- **THEN** Navigator routes those shortcuts to the same undo and redo behavior used by the explicit actions

### Requirement: Data flow editor supports previewed Mermaid import
Navigator SHALL provide a Mermaid import workflow inside the data flow editor that lets a user review import warnings before replacing the current workspace diagram.

#### Scenario: Opening Mermaid import from the editor
- **WHEN** a user opens the Mermaid import action from the data flow editor
- **THEN** Navigator displays a workspace-scoped import form for Mermaid source text
- **AND** keeps the current diagram unchanged until the user confirms a valid import

#### Scenario: Previewing a Mermaid import with an existing diagram
- **WHEN** a user validates Mermaid source for a workspace that already has nodes or edges
- **THEN** Navigator warns that confirming the import will replace the current diagram contents
- **AND** summarizes any parser warnings before the user confirms

### Requirement: Confirmed Mermaid import refreshes the collaborative canvas
Navigator SHALL apply a confirmed Mermaid import as a workspace diagram update that becomes visible to the importing user and other connected workspace clients.

#### Scenario: Confirming Mermaid import
- **WHEN** a user confirms a valid Mermaid import
- **THEN** Navigator replaces the workspace's stored diagram with the imported nodes and edges
- **AND** refreshes the editor canvas to show the imported graph
- **AND** marks the diagram state as persisted for the importing session

#### Scenario: Remote clients receive the imported diagram
- **WHEN** a Mermaid import is confirmed in a workspace with other connected clients
- **THEN** Navigator broadcasts the imported diagram update on the existing workspace data flow collaboration channel
- **AND** remote clients refresh to the imported graph without reloading the page

#### Scenario: Cancelling Mermaid import
- **WHEN** a user closes or cancels the Mermaid import flow before confirmation
- **THEN** Navigator dismisses the import state
- **AND** leaves the current workspace diagram unchanged

### Requirement: Mermaid import participates in diagram history
Navigator SHALL treat a confirmed Mermaid import as a diagram mutation that can be reversed through the existing undo behavior.

#### Scenario: Undoing a confirmed import
- **WHEN** a user triggers undo after confirming a Mermaid import
- **THEN** Navigator restores the prior workspace diagram state
- **AND** refreshes the graph using the same full-canvas update pattern as other history operations