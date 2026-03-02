## ADDED Requirements

### Requirement: Support description-only evidence type

The system SHALL support a `:description_only` evidence type that allows users to create evidence without file attachments or external links.

#### Scenario: Creating new description-only evidence
- **WHEN** user creates new evidence without selecting an attachment type
- **THEN** evidence is saved with `evidence_type: :description_only`

#### Scenario: Description-only evidence validation
- **WHEN** evidence has `evidence_type: :description_only`
- **THEN** validation SHALL pass without `blob_store_link` or `json_data` fields
- **AND** `description` field MUST be present

#### Scenario: Existing evidence types remain valid
- **WHEN** evidence has `evidence_type: :blob_store_link` or `:json_data`
- **THEN** validation SHALL continue to work as before
- **AND** existing evidence records SHALL remain unchanged

### Requirement: Description-only is default for new evidence

New evidence SHALL default to `evidence_type: :description_only` instead of `:blob_store_link`.

#### Scenario: New evidence form initialization
- **WHEN** user navigates to create new evidence
- **THEN** form SHALL initialize with `evidence_type: :description_only`
- **AND** attachment section SHALL show options to add attachments

#### Scenario: Default persists when only description provided
- **WHEN** user submits evidence with only name and description
- **THEN** evidence SHALL be saved with `evidence_type: :description_only`
- **AND** no validation errors SHALL occur

### Requirement: Evidence type enum includes description-only

The Evidence schema's `evidence_type` Ecto.Enum SHALL include `:description_only` as a valid value.

#### Scenario: Ecto enum serialization
- **WHEN** evidence is saved with `evidence_type: :description_only`
- **THEN** database SHALL store "description_only" as string
- **AND** schema SHALL deserialize back to `:description_only` atom

#### Scenario: Enum values list includes all types
- **WHEN** querying available evidence types
- **THEN** list SHALL include `:description_only`, `:blob_store_link`, and `:json_data`

### Requirement: Description-only helper label

Evidence helpers SHALL provide a human-readable label for `:description_only` type.

#### Scenario: Label retrieval for description-only
- **WHEN** requesting label for `evidence_type: :description_only`
- **THEN** helper SHALL return "Description Only"

### Requirement: Validation enforces type-specific content

Evidence validation SHALL ensure that `:description_only` evidence does not have attachment fields populated.

#### Scenario: Description-only with attachment fields fails validation
- **WHEN** evidence has `evidence_type: :description_only`
- **AND** `blob_store_link` or `json_data` is present
- **THEN** validation SHALL fail with appropriate error message

#### Scenario: Description-only with only description passes validation
- **WHEN** evidence has `evidence_type: :description_only`
- **AND** only `description` field is populated
- **THEN** validation SHALL pass

### Requirement: Description is required for all evidence types

All evidence records SHALL require a `description` field, regardless of `evidence_type`.

#### Scenario: Evidence without description fails validation
- **WHEN** submitting evidence without description
- **THEN** validation SHALL fail with "description is required" error
- **AND** evidence SHALL NOT be saved

#### Scenario: Evidence with description passes validation
- **WHEN** submitting evidence with description
- **THEN** validation SHALL pass for any evidence type
