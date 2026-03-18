## ADDED Requirements

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