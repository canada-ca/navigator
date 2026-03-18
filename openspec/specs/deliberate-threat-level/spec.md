# deliberate-threat-level Specification

## Purpose
This specification defines the current baseline behavior for Deliberate Threat Levels (Td1-Td7) in Navigator, including the canonical taxonomy and workspace-level defensive scope.

## Requirements

### Requirement: Deliberate Threat Level taxonomy is defined and available system-wide
Navigator SHALL define the Deliberate Threat Level (Td) taxonomy as a canonical ordered list of seven levels (Td1-Td7), each with a machine-readable identifier and a human-readable label, available to all workspace and threat classification flows.

#### Scenario: Taxonomy provides ordered Td values with labels
- **WHEN** any part of the system requests the list of valid Td levels
- **THEN** Navigator returns exactly seven levels in ascending order: Td1 ("Script Kiddie"), Td2 ("Low-Sophistication Insider"), Td3 ("Opportunistic External / Contractor Insider"), Td4 ("Organized Criminal Group"), Td5 ("Sophisticated Threat Actor"), Td6 ("Nation-State"), Td7 ("Peer Nation-State")

### Requirement: Workspace scopes its threat model to a maximum Deliberate Threat Level
Navigator SHALL allow a workspace owner to declare the highest Deliberate Threat Level (Td1-Td7) the organization realistically defends against.

#### Scenario: Setting max Td level on workspace creation
- **WHEN** a user creates a new workspace and selects a maximum Td level from the dropdown
- **THEN** Navigator persists the selected Td level against the workspace
- **AND** confirms the setting with a success flash

#### Scenario: Updating max Td level on workspace edit
- **WHEN** a workspace owner edits an existing workspace and changes the max Td level
- **THEN** Navigator updates the workspace record with the new value
- **AND** broadcasts the workspace update to all live collaborators

#### Scenario: Workspace with no max Td level set
- **WHEN** a workspace is created or exists without a max Td level selection
- **THEN** Navigator treats the max Td level as unset (null)
- **AND** does not restrict threat entry or display based on Td level