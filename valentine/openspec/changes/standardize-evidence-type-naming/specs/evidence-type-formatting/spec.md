## ADDED Requirements

### Requirement: Evidence type display standardization
The system SHALL display all evidence type options consistently as "JSON Content" and "File Link" across all user interface contexts, including form dropdowns, filter dropdowns, display cards, and validation error messages.

#### Scenario: Evidence type displayed in form dropdown
- **WHEN** user views the evidence create or edit form
- **THEN** the evidence type dropdown options SHALL display "JSON Content" and "File Link"

#### Scenario: Evidence type displayed in filter dropdown
- **WHEN** user opens the evidence type filter on the index page
- **THEN** the filter options SHALL display "JSON Content" and "File Link"

#### Scenario: Evidence type displayed in evidence card
- **WHEN** user views an evidence item in a list or detail view
- **THEN** the evidence type SHALL display as "JSON Content" or "File Link"

#### Scenario: Evidence type referenced in validation error
- **WHEN** user submits invalid evidence data with missing required fields
- **THEN** validation error messages SHALL reference "JSON Content" or "File Link" instead of raw enum values

#### Scenario: Field names in error messages use consistent terminology
- **WHEN** user submits invalid evidence data and validation error messages are displayed
- **THEN** field names in error messages SHALL use consistent terminology matching the evidence type names (e.g., "File Link must be provided..." instead of "Blob store url must be provided...")

### Requirement: Centralized evidence type formatting
The system SHALL provide a centralized EvidenceHelpers module containing helper functions for formatting evidence type enum values into user-friendly display strings.

#### Scenario: Format individual evidence type
- **WHEN** code calls `format_evidence_type(:json_data)`
- **THEN** the function SHALL return "JSON Content"

#### Scenario: Format blob store link evidence type
- **WHEN** code calls `format_evidence_type(:blob_store_link)`
- **THEN** the function SHALL return "File Link"

#### Scenario: Get all evidence type labels as map
- **WHEN** code calls `evidence_type_labels()`
- **THEN** the function SHALL return a map with all evidence type atoms as keys and their display strings as values (e.g., `%{json_data: "JSON Content", blob_store_link: "File Link"}`)

### Requirement: Evidence field name formatting
The system SHALL provide a centralized helper function for formatting evidence-related field names in error messages to maintain consistency with evidence type terminology.

#### Scenario: Format content field name
- **WHEN** code calls `format_field_name(:content)`
- **THEN** the function SHALL return "JSON Content"

#### Scenario: Format blob_store_url field name
- **WHEN** code calls `format_field_name(:blob_store_url)`
- **THEN** the function SHALL return "File Link"

#### Scenario: Format unknown field name
- **WHEN** code calls `format_field_name/1` with a field not in the explicit mapping (e.g., `:name`)
- **THEN** the function SHALL fall back to Phoenix.Naming.humanize/1 behavior (e.g., return "Name")

### Requirement: Helper module organization
The EvidenceHelpers module SHALL be located at `lib/valentine_web/live/workspace_live/evidence/components/evidence_helpers.ex` following the established pattern for domain-specific helpers (e.g., ThreatHelpers).

#### Scenario: Module is importable by evidence components
- **WHEN** an evidence-related LiveView or component imports EvidenceHelpers
- **THEN** the helper functions SHALL be available for use in that module

#### Scenario: Module follows established naming pattern
- **WHEN** developer searches for evidence-related helpers
- **THEN** the module location and naming SHALL be consistent with other domain helpers in the codebase

### Requirement: Display consistency across components
All components that display evidence types SHALL use the EvidenceHelpers module functions to ensure consistent terminology.

#### Scenario: Evidence component uses helper
- **WHEN** EvidenceComponent displays an evidence type
- **THEN** it SHALL use `format_evidence_type/1` from EvidenceHelpers

#### Scenario: Form dropdown uses helper
- **WHEN** evidence create/edit form generates dropdown options
- **THEN** it SHALL use `format_evidence_type/1` from EvidenceHelpers to format option labels

#### Scenario: Validation errors use standardized names
- **WHEN** Evidence schema validation fails and generates error messages
- **THEN** error messages SHALL reference "JSON Content" or "File Link" instead of enum values

### Requirement: Form field labels match evidence type names
The evidence create/edit form field labels SHALL match the standardized evidence type display names to create a consistent user experience.

#### Scenario: JSON content field label matches type name
- **WHEN** user selects "JSON Content" evidence type in the form
- **THEN** the conditional field label below SHALL display "JSON Content" (not "JSON content")

#### Scenario: File link field label matches type name
- **WHEN** user selects "File Link" evidence type in the form
- **THEN** the conditional field label below SHALL display "File Link" (not "Blob store URL")
