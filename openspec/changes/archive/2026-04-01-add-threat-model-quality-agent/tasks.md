## 1. Spec and data model baseline

- [x] 1.1 Confirm the accepted quality-review findings scope, severity levels, and read-only behavior against the new `threat-model-quality-review` spec and the deltas to `ai-assisted-analysis` and `threat-model-reporting`.
- [x] 1.2 Add or update the persistence model for quality-review runs and structured findings, including any required migrations and schema tests.
- [x] 1.3 Add context-layer APIs for creating, listing, canceling, retrying, and loading workspace-scoped quality-review runs and findings.

## 2. Async review execution

- [x] 2.1 Implement a normalized workspace-snapshot builder that loads application information, architecture, data flow diagrams, threats, assumptions, mitigations, and any first-version evidence inputs.
- [x] 2.2 Implement the quality-review runner and runtime agent flow using the existing asynchronous AI-assisted analysis lifecycle conventions for queue, run, cancel, retry, fail, and complete states.
- [x] 2.3 Add domain tests for lifecycle transitions, stale-run recovery, cancellation handling, and snapshot assembly behavior.

## 3. Findings persistence and presentation

- [x] 3.1 Persist structured findings with category, severity, rationale, and suggested next action when a quality-review run completes.
- [x] 3.2 Extend the workspace dashboard with launch, recent history, and cancel or retry actions for quality-review runs.
- [x] 3.3 Add a workspace review surface that displays quality-review findings with grouping or filtering by severity and category.
- [x] 3.4 Add LiveView tests for launching reviews, refreshing run status, and rendering findings and empty-result states.

## 4. Prompt behavior and quality hardening

- [x] 4.1 Implement the provider prompt and result-shaping contract for the accepted high-signal finding categories.
- [x] 4.2 Ensure sparse or low-context workspaces degrade gracefully with informational or low-confidence findings rather than misleading failures.
- [x] 4.3 Add regression fixtures or tests for duplicate threats, orphaned mitigations, weak STRIDE coverage, and contradiction detection scenarios.

## 5. Verification

- [x] 5.1 Run `make fmt` and resolve formatting issues.
- [x] 5.2 Run `make test` and resolve regressions across the new domain, AI workflow, and LiveView coverage.
- [ ] 5.3 Manually verify launching a quality review, observing progress, canceling or retrying a review, and inspecting findings on a repository-imported workspace.
- [ ] 5.4 Manually verify the same review flow on a hand-authored workspace and confirm the workflow remains read-only.