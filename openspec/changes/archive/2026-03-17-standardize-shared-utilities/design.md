## Context

Navigator's Phoenix web layer currently mixes three kinds of helper behavior:

1. Truly generic formatting logic that is reused across features, such as humanizing enum-like values, joining lists for display, and selecting an indefinite article.
2. Feature-scoped formatting logic, such as evidence-type label maps.
3. Request and LiveView lifecycle helpers, such as auth plugs and chat or flash mount hooks.

Today those boundaries are inconsistent. For example, `Valentine.Composer.Threat` depends on `ValentineWeb.WorkspaceLive.Threat.Components.ThreatHelpers`, which couples domain logic to a feature-scoped web module. Similar formatting logic is repeated across evidence helpers, report components, filter components, workspace dashboards, and repo-analysis views. This change is cross-cutting because it touches shared helpers, domain-to-web boundaries, and multiple LiveView surfaces, but it is intentionally narrow: preserve current behavior while standardizing where shared logic lives and how it is consumed.

The audit identified four concrete first-pass targets:

1. Cross-layer coupling between `valentine/lib/valentine/composer/threat.ex` and `valentine/lib/valentine_web/live/workspace_live/threat/components/threat_helpers.ex` for generic article and list-formatting behavior.
2. An almost identical helper block in `valentine/lib/valentine_web/live/workspace_live/threat_model/components/report_component.ex` and `valentine/lib/valentine_web/live/workspace_live/threat_model/components/markdown_report_component.ex` for `get_assets/1`, normalization, and STRIDE-letter formatting.
3. Repeated value-humanization logic in `filter_component`, `label_select_component`, `workspace_live/show.ex`, `threat_agent/index.ex`, `repo_analysis_agent_live/index.ex`, and evidence formatting fallback paths.
4. Duplicated repo-analysis status-label formatting in `workspace_live/show.ex` and `repo_analysis_agent_live/index.ex`.

Likely implementation anchors:

- `valentine/lib/valentine_web.ex`
- `valentine/lib/valentine_web/helpers/`
- `valentine/lib/valentine/composer/threat.ex`
- `valentine/lib/valentine_web/live/workspace_live/threat/components/threat_helpers.ex`
- `valentine/lib/valentine_web/live/workspace_live/evidence/components/evidence_helpers.ex`
- `valentine/lib/valentine_web/live/workspace_live/components/filter_component.ex`
- `valentine/lib/valentine_web/live/workspace_live/components/label_select_component.ex`
- `valentine/lib/valentine_web/live/workspace_live/show.ex`
- `valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex`
- `valentine/lib/valentine_web/live/workspace_live/threat_agent/index.ex`
- `valentine/lib/valentine_web/live/workspace_live/threat_model/components/report_component.ex`
- `valentine/lib/valentine_web/live/workspace_live/threat_model/components/markdown_report_component.ex`

## Goals / Non-Goals

**Goals:**

- Introduce one canonical shared helper module for generic display-formatting behavior used in multiple places.
- Remove cross-layer coupling where domain code calls feature-local web helper modules.
- Eliminate the exact duplicate helper block shared by the HTML and Markdown threat-model report renderers where the behavior is already equivalent.
- Establish a consistent rule for what stays feature-local versus what moves into the shared helper layer.
- Standardize how shared helpers are imported or referenced from LiveViews and components.
- Preserve current user-facing output through targeted regression tests.

**Non-Goals:**

- Reorganizing all helper modules in a single pass.
- Changing authentication, authorization, chat, or flash behavior beyond clarifying module responsibilities and call sites where needed.
- Redesigning UI copy, labels, or reports as a product change.
- Creating a new application context or moving general UI helpers into `Valentine.Composer`.

## Decisions

### Decision 1: Create a canonical shared display helper under `ValentineWeb.Helpers`

**Chosen:** Introduce a shared helper module in `valentine/lib/valentine_web/helpers/` for generic display behavior, with functions for enum/value humanization, list joining, indefinite article selection, and other audited formatting behavior that is clearly reused across multiple features.

**Rationale:** The repo already uses `ValentineWeb.Helpers.*` as the home for reusable web-layer functionality. Reusing that namespace avoids inventing a parallel abstraction while giving non-feature code a stable module to call. It also directly addresses the current misuse where domain code reaches into a threat-specific LiveView helper for article and list formatting.

**Alternatives considered:**
- Keep the current feature-local helpers and only document conventions. Rejected because duplicated implementations and the domain-to-feature dependency would remain.
- Move all formatting logic into `Valentine.Composer`. Rejected because most of this behavior is presentation-oriented rather than domain logic.

### Decision 2: Keep feature-specific label maps local, but require delegation for generic fallback behavior

**Chosen:** Modules such as evidence-specific helpers may continue to own feature-specific label maps, but they must delegate generic fallback formatting to the shared helper rather than reimplementing string normalization.

**Rationale:** Some features have legitimate product-specific labels that should stay close to the feature. Delegation preserves that locality while preventing multiple fallback implementations from drifting apart. The evidence helper is the clearest example: its label map is feature-owned, but its default formatting behavior overlaps with other components.

**Alternatives considered:**
- Collapse all helper behavior into one module. Rejected because it would create a catch-all helper module with weak ownership boundaries.

### Decision 3: Shared behavior used by multiple features or domain code must not live in feature-scoped modules

**Chosen:** If helper behavior is used by more than one feature, or by domain code under `Valentine.Composer`, it must be implemented in the shared helper layer. Feature modules may keep wrapper functions temporarily for compatibility, but those wrappers must delegate.

**Rationale:** This removes the current dependency inversion where core code calls into a feature-specific LiveView helper, and it gives future contributors a simple placement rule. It also gives an explicit home to exact duplicates such as the repo-analysis status label helper that currently exists in two separate LiveViews.

**Alternatives considered:**
- Allow shared behavior to stay in the first feature that introduced it. Rejected because that keeps ownership ambiguous and makes reuse harder to discover.

### Decision 4: Validate the consolidation with unit tests and focused regression tests

**Chosen:** Add direct unit tests for the shared helper functions and update the most affected domain/UI tests where wording or formatted output is expected.

**Rationale:** The highest risk in this change is subtle wording drift. Small focused tests are cheaper and more reliable than broad manual comparison, especially for threat statements, report output, and status labels where multiple views currently implement similar formatting independently.

**Alternatives considered:**
- Rely only on existing integration tests. Rejected because many formatting helpers are not covered precisely enough to detect copy regressions.

### Decision 5: Extract report-shared helpers only where the HTML and Markdown components already agree semantically

**Chosen:** Consolidate the duplicated report helper block only for behavior that is already semantically identical between the HTML and Markdown report renderers, such as impacted-asset aggregation, normalization, and STRIDE-letter formatting. Keep renderer-specific output concerns local.

**Rationale:** The two report components share exact helper implementations in some areas and intentionally differ in others, such as optional content rendering and HTML-to-Markdown conversion. Extracting only the shared logic gives a good consolidation win without blurring renderer-specific responsibilities.

**Alternatives considered:**
- Merge both report components into one abstraction. Rejected because the output formats differ enough that a single renderer abstraction would add complexity rather than remove it.

## Risks / Trade-offs

- Over-centralized helper module becoming a dumping ground -> Mitigation: only move behavior that is generic and reused, and keep feature-owned label maps local.
- Wording drift in threat or report text -> Mitigation: add regression tests for migrated call sites and preserve existing output strings when extracting helpers.
- Extracting report helpers too aggressively and erasing output-format differences -> Mitigation: only share helpers for identical behavior and keep HTML-versus-Markdown rendering decisions local.
- Partial adoption leaving old and new patterns side by side -> Mitigation: define a concrete first migration set and update contributor-facing conventions in module docs or adjacent comments where appropriate.
- Import churn across LiveViews and components -> Mitigation: prefer a small number of explicit imports through `ValentineWeb` or local aliases instead of introducing another layer of indirection.

## Migration Plan

1. Introduce the shared helper module and its unit tests.
2. Move generic threat sentence helpers out of the threat feature module and update `Valentine.Composer.Threat` plus threat UI call sites to use the shared helper.
3. Extract the shared helper block from the two threat-model report components where the logic is already equivalent.
4. Migrate repeated humanize and repo-analysis status-label helpers to the shared helper, while keeping feature-owned label maps local.
5. Update any remaining feature-local wrappers to delegate to the shared helper.
6. Run `make fmt` and `make test`.

Rollback is straightforward because this is an internal refactor: revert the helper extraction and restore previous call sites if regressions are discovered.

## Open Questions

- Should shared helper functions be imported centrally via `ValentineWeb.html_helpers/0`, or should most call sites reference the shared module explicitly to keep dependency flow obvious?
- Should lifecycle helper naming and placement (`AuthHelper`, `ApiAuthHelper`, `ChatHelper`, `FlashHelper`, `ThemeHelper`, `LocaleHelper`) be normalized in this change if the work stays documentation-level, or should that remain follow-up work after the display-helper consolidation is merged?
