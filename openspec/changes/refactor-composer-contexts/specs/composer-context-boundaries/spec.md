## ADDED Requirements

### Requirement: Capability-focused persistence ownership
The system SHALL organize Composer persistence and query behavior into capability-focused modules under `Valentine.Composer`, with each public operation implemented by the module that owns its domain capability.

#### Scenario: Developer locates a domain operation
- **WHEN** a developer needs to change persistence or query behavior for a Composer capability
- **THEN** the implementation is located in the named capability module rather than the compatibility facade

#### Scenario: Cross-capability relationship operation
- **WHEN** an operation creates or removes an association between threats, assumptions, mitigations, or evidence
- **THEN** the association behavior is owned by the explicit relationship or evidence capability rather than duplicated across entity modules

### Requirement: Backward-compatible Composer facade
`Valentine.Composer` MUST continue to expose the public functions available before the refactor with the same names, accepted arguments, default arguments, return values, ordering, preload shapes, error tuples, and exception behavior.

#### Scenario: Existing caller invokes Composer
- **WHEN** an unchanged LiveView, controller, MCP tool, AI workflow, export, fixture, or test calls a public `Valentine.Composer` function
- **THEN** the call delegates to the owning capability and produces the same observable result as before the refactor

#### Scenario: Caller uses a bang lookup
- **WHEN** an existing caller invokes a Composer bang function for a missing or inaccessible entity
- **THEN** the same exception type and workspace-scoping behavior are preserved

### Requirement: Direct capability API
Each extracted capability module SHALL expose the operations delegated to it by the Composer facade so new code can depend on the narrow capability without depending on unrelated Composer behavior.

#### Scenario: New code invokes a capability directly
- **WHEN** new application code calls an extracted capability function with valid arguments
- **THEN** it receives the same result it would receive through the corresponding Composer facade function

### Requirement: Workspace and permission isolation
The refactor MUST preserve existing workspace scoping, ownership checks, invitation behavior, and permission-aware access for every Composer operation.

#### Scenario: Entity belongs to another workspace
- **WHEN** a workspace-scoped lookup is given an entity identifier belonging to a different workspace
- **THEN** it continues to return or raise the same not-found outcome as before the refactor

#### Scenario: User lacks workspace permission
- **WHEN** a user attempts an operation for which existing Composer permission checks deny access
- **THEN** the refactored implementation denies access with the same result as before the refactor

### Requirement: Persistence and collaboration behavior preservation
The refactor SHALL preserve schemas, database tables, changesets, transactions, association behavior, PubSub-visible effects, and caller-observable ordering and preloads.

#### Scenario: Existing write workflow succeeds
- **WHEN** an existing workflow creates, updates, links, unlinks, or deletes Composer data
- **THEN** the same records, associations, return shape, and collaboration-visible effects result without a data migration

#### Scenario: Existing validation fails
- **WHEN** an existing workflow submits attributes that violate a Composer changeset or database constraint
- **THEN** the same error tuple or exception and equivalent changeset errors are returned

### Requirement: One-way module dependencies
The extracted architecture MUST keep the compatibility facade out of capability-module dependencies and SHALL place shared query mechanics in an internal helper rather than duplicating them.

#### Scenario: Capability needs shared workspace query behavior
- **WHEN** a capability performs a standard workspace-scoped lookup or preload
- **THEN** it uses the internal shared query helper or an equivalent local domain query without calling the Composer facade

#### Scenario: Capability needs another capability
- **WHEN** a capability must invoke an operation owned by another capability
- **THEN** it calls the owning capability directly without creating a dependency back through the facade

### Requirement: Regression verification
The change MUST be verified by focused capability/facade tests and the existing complete automated test suite, with no intentional changes to product behavior.

#### Scenario: Refactor verification completes
- **WHEN** implementation is ready for handoff
- **THEN** formatting checks, focused Composer tests, and the complete test suite pass
