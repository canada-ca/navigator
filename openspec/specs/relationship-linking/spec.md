# relationship-linking Specification

## Purpose
This specification defines the current baseline behavior for linking threats, assumptions, mitigations, and evidence within a Navigator workspace. It captures the shared linking model used across entity-specific views and the generic linking component.

## Requirements

### Requirement: Entity-specific linking routes
Navigator SHALL expose relationship-management routes from the originating entity views instead of requiring a single global linker page.

#### Scenario: Opening relationship routes from entity views
- **WHEN** a user opens a linking route from an assumption, mitigation, threat, or evidence view
- **THEN** Navigator loads the source entity with its current relationships for the requested target type
- **AND** loads only workspace-scoped candidate entities for that target type
- **AND** assigns an action-specific page title or linking context for that route

### Requirement: Generic relationship linker behavior
Navigator SHALL provide a shared linker component that manages the add and remove state for linked entities before save.

#### Scenario: Selecting an entity to link
- **WHEN** the shared linker component receives a selected item from its dropdown
- **THEN** Navigator moves that entity from the linkable set into the linked set in the component state

#### Scenario: Removing a linked entity before save
- **WHEN** a user removes an already selected linked entity in the linker component
- **THEN** Navigator removes it from the pending linked set
- **AND** returns it to the linkable candidate set

### Requirement: Shared save semantics for supported relationship pairs
Navigator SHALL apply relationship additions and removals using the pair-specific Composer functions for each supported source and target combination.

#### Scenario: Saving relationship changes
- **WHEN** a user saves relationship changes from the generic linker component
- **THEN** Navigator computes which relationships must be added and which must be removed compared with the current persisted relationships
- **AND** applies the correct add and remove operations for the current source-target pair
- **AND** sends a saved message back to the parent LiveView
- **AND** pushes the user back to the source view patch with a success flash

#### Scenario: Supported relationship combinations
- **WHEN** the source and target entity types are one of the supported combinations across assumptions, threats, mitigations, and evidence
- **THEN** Navigator uses the matching Composer add and remove functions for that pair
- **AND** does not reuse an unrelated pair's linking behavior

#### Scenario: Persisted relationship updates refresh the source entity associations
- **WHEN** a pair-specific add or remove operation succeeds in the Composer layer
- **THEN** Navigator reloads the relevant association set for the source entity before returning the updated entity state

### Requirement: Evidence auto-linking precedence
Navigator SHALL apply direct evidence-linking identifiers before any control-based evidence-linking strategy.

#### Scenario: Direct evidence linking takes precedence
- **WHEN** evidence is created with direct target identifiers such as an assumption, threat, or mitigation identifier
- **THEN** Navigator applies those direct links first
- **AND** does not prefer control-based linking over the explicit identifiers

#### Scenario: Direct evidence links stay within the same workspace
- **WHEN** Navigator attempts to link evidence directly to another entity by identifier
- **THEN** it only creates that relationship if the target entity belongs to the same workspace as the evidence

### Requirement: Inline relationship changes in threat editing
Navigator SHALL support adding and removing linked assumptions and mitigations directly from the threat detail workflow in addition to the generic linker routes.

#### Scenario: Removing a linked assumption or mitigation from a threat
- **WHEN** a user removes an assumption or mitigation from the threat detail view
- **THEN** Navigator updates the threat relationships immediately
- **AND** reassigns the updated threat in the same view

#### Scenario: Adding related items to a threat from nested flows
- **WHEN** a nested save or selection message provides an assumption or mitigation while editing a threat
- **THEN** Navigator adds the selected related item to the current threat
- **AND** reassigns the updated threat in the same view