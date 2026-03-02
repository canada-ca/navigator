## ADDED Requirements

### Requirement: Evidence.Index handles assumptions linking action
The LiveView SHALL set up entity linker for linking evidence to assumptions when action is :assumptions.

#### Scenario: Load evidence with assumptions for linking
- **WHEN** handle_params receives :assumptions action with evidence ID
- **THEN** socket assigns evidence with preloaded assumptions, source_entity_type as :evidence, target_entity_type as :assumptions, linkable entities from workspace assumptions, and linked entities from evidence assumptions

### Requirement: Evidence.Index handles threats linking action
The LiveView SHALL set up entity linker for linking evidence to threats when action is :threats.

#### Scenario: Load evidence with threats for linking
- **WHEN** handle_params receives :threats action with evidence ID
- **THEN** socket assigns evidence with preloaded threats, source_entity_type as :evidence, target_entity_type as :threats, linkable entities from workspace threats, and linked entities from evidence threats

### Requirement: Evidence.Index handles mitigations linking action
The LiveView SHALL set up entity linker for linking evidence to mitigations when action is :mitigations.

#### Scenario: Load evidence with mitigations for linking
- **WHEN** handle_params receives :mitigations action with evidence ID
- **THEN** socket assigns evidence with preloaded mitigations, source_entity_type as :evidence, target_entity_type as :mitigations, linkable entities from workspace mitigations, and linked entities from evidence mitigations

### Requirement: Evidence.Index handles entity linker saved event
The LiveView SHALL refresh evidence list and redirect after entity linker saves changes.

#### Scenario: Handle EntityLinkerComponent saved message
- **WHEN** receiving EntityLinkerComponent saved message
- **THEN** socket refreshes evidence list and redirects to evidence index

### Requirement: Evidence.Index preloads required associations
The LiveView SHALL preload all entity types needed for linking when loading workspace.

#### Scenario: Load workspace with entity associations
- **WHEN** getting workspace for index
- **THEN** system preloads evidence, assumptions, threats, and mitigations
