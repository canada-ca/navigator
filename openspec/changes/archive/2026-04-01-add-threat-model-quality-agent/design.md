## Context

Navigator already has two strong foundations for this change. First, the repository-analysis workflow under the AI-assisted analysis capability provides a proven asynchronous pattern for queuing, running, cancelling, retrying, and reporting progress for long-running AI-backed jobs. Second, the workspace dashboard and threat-model reporting surfaces already aggregate the core records needed for a coherent review: application information, architecture, data flow diagrams, assumptions, threats, mitigations, and recent analysis history.

This change should extend those patterns instead of inventing a separate agent architecture. The new workflow does not generate a threat model from an external source; it assembles a normalized snapshot from the current workspace and asks the configured provider to assess model quality against a bounded set of review categories.

The most likely code anchors are:
- `valentine/lib/valentine/repo_analysis/agent.ex` and `valentine/lib/valentine/repo_analysis/runner.ex` as the lifecycle reference for a sibling quality-review workflow.
- `valentine/lib/valentine_web/live/workspace_live/show.ex` for launch actions, recent-run history, and progress refresh behavior.
- `valentine/lib/valentine_web/live/workspace_live/threat_model/index.ex` for loading the reviewable workspace context.
- `valentine/lib/valentine/composer/` schemas and context modules for persistence and workspace snapshot assembly.
- DataCase and LiveView tests adjacent to the existing repository-analysis and workspace-reporting coverage.

The main constraints are: preserve workspace-scoped collaboration semantics, preserve permission-aware access, keep AI integration provider-agnostic, and avoid silent mutation of human-authored workspace content.

## Goals / Non-Goals

**Goals:**
- Add a workspace-scoped quality review workflow that analyzes existing threat-model artifacts and returns structured findings.
- Reuse the current asynchronous analysis patterns for queueing, cancellation, retry, progress updates, and recent-run history.
- Build a deterministic workspace snapshot from application information, architecture, DFD, threats, assumptions, mitigations, and optionally evidence where it improves review quality.
- Keep the first version read-only, with findings that users can inspect and act on manually.
- Add focused test coverage for lifecycle handling, snapshot assembly, and findings presentation.

**Non-Goals:**
- Auto-remediation or one-click apply flows.
- Continuous repository drift monitoring.
- New workspace roles or permission tiers.
- Cross-workspace analytics or benchmark scoring.
- Export-specific formatting of review findings in the first version.

## Decisions

### Decision 1: Reuse the existing async analysis architecture

**Chosen**: Model threat-model quality reviews as a sibling asynchronous workflow to repository analysis, with its own run record, runner, status transitions, cancellation behavior, and completion summary.

**Rationale**: Navigator already has a working pattern for long-running AI-backed analysis. Reusing it reduces risk, keeps user expectations consistent, and avoids a parallel orchestration path.

**Alternatives considered**:
- Run the review synchronously from a LiveView event: rejected because larger workspaces and provider latency need progress tracking and cancellation.
- Hide the review in the chat assistant only: rejected because users need structured, replayable review history and findings.

### Decision 2: Persist findings as structured review artifacts

**Chosen**: Persist each quality-review run and its findings separately from core threat-model entities. Findings should include category, severity, rationale, and suggested next action.

**Rationale**: Users need inspectable and auditable review output. Storing findings separately preserves trust and prevents accidental mutation of manually curated records.

**Alternatives considered**:
- Directly update threats or links based on AI output: rejected because it risks overwriting human-authored content.
- Store only a free-form narrative summary: rejected because structured findings are easier to filter, test, and render.

### Decision 3: Build a normalized workspace snapshot before prompting the provider

**Chosen**: Assemble a deterministic snapshot payload from existing workspace records before invoking the AI provider.

**Rationale**: A stable AI-facing contract improves prompt quality, supports focused testing, and decouples orchestration from snapshot shaping.

**Alternatives considered**:
- Prompt directly from raw Ecto structs: rejected because it is brittle and harder to validate.
- Reuse the repository-analysis generator prompt shape: rejected because generation and critique have different objectives.

### Decision 4: Surface launch and findings in existing reporting flows

**Chosen**: Add launch and recent-run visibility to the workspace dashboard and expose detailed findings from the threat-model reporting experience or a closely related review view.

**Rationale**: Users already use those surfaces to understand workspace state. The quality review belongs in the same review loop instead of a separate tool area.

**Alternatives considered**:
- Put the workflow only in brainstorm: rejected because brainstorm is ideation-oriented rather than review-oriented.
- Put the workflow only in settings: rejected because it would bury a primary outcome-focused feature.

### Decision 5: Scope v1 to explainable, high-signal finding classes

**Chosen**: Limit the first version to duplicate threats, missing or weak STRIDE coverage, orphaned mitigations, assumptions with unclear risk impact, and contradictions across architecture, DFD, and threats.

**Rationale**: These checks are high-value, align with current data structures, and can be explained clearly to users.

**Alternatives considered**:
- Broad open-ended critique prompts: rejected because they tend to produce noisy output that is harder to trust.
- Compliance scoring in v1: rejected because it introduces policy decisions that are separate from model-quality review.

## Risks / Trade-offs

- Sparse workspaces may produce noisy findings -> Mitigation: include workspace-completeness context and allow informational or low-confidence findings instead of overstated errors.
- Larger workspaces may increase latency or token cost -> Mitigation: normalize and trim snapshots to the most relevant fields.
- Users may expect automatic fixes -> Mitigation: keep the workflow explicitly read-only in UI copy and specs.
- New persistence adds schema and UI complexity -> Mitigation: keep the run/finding model narrow and avoid broader workflow state in v1.

## Migration Plan

1. Add OpenSpec behavior for the new capability and the deltas to AI-assisted analysis and threat-model reporting.
2. Add persistence for quality-review runs and structured findings.
3. Implement snapshot assembly and the AI-backed review runner using the existing provider abstraction.
4. Extend dashboard and threat-model reporting surfaces with launch, history, and findings presentation.
5. Add domain and LiveView tests for lifecycle and rendering.
6. Run `make fmt` and `make test`, then manually validate review flows on imported and manually built workspaces.

Rollback: remove the quality-review launch and findings surfaces and disconnect the runner. If dedicated persistence is added, the rollback must also remove or ignore the review-run tables without changing existing workspace records.

## Open Questions

- Whether evidence-aware checks belong in the first version or should be deferred to a later evidence-triage workflow.
- Whether detailed findings should live directly inside the existing threat-model route or in a dedicated quality-review route linked from the dashboard.