## ADDED Requirements

### Requirement: Reader AI interactions cannot alter workspace state
Navigator SHALL permit readers to inspect existing AI-assisted analysis and use non-mutating, user-private assistant interactions, but SHALL require current write access before AI-assisted output changes shared workspace content or creates a persisted workspace analysis job.

#### Scenario: Reader inspects existing analysis
- **WHEN** a reader opens brainstorm content, repository-analysis status, quality-review status, or completed quality-review findings
- **THEN** Navigator presents the existing workspace-scoped information in read-only form

#### Scenario: Reader uses a non-mutating personal assistant interaction
- **WHEN** a reader asks the assistant a question that only reads accessible workspace context and stores no shared workspace result
- **THEN** Navigator may return the assistant response in the reader's private interaction state
- **AND** does not insert the response into shared editors or workspace records

#### Scenario: Reader attempts to persist AI-assisted output
- **WHEN** a reader invokes an assistant action that would insert content, create or update an entity, import references, generate threats, or create a persisted analysis run
- **THEN** Navigator rejects the operation before changing persistent records, shared drafts, or job state

## MODIFIED Requirements

### Requirement: Brainstorm item lifecycle
Navigator SHALL allow owners and writers to create, edit, delete, restore, and status-update brainstorm items within a workspace, while readers can inspect the existing items only.

#### Scenario: Creating a brainstorm item with write access
- **WHEN** an owner or writer submits a brainstorm item with a selected type and text
- **THEN** Navigator creates the brainstorm item in the current workspace
- **AND** refreshes the brainstorm board

#### Scenario: Rejecting brainstorm creation without a type
- **WHEN** an owner or writer attempts to create a brainstorm item without selecting a type
- **THEN** Navigator does not create the item
- **AND** shows an error asking the user to select a category

#### Scenario: Updating a brainstorm item with write access
- **WHEN** an owner or writer edits an existing brainstorm item and saves it
- **THEN** Navigator updates that item
- **AND** refreshes the brainstorm board
- **AND** clears the editing state with a success flash

#### Scenario: Deleting and restoring a brainstorm item with write access
- **WHEN** an owner or writer deletes a brainstorm item
- **THEN** Navigator removes the item, places it in the temporary undo queue, refreshes the board, and shows an undo flash
- **AND** if that user invokes undo before the entry expires while retaining write access, Navigator recreates the item and refreshes the board

#### Scenario: Updating brainstorm item status with write access
- **WHEN** an owner or writer changes the status of a brainstorm item
- **THEN** Navigator updates the item status and refreshes the board with a success flash

#### Scenario: Rejecting a brainstorm mutation by a reader
- **WHEN** a reader submits a create, update, delete, restore, or status-change event for a brainstorm item
- **THEN** Navigator rejects the event
- **AND** leaves the brainstorm item set unchanged

### Requirement: Brainstorm filtering and organization
Navigator SHALL allow all workspace readers to filter and search brainstorm items, while requiring write access for clustering, moving items, and shared type-order changes.

#### Scenario: Filtering or searching brainstorm items
- **WHEN** an owner, writer, or reader updates brainstorm filters or search text
- **THEN** Navigator refreshes the visible brainstorm items using the updated criteria
- **AND** does not change persisted brainstorm content

#### Scenario: Clearing brainstorm filters
- **WHEN** an owner, writer, or reader clears brainstorm filters
- **THEN** Navigator resets the filter state to its defaults
- **AND** refreshes the board with the full visible item set

#### Scenario: Moving a brainstorm item between types with write access
- **WHEN** an owner or writer moves a brainstorm item to a different type
- **THEN** Navigator updates the item's type and refreshes the board

#### Scenario: Reordering brainstorm type columns with write access
- **WHEN** an owner or writer reorders the brainstorm type columns
- **THEN** Navigator stores the sanitized populated type order for the workspace session
- **AND** broadcasts the new type order to other connected clients

#### Scenario: Assigning a brainstorm item to a cluster with write access
- **WHEN** an owner or writer assigns a brainstorm item to an existing or new cluster key
- **THEN** Navigator updates the item's cluster assignment, refreshes the board, and clears the cluster-assignment UI state

#### Scenario: Rejecting reader organization changes
- **WHEN** a reader attempts to move, reorder, cluster, or generate threats from brainstorm items
- **THEN** Navigator rejects the operation
- **AND** leaves persisted and shared brainstorm state unchanged

### Requirement: Threat-model quality review creation
Navigator SHALL require current write access to create a workspace quality-review request from existing workspace threat-model content.

#### Scenario: Creating a threat-model quality review with write access
- **WHEN** an owner or writer starts a quality review for an accessible workspace
- **THEN** Navigator creates a queued quality-review job for that workspace and initiating user context
- **AND** associates the run with the current workspace instead of a repository URL

#### Scenario: Rejecting quality-review creation by a reader
- **WHEN** a reader attempts to start a threat-model quality review
- **THEN** Navigator rejects the request
- **AND** does not create or launch a quality-review run
