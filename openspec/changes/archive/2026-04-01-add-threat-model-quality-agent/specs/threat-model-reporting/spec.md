## MODIFIED Requirements

### Requirement: Workspace dashboard reporting
Navigator SHALL provide a workspace dashboard view that loads the workspace summary, recent repository analysis history, and recent threat-model quality-review history.

#### Scenario: Opening the workspace dashboard
- **WHEN** a user opens the workspace show route
- **THEN** Navigator assigns the page title "Show Workspace"
- **AND** loads the workspace together with assumptions, threats, and mitigations
- **AND** assigns the most recent repository analysis history for that workspace
- **AND** assigns the most recent threat-model quality-review history for that workspace

#### Scenario: Refreshing dashboard data after repository analysis updates
- **WHEN** the workspace dashboard receives a repository analysis update event
- **THEN** Navigator reloads the workspace summary, recent repository analysis history, and recent threat-model quality-review history for the same workspace

#### Scenario: Refreshing dashboard data after quality-review updates
- **WHEN** the workspace dashboard receives a threat-model quality-review update event
- **THEN** Navigator reloads the workspace summary, recent repository analysis history, and recent threat-model quality-review history for the same workspace

## ADDED Requirements

### Requirement: Threat-model quality review findings view
Navigator SHALL provide a workspace review surface for inspecting threat-model quality-review findings.

#### Scenario: Opening quality-review findings
- **WHEN** a user opens a completed threat-model quality-review result from the workspace review experience
- **THEN** Navigator loads the selected review run and its findings for that workspace only
- **AND** groups or filters findings by severity or category for triage

#### Scenario: Viewing a completed review with no findings
- **WHEN** a user opens a completed threat-model quality-review result that contains no actionable findings
- **THEN** Navigator shows an explicit no-findings state instead of an empty or failed view

### Requirement: Threat-model quality review actions on the dashboard
Navigator SHALL support dashboard actions for starting, canceling, and retrying threat-model quality-review runs when those actions are allowed for the current user.

#### Scenario: Starting a quality review from the dashboard
- **WHEN** a user starts a quality review from the workspace dashboard
- **THEN** Navigator queues the review when the workspace has no active review
- **AND** refreshes the dashboard with a success indication when the request is accepted

#### Scenario: Requesting quality-review cancellation
- **WHEN** a user requests cancellation of a threat-model quality-review run they own from the workspace dashboard
- **THEN** Navigator records the cancellation request
- **AND** refreshes the workspace dashboard with a success flash when the request is accepted

#### Scenario: Retrying a quality-review run
- **WHEN** a user retries a threat-model quality-review run they own from the workspace dashboard
- **THEN** Navigator queues the retry when the run is retryable
- **AND** refreshes the workspace dashboard with a success flash when the retry is accepted