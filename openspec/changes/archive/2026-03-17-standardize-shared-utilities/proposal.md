## Why

Navigator's web layer has accumulated overlapping helper modules and feature-local formatting functions, but the duplication is not evenly distributed. The most immediate issues are that `Valentine.Composer.Threat` depends on a feature-scoped threat helper for generic string formatting, the HTML and Markdown threat-model reports duplicate the same normalization and asset-aggregation helpers, and multiple LiveViews each reimplement their own value-humanization and repo-analysis status-label logic. That duplication makes new UI work slower, creates inconsistent wording across workspace features, and raises regression risk when the same formatting behavior needs to change in multiple places.

## What Changes

- Introduce a canonical shared-utility surface for common display-formatting behavior that is currently reimplemented in feature-local modules and views.
- Remove the current domain-to-feature dependency by moving generic threat sentence helpers out of `ValentineWeb.WorkspaceLive.Threat.Components.ThreatHelpers` and into a shared location suitable for reuse from `Valentine.Composer.Threat`.
- Consolidate the duplicated helper block used by the HTML and Markdown threat-model report components for impacted-asset aggregation, normalization, and STRIDE-letter formatting.
- Standardize repeated humanization and status-label formatting used in the filter component, label select component, workspace dashboard, threat agent index, and repo-analysis views.
- Keep feature-specific label maps such as evidence labels local, but require generic fallback formatting to delegate to the shared utility layer.
- Define standard placement rules for shared utilities versus feature-scoped helpers so new code lands in consistent modules.
- Add focused tests around the consolidated helpers so wording and formatting remain stable as features evolve.

## Capabilities

### New Capabilities

- `shared-ui-utilities`: Defines the canonical shared utility layer for repeated web formatting and helper behavior, including where shared helpers live, what behavior must be centralized, and how feature code consumes those helpers.

### Modified Capabilities

- None.

## Impact

- Affected code will primarily live under `valentine/lib/valentine_web/`, especially shared helper modules, `ValentineWeb`, and workspace LiveView/component helpers that currently own duplicate formatting behavior.
- Expected touch points include `valentine/lib/valentine/composer/threat.ex`, threat presentation helpers, evidence formatting helpers, the two threat-model report components, generic filter/select formatting paths, workspace dashboard status formatting, and repo-analysis views.
- No database migrations, API contract changes, or feature removals are required.
- The main risk is accidental wording drift in existing UI copy, so the change should include regression tests for consolidated formatting behavior.

### Non-Goals

- Redesigning workspace workflows or changing product behavior beyond preserving existing outputs through shared implementations.
- Rewriting unrelated business logic in `Valentine.Composer` that does not participate in duplicated helper behavior.
- Collapsing all helper modules under `valentine/lib/valentine_web/helpers/` into a single abstraction or rewriting lifecycle helpers that are only similar by structure.
- Performing a broad UI visual refresh or component-library migration.