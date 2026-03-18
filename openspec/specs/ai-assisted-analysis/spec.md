# ai-assisted-analysis Specification

## Purpose
This specification defines the current baseline behavior for AI-assisted analysis in Navigator. It covers the interactive brainstorm board and the repository-analysis import workflow that generates workspace content from GitHub repositories.

## Requirements

### Requirement: Brainstorm board workspace flow
Navigator SHALL provide a workspace-scoped brainstorm board for collecting, organizing, and refining AI-assisted or manually created analysis items.

#### Scenario: Opening the brainstorm board
- **WHEN** a user opens the brainstorm route for a workspace
- **THEN** Navigator assigns the page title "Brainstorm Board"
- **AND** loads brainstorm items grouped by type for that workspace
- **AND** initializes workspace-scoped filters, undo state, and visible type ordering

### Requirement: Brainstorm item lifecycle
Navigator SHALL support creating, editing, deleting, restoring, and status-updating brainstorm items within a workspace.

#### Scenario: Creating a brainstorm item
- **WHEN** a user submits a brainstorm item with a selected type and text
- **THEN** Navigator creates the brainstorm item in the current workspace
- **AND** refreshes the brainstorm board

#### Scenario: Rejecting brainstorm creation without a type
- **WHEN** a user attempts to create a brainstorm item without selecting a type
- **THEN** Navigator does not create the item
- **AND** shows an error asking the user to select a category

#### Scenario: Updating a brainstorm item
- **WHEN** a user edits an existing brainstorm item and saves it
- **THEN** Navigator updates that item
- **AND** refreshes the brainstorm board
- **AND** clears the editing state with a success flash

#### Scenario: Deleting and restoring a brainstorm item
- **WHEN** a user deletes a brainstorm item
- **THEN** Navigator removes the item, places it in the temporary undo queue, refreshes the board, and shows an undo flash
- **AND** if the user invokes undo before the entry expires, Navigator recreates the item and refreshes the board

#### Scenario: Updating brainstorm item status
- **WHEN** a user changes the status of a brainstorm item
- **THEN** Navigator updates the item status and refreshes the board with a success flash

### Requirement: Brainstorm filtering and organization
Navigator SHALL support filtering, searching, clustering, and type-order organization for brainstorm items.

#### Scenario: Filtering or searching brainstorm items
- **WHEN** a user updates brainstorm filters or search text
- **THEN** Navigator refreshes the visible brainstorm items using the updated criteria

#### Scenario: Clearing brainstorm filters
- **WHEN** a user clears brainstorm filters
- **THEN** Navigator resets the brainstorm filter state to its defaults
- **AND** refreshes the board with the full visible item set

#### Scenario: Moving a brainstorm item between types
- **WHEN** a user moves a brainstorm item to a different type
- **THEN** Navigator updates the item's type and refreshes the board

#### Scenario: Reordering brainstorm type columns
- **WHEN** a user reorders the brainstorm type columns
- **THEN** Navigator stores the sanitized populated type order for the workspace session
- **AND** broadcasts the new type order to other connected clients

#### Scenario: Assigning a brainstorm item to a cluster
- **WHEN** a user assigns a brainstorm item to an existing or new cluster key
- **THEN** Navigator updates the item's cluster assignment, refreshes the board, and clears the cluster-assignment UI state

### Requirement: Brainstorm collaboration behavior
Navigator SHALL synchronize brainstorm updates across clients connected to the same workspace.

#### Scenario: Receiving brainstorm updates from another client
- **WHEN** the brainstorm board receives item-created, item-updated, item-deleted, or type-reordered events for the same workspace
- **THEN** Navigator refreshes the board or updates the visible type order accordingly

### Requirement: Repository-analysis import creation
Navigator SHALL support creating a workspace import request from a supported public GitHub repository URL.

#### Scenario: Creating a repository-analysis import
- **WHEN** a user starts a repository-analysis import with a valid public GitHub repository URL
- **THEN** Navigator creates a workspace and a queued repository-analysis job for that owner
- **AND** stores the GitHub URL on both the workspace and the queued job
- **AND** assigns a runtime agent identifier for the job

#### Scenario: Inferring a workspace name from the repository URL
- **WHEN** a valid repository-analysis import omits an explicit workspace name
- **THEN** Navigator derives the workspace name from the GitHub repository name

#### Scenario: Rejecting invalid repository-analysis imports
- **WHEN** the import request is missing required workspace fields, uses a non-GitHub URL, uses an incomplete GitHub URL, or points to a private or inaccessible repository
- **THEN** Navigator rejects the import with a changeset-style validation error
- **AND** does not create a workspace or analysis job

### Requirement: Repository-analysis job lifecycle
Navigator SHALL support cancelling, retrying, and recovering repository-analysis jobs.

#### Scenario: Cancelling a queued repository-analysis job
- **WHEN** the job owner cancels a queued repository-analysis job without a live runtime process
- **THEN** Navigator marks the job as cancelled
- **AND** records cancellation and completion timestamps

#### Scenario: Rejecting cancellation by another owner
- **WHEN** a user attempts to cancel a repository-analysis job they do not own
- **THEN** Navigator returns a not-found style result and leaves the job unchanged

#### Scenario: Retrying a completed or failed repository-analysis job
- **WHEN** the owner retries a rerunnable repository-analysis job and the workspace has no currently running import
- **THEN** Navigator creates a new queued repository-analysis job for the same workspace and repository URL

#### Scenario: Rejecting a retry when another import is already running
- **WHEN** a rerunnable repository-analysis job is retried while the workspace already has an active import
- **THEN** Navigator rejects the retry as already running

#### Scenario: Recovering stale repository-analysis jobs
- **WHEN** repository-analysis recovery finds stale running or queued jobs that have missed the recovery timeout
- **THEN** Navigator marks those jobs as timed out with an explanatory failure reason
- **AND** leaves already completed jobs unchanged

### Requirement: Provider-agnostic AI integration
Navigator SHALL keep AI-assisted analysis compatible with the application's configured provider abstraction rather than binding the product to a single LLM provider.

#### Scenario: Running AI-assisted analysis with configured providers
- **WHEN** a workspace uses AI-assisted analysis and a supported provider configuration is available
- **THEN** Navigator routes the request through the configured AI integration layer
- **AND** the user-facing workflow remains the same regardless of the supported provider used underneath