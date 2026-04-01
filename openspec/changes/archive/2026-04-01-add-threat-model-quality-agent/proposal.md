## Why

Navigator can already generate a first-pass threat model from a repository, capture manual threat-model artifacts, and aggregate the workspace into a reporting view, but it cannot evaluate the quality of the resulting model. Teams can create or import threats, assumptions, mitigations, and diagrams, yet they still have to manually inspect completeness, consistency, and linkage quality before they can trust the workspace as review-ready.

## What Changes

- Add a workspace-scoped threat model quality review workflow that analyzes the current workspace and returns structured findings instead of generating a new threat model.
- Surface high-value findings for duplicate or near-duplicate threats, weak or missing STRIDE coverage, mitigations that are not linked to threats, assumptions with unclear risk impact, and contradictions across architecture, data flow diagrams, and threat records.
- Reuse the existing asynchronous AI-assisted analysis pattern so quality reviews can be queued, cancelled, retried, and tracked with progress updates and recent-run history.
- Present review results as structured, inspectable findings with category, severity, rationale, and suggested next action, without automatically mutating workspace content.
- Add a launch point and findings presentation to the existing workspace review experience so teams can rerun reviews after major modeling changes.

## Capabilities

### New Capabilities
- `threat-model-quality-review`: Run a workspace-scoped quality review over existing threat-model artifacts and return structured findings for human triage.

### Modified Capabilities
- `ai-assisted-analysis`: Add a second AI-assisted workflow that reviews existing workspace content rather than generating an initial model from a repository.
- `threat-model-reporting`: Add quality-review launch, history, and findings presentation to the workspace review experience.

## Impact

- Affected code will likely include the AI-provider integration, repository-analysis orchestration pattern, workspace dashboard and threat-model LiveViews, and Composer-level workspace aggregation paths.
- New persistence will likely be needed for quality-review runs and their structured findings.
- Existing threat, assumption, mitigation, DFD, collaboration, and export flows remain supported; the first version is diagnostic and read-only.

### Non-Goals

- Automatically editing threats, mitigations, assumptions, or diagrams based on findings.
- Continuous repository drift monitoring.
- Quantitative risk scoring or prioritization formulas.
- Cross-workspace quality analytics.
- Broader reviewer workflow changes beyond viewing and rerunning reviews.

### Rollout / Compatibility

- Existing workspaces remain compatible and can opt into quality reviews without data migration of current threat-model records.
- If a dedicated persistence model is introduced for review runs, existing workspaces simply start with no historical review data.