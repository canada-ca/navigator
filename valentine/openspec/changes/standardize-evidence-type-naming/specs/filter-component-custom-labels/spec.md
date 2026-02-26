## ADDED Requirements

### Requirement: Optional labels parameter
FilterComponent SHALL accept an optional `labels` parameter containing a map of values to custom display strings, allowing parent components to override the default humanization behavior.

#### Scenario: Filter component receives labels parameter
- **WHEN** FilterComponent is invoked with a `labels` parameter containing a map
- **THEN** the component SHALL use the provided labels for displaying filter options

#### Scenario: Filter component works without labels parameter
- **WHEN** FilterComponent is invoked without a `labels` parameter
- **THEN** the component SHALL use the default `humanize/1` function to format display strings

#### Scenario: Labels parameter contains mapping for filter value
- **WHEN** FilterComponent displays a value that exists in the `labels` map
- **THEN** the component SHALL display the corresponding label from the map

#### Scenario: Labels parameter missing mapping for filter value
- **WHEN** FilterComponent displays a value that does NOT exist in the `labels` map
- **THEN** the component SHALL fall back to the default `humanize/1` function for that value

### Requirement: Backward compatibility
The labels parameter enhancement SHALL be fully backward compatible with all existing uses of FilterComponent across the application.

#### Scenario: Existing filter components continue working
- **WHEN** existing FilterComponent invocations (without labels parameter) are executed
- **THEN** they SHALL continue to function exactly as before with no changes in behavior

#### Scenario: Non-evidence filters unaffected
- **WHEN** FilterComponent is used for other entity types (threats, mitigations, controls, assumptions)
- **THEN** their display behavior SHALL remain unchanged

### Requirement: Generic component integrity
FilterComponent SHALL remain a generic, reusable component with no domain-specific logic or hardcoded values.

#### Scenario: No evidence-specific code in FilterComponent
- **WHEN** reviewing FilterComponent implementation
- **THEN** there SHALL be no evidence-specific logic, references, or hardcoded values

#### Scenario: Labels work for any domain
- **WHEN** any parent component provides a labels map
- **THEN** FilterComponent SHALL use those labels regardless of the domain or entity type

### Requirement: Evidence type filter usage
The evidence index page filter SHALL use the labels parameter to display standardized evidence type names.

#### Scenario: Evidence filter displays custom labels
- **WHEN** user opens the evidence type filter on the evidence index page
- **THEN** the filter SHALL display "JSON Content" and "File Link" using labels provided by the parent

#### Scenario: Evidence filter passes labels from helper
- **WHEN** evidence index LiveView invokes FilterComponent for evidence types
- **THEN** it SHALL pass the result of `evidence_type_labels()` as the labels parameter

### Requirement: Filter functionality preservation
The labels parameter SHALL only affect display presentation and MUST NOT change the underlying filter values or filtering logic.

#### Scenario: Filter uses actual enum values for filtering
- **WHEN** user selects a filter option with a custom label
- **THEN** the FilterComponent SHALL use the actual enum value (not the display label) for filtering operations

#### Scenario: Filter value conversion remains intact
- **WHEN** FilterComponent converts string values back to atoms (via `String.to_existing_atom/1`)
- **THEN** it SHALL use the actual enum values, not the display labels
