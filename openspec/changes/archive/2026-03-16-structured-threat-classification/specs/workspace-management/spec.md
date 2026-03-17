## MODIFIED Requirements

### Requirement: Workspace lifecycle entry points
Navigator SHALL expose separate entry points for listing, creating, editing, and importing workspaces from the workspace area. The create and edit forms SHALL include a field for selecting the workspace's maximum Deliberate Threat Level (Td1–Td7).

#### Scenario: Opening the standard new workspace flow
- **WHEN** a user navigates to the new workspace action
- **THEN** Navigator assigns the page title "New Workspace"
- **AND** initializes a blank workspace struct for the form flow
- **AND** the form includes a max Td level dropdown defaulting to unset

#### Scenario: Opening the workspace edit flow
- **WHEN** a user navigates to edit an existing workspace
- **THEN** Navigator assigns the page title "Edit Workspace"
- **AND** loads the existing workspace for editing
- **AND** the form pre-populates the max Td level dropdown with the stored value

#### Scenario: Opening supported import flows
- **WHEN** a user navigates to either the generic import flow or the GitHub import flow
- **THEN** Navigator assigns an import-specific page title for that flow
- **AND** initializes a blank workspace struct for import-driven creation

#### Scenario: Max Td level dropdown provides labeled options with descriptions
- **WHEN** a user opens the max Td level dropdown in the new or edit workspace form
- **THEN** Navigator displays each Td level with its identifier and inline description (e.g., "Td4 — Organized Criminal Group", "Td6 — Nation-State")
- **AND** includes an unset option (no Td scope declared)

#### Scenario: Saving a workspace with a max Td level
- **WHEN** a user saves a workspace form with a max Td level selected
- **THEN** Navigator persists the max Td level on the workspace record
- **AND** broadcasts the workspace update to live collaborators
- **AND** shows a success flash
