# evidence-management Specification

## Purpose
This specification defines the current baseline behavior for listing, creating, editing, filtering, deleting, and linking evidence records in a Navigator workspace.

## Requirements

### Requirement: Evidence overview listing
Navigator SHALL provide a workspace-scoped evidence overview that displays evidence records with linked metadata and supports an empty state.

#### Scenario: Opening the evidence overview
- **WHEN** a user opens the evidence index for a workspace
- **THEN** Navigator assigns the page title "Evidence Overview"
- **AND** loads workspace evidence ordered by most recent insertion first
- **AND** preloads linked assumptions, threats, and mitigations for each evidence item

#### Scenario: Showing an empty evidence state
- **WHEN** a workspace has no evidence records
- **THEN** Navigator shows the evidence overview without any evidence entries
- **AND** presents the empty-state messaging for missing evidence

### Requirement: Evidence filtering
Navigator SHALL support evidence filtering by evidence type, tags, and NIST controls, and SHALL allow the filters to be cleared.

#### Scenario: Applying evidence filters
- **WHEN** the evidence overview receives an evidence filter update
- **THEN** Navigator reloads the workspace evidence list using the selected filters

#### Scenario: Clearing evidence filters
- **WHEN** a user clears evidence filters
- **THEN** Navigator resets the evidence filter state to an empty filter set
- **AND** reloads the full evidence list for the workspace

### Requirement: Evidence create and edit flows
Navigator SHALL expose distinct new and edit flows for evidence records.

#### Scenario: Opening the new evidence flow
- **WHEN** a user opens the new evidence route for a workspace
- **THEN** Navigator assigns the page title "New Evidence"
- **AND** initializes a new evidence form with default evidence type `description_only`
- **AND** initializes empty tag and NIST control collections

#### Scenario: Opening the edit evidence flow
- **WHEN** a user opens an existing evidence record for editing
- **THEN** Navigator assigns the page title "Edit Evidence"
- **AND** loads the existing evidence into the form state
- **AND** serializes any stored JSON content back into the editable raw content field

### Requirement: Evidence form supports typed evidence content
Navigator SHALL support description-only, blob-link, and JSON-based evidence entry patterns.

#### Scenario: Switching evidence type
- **WHEN** a user changes the selected evidence type in the evidence form
- **THEN** Navigator updates the pending evidence type in the form state

#### Scenario: Clearing the selected evidence type
- **WHEN** a user clears the currently selected evidence type
- **THEN** Navigator resets the form to `description_only`
- **AND** clears any blob URL and JSON content state

#### Scenario: Managing tags and NIST controls
- **WHEN** a user adds or removes tags or NIST controls in the evidence form
- **THEN** Navigator updates the pending list for that field
- **AND** prevents duplicate entries from being added

### Requirement: Evidence save validates structured content
Navigator SHALL validate JSON evidence content before persisting it and SHALL create or update evidence records through the evidence form.

#### Scenario: Creating new evidence
- **WHEN** a user saves valid evidence from the new evidence form
- **THEN** Navigator builds evidence attributes from the form state
- **AND** creates the evidence in the current workspace
- **AND** navigates to the created evidence route with a success flash

#### Scenario: Updating existing evidence
- **WHEN** a user saves valid changes to an existing evidence record
- **THEN** Navigator updates the evidence
- **AND** reapplies evidence linking for that record
- **AND** navigates to the updated evidence route with a success flash

#### Scenario: Rejecting invalid JSON evidence
- **WHEN** a user selects JSON evidence and provides invalid JSON content
- **THEN** Navigator does not persist the record
- **AND** exposes a validation error for the content field

### Requirement: Evidence deletion behavior
Navigator SHALL support deleting evidence from the overview with success and error feedback.

#### Scenario: Deleting evidence
- **WHEN** a user deletes an existing evidence record from the overview
- **THEN** Navigator removes the evidence
- **AND** refreshes the evidence list for the workspace
- **AND** shows a success flash

#### Scenario: Handling failed evidence deletion
- **WHEN** the evidence does not exist or deletion fails
- **THEN** Navigator keeps the current evidence list intact
- **AND** shows an error flash

### Requirement: Evidence linking entry points
Navigator SHALL expose evidence-specific linking routes for assumptions, threats, and mitigations.

#### Scenario: Opening an evidence linking route
- **WHEN** a user opens an evidence-to-assumptions, evidence-to-threats, or evidence-to-mitigations route
- **THEN** Navigator assigns the page title "Link Evidence"
- **AND** loads the relevant workspace entities as linkable candidates
- **AND** loads the evidence record's current linked entities for that target type

#### Scenario: Completing evidence linking
- **WHEN** the generic entity linker reports a successful save for evidence linking
- **THEN** Navigator refreshes the workspace evidence list
- **AND** patches the LiveView back to the workspace evidence overview