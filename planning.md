# GitHub Repo Threat Model Agent Plan

## Branch

- Current branch: `feat/jido_agent`

## Current Status

The repo-import threat-model flow is no longer just a speculative vertical slice. It has been compiled, exercised in a working Elixir environment, and debugged through several real runtime failures.

Current end-to-end behavior:

1. A user can open Workspaces and start `Import from GitHub`.
2. Submitting a valid public GitHub URL creates a workspace and a persisted repo-analysis job.
3. A Jido-backed runtime launches the repo-analysis task.
4. The runner clones the repository with conservative limits, selects and prioritizes relevant files, and builds a repo snapshot.
5. The generator requests structured threat-model output from the existing LLM stack.
6. The persister writes application information, architecture, DFD, threats, assumptions, and mitigations into the existing workspace tables.
7. Generated assumptions and mitigations are linked to generated threats.
8. Re-running an import for the same generated content updates generated records instead of endlessly duplicating them.
9. Users can monitor job progress globally in `My Agents` and see workspace-local import status on the workspace show page.
10. Users can retry failed imports or rerun completed imports from both `My Agents` and the workspace overview.
11. Repository import summaries are collapsible, start collapsed by default, and expose compact status/navigation affordances.
12. Stale jobs can be recovered by a supervised recovery worker.

## What Was Implemented

### Durable repo-analysis jobs

- Added a persisted job model for GitHub repo analysis in [valentine/lib/valentine/composer/repo_analysis_agent.ex](valentine/lib/valentine/composer/repo_analysis_agent.ex).
- Added migration [valentine/priv/repo/migrations/20260311110000_create_repo_analysis_agents.exs](valentine/priv/repo/migrations/20260311110000_create_repo_analysis_agents.exs).
- Added Composer context functions for create/list/get/update/cancel in [valentine/lib/valentine/composer.ex](valentine/lib/valentine/composer.ex).
- Linked jobs to workspaces in [valentine/lib/valentine/composer/workspace.ex](valentine/lib/valentine/composer/workspace.ex).

### Jido runtime foundation and fixes

- Added `{:jido, "~> 2.0"}` in [valentine/mix.exs](valentine/mix.exs).
- Added Jido instance module in [valentine/lib/valentine/jido.ex](valentine/lib/valentine/jido.ex).
- Added `Valentine.Jido` and `Task.Supervisor` to supervision tree in [valentine/lib/valentine/application.ex](valentine/lib/valentine/application.ex).
- Added repo-analysis runtime config in [valentine/config/config.exs](valentine/config/config.exs).
- Fixed an invalid guard usage in [valentine/lib/valentine/repo_analysis/agent.ex](valentine/lib/valentine/repo_analysis/agent.ex) where `Process.alive?/1` had been used in a guard.
- Reworked [valentine/lib/valentine/repo_analysis/agent.ex](valentine/lib/valentine/repo_analysis/agent.ex) to use explicit Jido `signal_routes` and nested actions instead of dead `handle_signal/2` callbacks.
- Added a runtime start toggle in [valentine/lib/valentine/repo_analysis.ex](valentine/lib/valentine/repo_analysis.ex) so tests can exercise API behavior without spawning background runtime tasks under SQL sandbox.

### Repo analysis execution pipeline

- Added service entry point in [valentine/lib/valentine/repo_analysis.ex](valentine/lib/valentine/repo_analysis.ex).
- Added Jido agent wrapper in [valentine/lib/valentine/repo_analysis/agent.ex](valentine/lib/valentine/repo_analysis/agent.ex).
- Added runner orchestration in [valentine/lib/valentine/repo_analysis/runner.ex](valentine/lib/valentine/repo_analysis/runner.ex).
- Added conservative public GitHub clone/index logic in [valentine/lib/valentine/repo_analysis/github.ex](valentine/lib/valentine/repo_analysis/github.ex).
- Added LLM-based structured generation in [valentine/lib/valentine/repo_analysis/generator.ex](valentine/lib/valentine/repo_analysis/generator.ex).
- Added persistence of generated application information, architecture, DFD, threats, assumptions, and mitigations in [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex).
- Added early GitHub URL validation in [valentine/lib/valentine/repo_analysis.ex](valentine/lib/valentine/repo_analysis.ex) using parsing helpers from [valentine/lib/valentine/repo_analysis/github.ex](valentine/lib/valentine/repo_analysis/github.ex), so obviously invalid imports fail fast before a workspace/job is created.
- Fixed the repo clone timeout path in [valentine/lib/valentine/repo_analysis/github.ex](valentine/lib/valentine/repo_analysis/github.ex) by replacing invalid `System.cmd/3` `timeout:` usage with a task-based timeout wrapper.
- Fixed post-persistence completion handling in [valentine/lib/valentine/repo_analysis/runner.ex](valentine/lib/valentine/repo_analysis/runner.ex) so DFD summary generation reads string-keyed maps correctly.

### Persistence quality and linking

- Implemented idempotent generated-record persistence in [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex) for threats, assumptions, and mitigations.
- Added stale generated record cleanup on rerun in [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex).
- Added `related_threat_indexes` support to the structured generation contract in [valentine/lib/valentine/repo_analysis/generator.ex](valentine/lib/valentine/repo_analysis/generator.ex).
- Wired generated assumptions to generated threats and generated mitigations to generated threats in [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex).
- Preserved non-generated tags when updating generated records on rerun in [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex).

### DFD generation and layout improvements

- Fixed the initial generated DFD collapse bug in [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex).
- Normalized generated DFD component kinds in [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex) so `external_entity` persists as `actor` and `data_store` persists as `datastore`, matching the editor.
- Replaced the old fixed node position (`50,50` for every node) with a deterministic layout pass that:
  - spaces trust boundaries on a grid
  - spaces trust boundaries using the largest generated boundary footprint
  - places components inside boundaries by flow depth and component lane
  - places root-level components separately from boundary-contained components
- Added type-specific lanes so generated actors, processes, and data stores are stacked more predictably.
- Added layout-focused assertions in [valentine/test/valentine/repo_analysis/persister_test.exs](valentine/test/valentine/repo_analysis/persister_test.exs) so generated nodes must receive distinct, non-default positions.

### Recovery and stuck-job handling

- Added stale-job recovery logic in [valentine/lib/valentine/repo_analysis.ex](valentine/lib/valentine/repo_analysis.ex).
- Added a supervised recovery worker in [valentine/lib/valentine/repo_analysis/recovery.ex](valentine/lib/valentine/repo_analysis/recovery.ex).
- Wired the recovery worker into the supervision tree in [valentine/lib/valentine/application.ex](valentine/lib/valentine/application.ex).
- Added runtime/recovery config in [valentine/config/config.exs](valentine/config/config.exs) and disabled recovery in tests via [valentine/config/test.exs](valentine/config/test.exs).
- Added leftover clone-dir cleanup in recovery/cancellation paths in [valentine/lib/valentine/repo_analysis.ex](valentine/lib/valentine/repo_analysis.ex).

### UI entry points and monitoring

- Added global `My Agents` route and GitHub import route in [valentine/lib/valentine_web/router.ex](valentine/lib/valentine_web/router.ex).
- Added workspace-index action handling in [valentine/lib/valentine_web/live/workspace_live/index.ex](valentine/lib/valentine_web/live/workspace_live/index.ex).
- Added `My Agents` and `Import from GitHub` actions in [valentine/lib/valentine_web/live/workspace_live/index.html.heex](valentine/lib/valentine_web/live/workspace_live/index.html.heex).
- Added GitHub import modal/component in [valentine/lib/valentine_web/live/workspace_live/github_import_component.ex](valentine/lib/valentine_web/live/workspace_live/github_import_component.ex).
- Fixed the import form crash in [valentine/lib/valentine_web/live/workspace_live/github_import_component.ex](valentine/lib/valentine_web/live/workspace_live/github_import_component.ex) by switching from a raw map-backed form to a changeset-backed form.
- Added global job monitor LiveView in [valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex](valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex).
- Added workspace-local repo-analysis status and cancel visibility in [valentine/lib/valentine_web/live/workspace_live/show.ex](valentine/lib/valentine_web/live/workspace_live/show.ex) and [valentine/lib/valentine_web/live/workspace_live/show.html.heex](valentine/lib/valentine_web/live/workspace_live/show.html.heex).
- Added retry/rerun actions to `My Agents` and the workspace overview in [valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex](valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex) and [valentine/lib/valentine_web/live/workspace_live/show.ex](valentine/lib/valentine_web/live/workspace_live/show.ex).
- Added richer timestamps, recent import history, relative time rendering, and summary metadata to the repo-analysis views in [valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex](valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex) and [valentine/lib/valentine_web/live/workspace_live/show.html.heex](valentine/lib/valentine_web/live/workspace_live/show.html.heex).
- Added collapsible import/job cards, compact summary links, and state-style status pills to the repo-analysis UI in [valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex](valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex), [valentine/lib/valentine_web/live/workspace_live/show.html.heex](valentine/lib/valentine_web/live/workspace_live/show.html.heex), and [valentine/assets/css/app.css](valentine/assets/css/app.css).

### Prompt and repo selection improvements

- Expanded file selection heuristics in [valentine/lib/valentine/repo_analysis/github.ex](valentine/lib/valentine/repo_analysis/github.ex) to prioritize infrastructure, deployment, CI, and repo metadata files.
- Added `stack_hints` and `priority_paths` to the repo snapshot metadata in [valentine/lib/valentine/repo_analysis/github.ex](valentine/lib/valentine/repo_analysis/github.ex).
- Refined [valentine/lib/valentine/repo_analysis/generator.ex](valentine/lib/valentine/repo_analysis/generator.ex) so prompts are more repo-aware and ask for more conservative DFD sizing and better use of infrastructure/auth context.

### Tests added or expanded

- Added fixture support in [valentine/test/support/fixtures/composer_fixtures.ex](valentine/test/support/fixtures/composer_fixtures.ex).
- Added Composer coverage in [valentine/test/valentine/composer_test.exs](valentine/test/valentine/composer_test.exs).
- Added workspace index LiveView coverage in [valentine/test/valentine_web/live/workspace/index_view_test.exs](valentine/test/valentine_web/live/workspace/index_view_test.exs).
- Added My Agents LiveView coverage in [valentine/test/valentine_web/live/repo_analysis_agent/index_view_test.exs](valentine/test/valentine_web/live/repo_analysis_agent/index_view_test.exs).
- Added repo-analysis API coverage in [valentine/test/valentine/repo_analysis_test.exs](valentine/test/valentine/repo_analysis_test.exs) for:
  - `create_import/2`
  - `cancel_for_owner/2`
  - invalid GitHub URLs
  - stale-job recovery behavior
  - runner failure behavior
- Added persistence and rerun coverage in [valentine/test/valentine/repo_analysis/persister_test.exs](valentine/test/valentine/repo_analysis/persister_test.exs).
- Added workspace show page coverage in [valentine/test/valentine_web/live/workspace/show_view_test.exs](valentine/test/valentine_web/live/workspace/show_view_test.exs).

## Validation Performed

This work has been validated in a working Elixir environment. The earlier limitation that `mix` was unavailable is no longer true.

Focused repo-analysis and related tests were run successfully during the implementation work, including:

```bash
cd /workspace/valentine
mix deps.get
mix test test/valentine/repo_analysis_test.exs test/valentine/repo_analysis/persister_test.exs
mix test test/valentine/repo_analysis_test.exs test/valentine/repo_analysis/persister_test.exs test/valentine_web/live/workspace/show_view_test.exs test/valentine_web/live/workspace/index_view_test.exs test/valentine_web/live/repo_analysis_agent/index_view_test.exs test/valentine/composer_test.exs
mix test test/valentine/repo_analysis/persister_test.exs
mix test test/valentine_web/live/repo_analysis_agent/index_view_test.exs test/valentine_web/live/workspace/show_view_test.exs
```

The focused repo-analysis layout/persistence run ended green after the actor/datastore normalization and lane-based DFD layout changes.

## Known Limitations

- The import flow is still public-GitHub-only. There is no private repo auth, GitHub App integration, or support for non-GitHub providers.
- Cancellation is cooperative between major phases. A currently executing external call or LLM request is not forcibly interrupted mid-request.
- DFD layout is materially better than the original fixed-position output and now uses explicit actor/process/datastore lanes, but it is still heuristic rather than editor-quality graph layout.
- Prompt quality is improved, but generated architecture prose and DFD semantics will still vary by repository quality and model behavior.
- Manual browser validation of the full UX should still be done after major follow-up changes.

## Logical Next Steps

### 1. Tighten DFD layout heuristics with real repos

The deterministic layout solved the overlap/collapse bug, but the next useful refinement is to make diagrams more opinionated and readable on real repositories.

Good follow-ups:

- refine actor/process/datastore lanes against a few denser real-repo imports
- improve boundary sizing/placement when a boundary contains many nodes or long multi-stage flows
- use flow direction more aggressively to reduce crossing edges
- add a few representative fixture cases for denser generated DFDs

Main files:

- [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex)
- [valentine/test/valentine/repo_analysis/persister_test.exs](valentine/test/valentine/repo_analysis/persister_test.exs)

### 2. Improve private-repo and provider support strategy

If this feature is meant to be broadly useful, public GitHub-only is the next major product limitation.

Possible scope options:

- personal access token support for private GitHub repositories
- GitHub App based integration
- support for GitLab or generic git URLs later

This will likely require changes in:

- [valentine/lib/valentine/repo_analysis/github.ex](valentine/lib/valentine/repo_analysis/github.ex)
- [valentine/lib/valentine_web/live/workspace_live/github_import_component.ex](valentine/lib/valentine_web/live/workspace_live/github_import_component.ex)
- config/runtime handling for credentials

### 3. Broaden automated coverage around runner and recovery paths

The focused coverage is solid, but the most brittle code still lives around long-running runtime behavior.

Best next tests:

- additional recovery edge cases
- clone timeout and cleanup behavior
- repeated rerun behavior on existing workspaces
- more complex DFD layout cases
- UI tests for collapsible import summaries and compact status affordances

### 4. Do manual UX validation on the happy path

Before treating the feature as finished, walk through the app manually with one or two real repositories:

1. create a repo import from the workspace index
2. observe progress in both `My Agents` and the workspace show page
3. verify generated architecture/application information content quality
4. inspect the generated DFD visually for readability
5. inspect generated threats, assumptions, and mitigations for reasonable linking

### 5. Profile and optimize performance hot paths

Once the product-visible follow-ups above are in a good place, the next engineering pass can focus on performance.

Likely targets:

- large repo clone/index cost in [valentine/lib/valentine/repo_analysis/github.ex](valentine/lib/valentine/repo_analysis/github.ex)
- persistence/query overhead in [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex)
- LiveView rendering density in [valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex](valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex) and [valentine/lib/valentine_web/live/workspace_live/show.html.heex](valentine/lib/valentine_web/live/workspace_live/show.html.heex)

## Safe Starting Point For The Next AI Window

If a later context window needs to continue this work, a good first task is:

1. run the focused repo-analysis test suite again
2. inspect one real generated DFD in the UI
3. improve the layout heuristics in [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex)
4. if the layout looks acceptable, move on to private-repo support or performance profiling

## Files Added

- [valentine/lib/valentine/composer/repo_analysis_agent.ex](valentine/lib/valentine/composer/repo_analysis_agent.ex)
- [valentine/lib/valentine/jido.ex](valentine/lib/valentine/jido.ex)
- [valentine/lib/valentine/repo_analysis.ex](valentine/lib/valentine/repo_analysis.ex)
- [valentine/lib/valentine/repo_analysis/agent.ex](valentine/lib/valentine/repo_analysis/agent.ex)
- [valentine/lib/valentine/repo_analysis/github.ex](valentine/lib/valentine/repo_analysis/github.ex)
- [valentine/lib/valentine/repo_analysis/generator.ex](valentine/lib/valentine/repo_analysis/generator.ex)
- [valentine/lib/valentine/repo_analysis/persister.ex](valentine/lib/valentine/repo_analysis/persister.ex)
- [valentine/lib/valentine/repo_analysis/recovery.ex](valentine/lib/valentine/repo_analysis/recovery.ex)
- [valentine/lib/valentine/repo_analysis/runner.ex](valentine/lib/valentine/repo_analysis/runner.ex)
- [valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex](valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex)
- [valentine/lib/valentine_web/live/workspace_live/github_import_component.ex](valentine/lib/valentine_web/live/workspace_live/github_import_component.ex)
- [valentine/priv/repo/migrations/20260311110000_create_repo_analysis_agents.exs](valentine/priv/repo/migrations/20260311110000_create_repo_analysis_agents.exs)
- [valentine/test/valentine/repo_analysis_test.exs](valentine/test/valentine/repo_analysis_test.exs)
- [valentine/test/valentine/repo_analysis/persister_test.exs](valentine/test/valentine/repo_analysis/persister_test.exs)
- [valentine/test/valentine_web/live/repo_analysis_agent/index_view_test.exs](valentine/test/valentine_web/live/repo_analysis_agent/index_view_test.exs)
- [valentine/test/valentine_web/live/workspace/show_view_test.exs](valentine/test/valentine_web/live/workspace/show_view_test.exs)

## Files Modified

- [valentine/config/config.exs](valentine/config/config.exs)
- [valentine/config/test.exs](valentine/config/test.exs)
- [valentine/lib/valentine/application.ex](valentine/lib/valentine/application.ex)
- [valentine/lib/valentine/composer.ex](valentine/lib/valentine/composer.ex)
- [valentine/lib/valentine/composer/workspace.ex](valentine/lib/valentine/composer/workspace.ex)
- [valentine/lib/valentine_web/live/workspace_live/index.ex](valentine/lib/valentine_web/live/workspace_live/index.ex)
- [valentine/lib/valentine_web/live/workspace_live/index.html.heex](valentine/lib/valentine_web/live/workspace_live/index.html.heex)
- [valentine/lib/valentine_web/live/workspace_live/show.ex](valentine/lib/valentine_web/live/workspace_live/show.ex)
- [valentine/lib/valentine_web/live/workspace_live/show.html.heex](valentine/lib/valentine_web/live/workspace_live/show.html.heex)
- [valentine/lib/valentine_web/router.ex](valentine/lib/valentine_web/router.ex)
- [valentine/mix.exs](valentine/mix.exs)
- [valentine/test/support/fixtures/composer_fixtures.ex](valentine/test/support/fixtures/composer_fixtures.ex)
- [valentine/test/valentine/composer_test.exs](valentine/test/valentine/composer_test.exs)
- [valentine/test/valentine_web/live/workspace/index_view_test.exs](valentine/test/valentine_web/live/workspace/index_view_test.exs)