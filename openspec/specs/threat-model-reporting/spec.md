# threat-model-reporting Specification

## Purpose
This specification defines the current baseline behavior for workspace reporting surfaces in Navigator, including the workspace dashboard, threat model summary view, and security requirements traceability matrix. It captures how current workspace data is aggregated and presented for review.

## Requirements

### Requirement: Threat model summary view
Navigator SHALL provide a threat model view that aggregates the core workspace analysis records into a single reporting-oriented view.

#### Scenario: Opening the threat model view
- **WHEN** a user opens the workspace threat model route
- **THEN** Navigator loads the workspace with application information, architecture, data flow diagram, assumptions, threats, and mitigations
- **AND** assigns the page title "Threat model"
- **AND** keeps the view scoped to that workspace only

### Requirement: Workspace dashboard reporting
Navigator SHALL provide a workspace dashboard view that loads the workspace summary and recent repository analysis history.

#### Scenario: Opening the workspace dashboard
- **WHEN** a user opens the workspace show route
- **THEN** Navigator assigns the page title "Show Workspace"
- **AND** loads the workspace together with assumptions, threats, and mitigations
- **AND** assigns the most recent repository analysis history for that workspace

#### Scenario: Refreshing dashboard data after repository analysis updates
- **WHEN** the workspace dashboard receives a repository analysis update event
- **THEN** Navigator reloads the workspace summary and recent repository analysis history for the same workspace

### Requirement: Repository analysis actions on the dashboard
Navigator SHALL support dashboard actions for canceling and retrying repository analysis jobs when those actions are allowed for the current user.

#### Scenario: Requesting repository analysis cancellation
- **WHEN** a user requests cancellation of a repository analysis job they own from the workspace dashboard
- **THEN** Navigator records the cancellation request
- **AND** refreshes the workspace dashboard with a success flash when the request is accepted

#### Scenario: Retrying a repository analysis job
- **WHEN** a user retries a repository analysis job they own from the workspace dashboard
- **THEN** Navigator queues the retry when the job is retryable
- **AND** refreshes the workspace dashboard with a success flash when the retry is accepted

### Requirement: Security requirements traceability matrix
Navigator SHALL provide an SRTM view that classifies controls as not allocated, out of scope, or in scope using the workspace's assumptions, mitigations, threats, and configured cloud profile filters.

#### Scenario: Loading the SRTM view
- **WHEN** a user opens the SRTM route for a workspace
- **THEN** Navigator initializes default filters from the workspace cloud profile and type
- **AND** loads matching controls
- **AND** classifies tagged assumptions into out-of-scope controls
- **AND** classifies tagged mitigations and threats into in-scope controls
- **AND** leaves untagged or unmatched controls as not allocated

#### Scenario: Clearing SRTM filters
- **WHEN** a user clears filters in the SRTM view
- **THEN** Navigator resets the active filters to an empty filter set
- **AND** recalculates the control allocation view
- **AND** resets the evidence filter to show all controls

#### Scenario: Updating SRTM main filters
- **WHEN** the SRTM view receives a filter update message
- **THEN** Navigator reloads the filtered controls and recalculates the control allocation view
- **AND** resets the evidence filter to show all controls

### Requirement: SRTM evidence filtering
Navigator SHALL allow users to narrow the in-scope control view by evidence coverage state.

#### Scenario: Selecting an evidence filter
- **WHEN** a user selects an evidence filter such as all, has evidence, or needs evidence
- **THEN** Navigator updates the evidence filter state to the corresponding safe value

#### Scenario: Handling an invalid evidence filter input
- **WHEN** the SRTM view receives an invalid evidence filter value
- **THEN** Navigator falls back to the all-controls evidence filter instead of failing