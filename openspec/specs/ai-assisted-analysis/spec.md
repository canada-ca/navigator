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

### Requirement: Threat-model quality review job lifecycle
Navigator SHALL support cancelling, retrying, and recovering threat-model quality review jobs.

#### Scenario: Cancelling a queued quality-review job
- **WHEN** the review owner cancels a queued quality-review job without a live runtime process
- **THEN** Navigator marks the job as cancelled
- **AND** records cancellation and completion timestamps

#### Scenario: Retrying a completed or failed quality-review job
- **WHEN** the owner retries a rerunnable quality-review job and the workspace has no currently running quality review
- **THEN** Navigator creates a new queued quality-review job for the same workspace

#### Scenario: Recovering stale quality-review jobs
- **WHEN** quality-review recovery finds stale running or queued jobs that have missed the recovery timeout
- **THEN** Navigator marks those jobs as timed out with an explanatory failure reason
- **AND** leaves already completed jobs unchanged

### Requirement: Provider-agnostic AI integration
Navigator SHALL route all AI-assisted analysis through the configured AI gateway using its OpenAI-compatible API rather than authenticating directly to upstream model providers.

#### Scenario: Running AI-assisted analysis through a gateway
- **WHEN** a workspace uses AI-assisted analysis and the AI gateway URL, gateway key, and model alias are configured
- **THEN** Navigator routes repository-analysis and threat-model quality-review requests to that gateway
- **AND** authenticates with the gateway key
- **AND** sends the configured model alias while leaving upstream-provider selection to the gateway
- **AND** the user-facing workflow remains unchanged regardless of the upstream provider selected by the gateway

#### Scenario: Using the default gateway model alias
- **WHEN** the AI gateway URL and key are configured without an explicit model alias
- **THEN** Navigator sends `openai-gpt-5.6-luna` as the model alias

#### Scenario: Rejecting incomplete gateway configuration
- **WHEN** an AI-assisted workflow is invoked without a configured AI gateway URL or gateway key
- **THEN** Navigator fails the request with a gateway-configuration error before contacting an LLM endpoint
- **AND** does not fall back to direct OpenAI or Azure OpenAI credentials

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
