# threat-agent-classification Specification

## Purpose
This specification defines the current baseline behavior for workspace-scoped Threat Agents in Navigator, including listing, create/edit flows, deletion, and their use as a reference when assigning Deliberate Threat Levels to threats.

## Requirements

### Requirement: Workspace-scoped Threat Agent catalogue
Navigator SHALL provide a workspace-scoped catalogue of Threat Agents, where each agent captures a class, capability level, motivation, and a mapped Deliberate Threat Level (Td1-Td7).

#### Scenario: Listing threat agents for a workspace
- **WHEN** a user navigates to the Threat Agents section of a workspace
- **THEN** Navigator displays all threat agents associated with that workspace
- **AND** each entry shows the agent name, class, capability, motivation, and Td level

#### Scenario: Workspace with no threat agents
- **WHEN** a workspace has no threat agents defined
- **THEN** Navigator displays an empty state with an invitation to add the first agent

### Requirement: Threat Agent create and edit flows
Navigator SHALL expose distinct create and edit flows for Threat Agents within a workspace.

#### Scenario: Creating a new Threat Agent
- **WHEN** a user submits a valid new Threat Agent form for a workspace
- **THEN** Navigator creates the Threat Agent in the workspace
- **AND** broadcasts a workspace update event
- **AND** navigates to the Threat Agent listing with a success flash

#### Scenario: Editing an existing Threat Agent
- **WHEN** a user submits changes to an existing Threat Agent
- **THEN** Navigator updates the Threat Agent record
- **AND** broadcasts a workspace update event
- **AND** navigates to the listing with a success flash

#### Scenario: Threat Agent form requires a name
- **WHEN** a user submits a Threat Agent form without a name
- **THEN** Navigator rejects the submission
- **AND** displays a validation error on the name field

### Requirement: Threat Agent deletion
Navigator SHALL allow deletion of a Threat Agent from the workspace catalogue.

#### Scenario: Deleting a Threat Agent
- **WHEN** a user deletes a Threat Agent from the listing
- **THEN** Navigator removes that Threat Agent from the workspace
- **AND** refreshes the listing with a success flash

#### Scenario: Deleting a workspace removes its Threat Agents
- **WHEN** a workspace is deleted
- **THEN** Navigator also removes all Threat Agents associated with that workspace

### Requirement: Threat Agent Td level drives Td dropdown in threats
Navigator SHALL allow a threat to reference the workspace's Threat Agent catalogue when assigning a Deliberate Threat Level to that threat.

#### Scenario: Threat form displays defined Td levels for selection
- **WHEN** a user opens the threat create or edit form
- **THEN** Navigator presents the Td1-Td7 levels as selectable options for the threat's assigned Td level field
- **AND** may surface the workspace's catalogued Threat Agents as reference for the Td assignment