## ADDED Requirements

### Requirement: EvidenceComponent renders evidence details
The component SHALL display all key evidence information including name, description, evidence type, numeric ID, tags, NIST controls, and timestamps.

#### Scenario: Display evidence with all fields populated
- **WHEN** rendering evidence with name, description, tags, NIST controls, and numeric ID
- **THEN** component displays all fields correctly formatted

#### Scenario: Display evidence without optional fields
- **WHEN** rendering evidence without description, tags, or NIST controls
- **THEN** component displays only required fields (name, type) without errors

#### Scenario: Display updated timestamp
- **WHEN** evidence has been updated after creation
- **THEN** component displays both created and updated timestamps

#### Scenario: Hide updated timestamp when not modified
- **WHEN** evidence inserted_at equals updated_at
- **THEN** component displays only created timestamp

### Requirement: EvidenceComponent displays action buttons
The component SHALL display buttons for editing, deleting, and linking to related entities (assumptions, threats, mitigations).

#### Scenario: Display all action buttons
- **WHEN** rendering evidence component
- **THEN** component displays edit, delete, assumptions link, threats link, and mitigations link buttons with correct IDs

#### Scenario: Display entity counters
- **WHEN** evidence has linked assumptions, threats, or mitigations
- **THEN** component displays accurate counts for each entity type

#### Scenario: Handle zero entity counts
- **WHEN** evidence has no linked entities
- **THEN** component displays zero counters without errors

### Requirement: EvidenceComponent formats evidence types correctly
The component SHALL format evidence type enum values into human-readable labels.

#### Scenario: Format json_data type
- **WHEN** evidence type is json_data
- **THEN** component displays "JSON Data"

#### Scenario: Format blob_store_link type
- **WHEN** evidence type is blob_store_link
- **THEN** component displays "File Link"

#### Scenario: Format other evidence types
- **WHEN** evidence type is any other value
- **THEN** component displays capitalized string representation

### Requirement: EvidenceComponent formats dates consistently
The component SHALL format datetime values using consistent format across the application.

#### Scenario: Format datetime values
- **WHEN** rendering timestamps
- **THEN** component displays dates in "YYYY-MM-DD HH:MM" format

### Requirement: EvidenceComponent handles association lengths safely
The component SHALL safely compute association list lengths without errors for both loaded and unloaded associations.

#### Scenario: Count loaded associations
- **WHEN** associations are preloaded as lists
- **THEN** component returns correct count

#### Scenario: Handle unloaded associations
- **WHEN** associations are not preloaded
- **THEN** component returns zero without raising errors
