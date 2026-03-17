## 1. Audit And Target Selection

- [x] 1.1 Confirm the first consolidation set from the audit: shared text helpers in `valentine/lib/valentine/composer/threat.ex` and `valentine/lib/valentine_web/live/workspace_live/threat/components/threat_helpers.ex`, duplicated report helpers in the threat-model report components, repeated value-humanization helpers, and duplicated repo-analysis status label helpers
- [x] 1.2 Decide which audited behaviors move into a canonical helper, which stay feature-local with delegation, and which are only naming or placement conventions under `valentine/lib/valentine_web/helpers/`
- [x] 1.3 Document the placement rule that domain code and multi-feature logic must not depend on feature-scoped LiveView helper modules

## 2. Shared Helper Foundation

- [x] 2.1 Create the canonical shared display helper module under `valentine/lib/valentine_web/helpers/` with APIs for generic value humanization, list joining, indefinite article selection, and other audited formatting behavior that is reused outside a single feature
- [x] 2.2 Add unit tests covering the shared helper outputs for atoms, binaries, nil values, Oxford-comma list rendering, and article selection so extracted behavior is locked down before wider migration
- [x] 2.3 Update `valentine/lib/valentine_web.ex` and any explicit imports or aliases so the shared helper is consumed consistently from LiveViews, components, and any domain-facing call sites that currently depend on feature-local helpers

## 3. Migrate Duplicate Call Sites

- [x] 3.1 Refactor `Valentine.Composer.Threat` and the threat helper call sites so `show_statement/1` and related rendering paths no longer depend on `ValentineWeb.WorkspaceLive.Threat.Components.ThreatHelpers` for generic text behavior
- [x] 3.2 Consolidate the duplicated helper block in `valentine/lib/valentine_web/live/workspace_live/threat_model/components/report_component.ex` and `valentine/lib/valentine_web/live/workspace_live/threat_model/components/markdown_report_component.ex`, including shared asset aggregation, normalization, and STRIDE-letter formatting where behavior is equivalent
- [x] 3.3 Replace repeated value-humanization logic in components and views such as the filter component, label select component, workspace dashboard, threat agent index, and repo-analysis views with the canonical shared helper while preserving feature-specific labels
- [x] 3.4 Update feature-local helpers such as `valentine/lib/valentine_web/live/workspace_live/evidence/components/evidence_helpers.ex` so feature-owned label maps remain local but generic fallback formatting delegates to the shared helper
- [x] 3.5 Consolidate duplicated repo-analysis status label formatting between `valentine/lib/valentine_web/live/workspace_live/show.ex` and `valentine/lib/valentine_web/live/repo_analysis_agent_live/index.ex`
- [x] 3.6 Review `valentine/lib/valentine_web/helpers/` for utility-role inconsistencies across auth, RBAC, locale, theme, flash, chat, nav, control, and presence helpers, then make only the minimal naming, documentation, or call-site adjustments needed to clarify the shared-helper boundary

## 4. Regression Coverage And Validation

- [x] 4.1 Update affected DataCase, ConnCase, or LiveView tests so threat statements, report output, repo-analysis status labels, and feature-specific display labels keep their existing rendered wording and formatting behavior after consolidation
- [x] 4.2 Run `make fmt` and resolve any formatting issues
- [x] 4.3 Run `make test` and resolve any regressions introduced by the consolidation
- [x] 4.4 Manually verify representative threat, evidence, filter, report, workspace dashboard, and repo-analysis views still render the expected labels and sentence text after the helper migration
- [x] 4.5 Sync the accepted `shared-ui-utilities` behavior into the baseline OpenSpec capability during archive