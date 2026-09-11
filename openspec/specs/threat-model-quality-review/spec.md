# threat-model-quality-review Specification

## Purpose
This specification defines the workspace-scoped threat-model quality review workflow in Navigator. It captures how a quality review evaluates existing workspace artifacts, persists structured findings, and keeps the review flow read-only.
## Requirements
### Requirement: Workspace quality review creation
Navigator SHALL provide a workspace-scoped threat-model quality review workflow that requires current write access, analyzes existing workspace artifacts, and creates a review run without mutating the workspace threat model.

#### Scenario: Starting a quality review with write access
- **WHEN** an owner or writer starts a threat-model quality review for an accessible workspace
- **THEN** Navigator creates a queued quality-review run for that workspace
- **AND** keeps the review scoped to the current workspace only
- **AND** does not create, edit, or delete threats, assumptions, mitigations, or diagram records as part of starting the review

#### Scenario: Rejecting quality-review creation by a reader
- **WHEN** a reader attempts to start a threat-model quality review
- **THEN** Navigator rejects the request
- **AND** does not create or launch a run

#### Scenario: Rejecting a duplicate active review
- **WHEN** an owner or writer starts a quality review while that workspace already has an active quality-review run
- **THEN** Navigator rejects the request as already running
- **AND** leaves the existing active review unchanged

### Requirement: Workspace quality review lifecycle
Navigator SHALL support running, cancelling, retrying, deleting, and completing threat-model quality reviews with progress reporting, while requiring current lifecycle authority for user-initiated changes.

#### Scenario: Running a quality review
- **WHEN** an authorized queued quality-review run starts
- **THEN** Navigator updates the run through meaningful progress states while it assembles workspace context, evaluates the threat model, and persists findings

#### Scenario: Cancelling a quality review as the initiating writer
- **WHEN** the initiating user retains write access and cancels their active quality-review run
- **THEN** Navigator marks the run as cancelled
- **AND** records the relevant cancellation and completion timestamps

#### Scenario: Managing a quality review as the workspace owner
- **WHEN** the current workspace owner cancels or deletes a quality-review run belonging to that workspace
- **THEN** Navigator applies the requested supported lifecycle action
- **AND** leaves runs from other workspaces unchanged

#### Scenario: Retrying a quality review with lifecycle authority
- **WHEN** the workspace owner or the initiating user with current write access retries a rerunnable quality-review run
- **AND** the workspace has no currently running quality review
- **THEN** Navigator creates a new queued quality-review run for that workspace

#### Scenario: Rejecting lifecycle changes after a writer is downgraded
- **WHEN** an initiating writer has been downgraded to `read` and attempts to retry, cancel, or delete their quality-review run
- **THEN** Navigator rejects the operation
- **AND** leaves the run unchanged

### Requirement: Structured quality review findings
Navigator SHALL persist quality-review results as structured findings that users can inspect and triage.

#### Scenario: Completing a quality review with findings
- **WHEN** a quality-review run completes successfully
- **THEN** Navigator stores structured findings for that run
- **AND** each finding includes a category, severity, rationale, and suggested next action

#### Scenario: Completing a quality review with no actionable findings
- **WHEN** a quality-review run completes and the review does not identify actionable issues
- **THEN** Navigator records the run as completed
- **AND** stores an empty findings set or an equivalent explicit no-findings result

### Requirement: Read-only review behavior
Navigator SHALL keep the first version of threat-model quality review diagnostic and read-only.

#### Scenario: Viewing a quality-review finding
- **WHEN** a user inspects findings from a completed quality-review run
- **THEN** Navigator presents the findings as recommendations only
- **AND** requires separate user actions outside the review workflow to edit workspace content

#### Scenario: Evaluating the current workspace snapshot
- **WHEN** Navigator assembles data for a threat-model quality review
- **THEN** it uses the current workspace application information, architecture, data flow diagram, threats, assumptions, mitigations, and configured first-version evidence inputs as review context
- **AND** it does not persist snapshot assembly as user-visible edits to those workspace records

### Requirement: Quality-review results remain readable without lifecycle authority
Navigator SHALL allow readers to inspect workspace quality-review status and findings without granting authority to create, retry, cancel, or delete review runs.

#### Scenario: Reader views a quality-review run
- **WHEN** a reader opens the workspace quality-review index or a workspace-scoped review result
- **THEN** Navigator displays the run status and available findings
- **AND** omits lifecycle controls

#### Scenario: Reader forges a quality-review lifecycle event
- **WHEN** a reader submits a start, retry, cancel, or delete event for a workspace quality-review run
- **THEN** Navigator rejects the event
- **AND** leaves the run and workspace unchanged
