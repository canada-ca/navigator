## ADDED Requirements

### Requirement: Evidence create UI
The system SHALL provide a full-page evidence creation view within a workspace.

#### Scenario: Open new evidence page
- **WHEN** a user navigates to the evidence creation route for a workspace
- **THEN** the system displays a full-page form to create evidence

### Requirement: Evidence edit UI
The system SHALL provide a full-page evidence editing view for an existing evidence record.

#### Scenario: Open edit evidence page
- **WHEN** a user navigates to an evidence edit route
- **THEN** the system displays a full-page form pre-filled with the evidence details

### Requirement: Evidence type inputs
The system SHALL conditionally display evidence inputs based on the evidence type.

#### Scenario: JSON data evidence
- **WHEN** the user selects an evidence type of JSON data
- **THEN** the system displays an input for JSON content and hides the file link input

#### Scenario: File link evidence
- **WHEN** the user selects an evidence type of file link
- **THEN** the system displays an input for a blob store URL and hides the JSON content input

### Requirement: NIST control tagging and auto-linking
The system SHALL accept NIST controls via tag-style input and SHALL auto-link evidence to assumptions, threats, and mitigations by NIST controls on save.

#### Scenario: Create with NIST controls
- **WHEN** the user saves new evidence with NIST controls
- **THEN** the system persists the controls and auto-links evidence to matching entities by NIST controls

#### Scenario: Edit with updated NIST controls
- **WHEN** the user updates NIST controls and saves an existing evidence record
- **THEN** the system re-runs NIST auto-linking using the updated controls

### Requirement: Validation feedback
The system SHALL surface validation errors for required evidence fields in the create and edit views.

#### Scenario: Missing required fields
- **WHEN** a user attempts to save evidence without required fields
- **THEN** the system displays validation errors on the form
