## ADDED Requirements

### Requirement: Threat-model quality review creation
Navigator SHALL support creating a workspace quality-review request from existing workspace threat-model content.

#### Scenario: Creating a threat-model quality review
- **WHEN** a user starts a quality review for a workspace with sufficient access
- **THEN** Navigator creates a queued quality-review job for that workspace owner or initiating user context
- **AND** associates the run with the current workspace instead of a repository URL

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

## MODIFIED Requirements

### Requirement: Provider-agnostic AI integration
Navigator SHALL keep AI-assisted analysis compatible with the application's configured provider abstraction rather than binding the product to a single LLM provider.

#### Scenario: Running AI-assisted analysis with configured providers
- **WHEN** a workspace uses AI-assisted analysis and a supported provider configuration is available
- **THEN** Navigator routes repository-analysis and threat-model quality-review requests through the configured AI integration layer
- **AND** the user-facing workflow remains the same regardless of the supported provider used underneath