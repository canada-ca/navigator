## Why

The evidence-ui branch introduces significant new UI functionality for evidence management, including a new display component, create/edit form, and entity linking capabilities. However, these changes currently lack test coverage, which creates risk for regressions and makes future refactoring more difficult. We need comprehensive test coverage that follows the existing patterns established for threats, assumptions, and mitigations.

## What Changes

- Add test coverage for `EvidenceComponent` display component (rendering, formatting helpers)
- Add test coverage for `Evidence.Show` LiveView (mount, handle_params, form events, save operations)
- Extend `Evidence.Index` tests to cover entity linking actions (assumptions, threats, mitigations)
- Add test coverage for new Composer module functions (add/remove evidence-to-entity linking)
- Extend `EntityLinkerComponent` tests to cover evidence as source entity
- Follow existing test patterns from threat/assumption/mitigation tests for consistency

## Capabilities

### New Capabilities
- `evidence-component-tests`: Tests for the EvidenceComponent display component
- `evidence-show-tests`: Tests for the Evidence.Show LiveView (create/edit form)
- `evidence-index-linking-tests`: Tests for entity linking actions in Evidence.Index
- `evidence-composer-tests`: Tests for new Composer functions for evidence entity linking
- `evidence-entity-linker-tests`: Tests for evidence support in EntityLinkerComponent

### Modified Capabilities
<!-- No existing capabilities are being modified - this is purely additive test coverage -->

## Impact

- Test files: Creates 5 new test files or extends existing ones
  - `test/valentine_web/live/components/evidence_component_test.exs` (new)
  - `test/valentine_web/live/workspace/evidence/show_test.exs` (new)
  - `test/valentine_web/live/workspace/evidence/index_test.exs` (extend)
  - `test/valentine/composer_test.exs` (extend with new evidence linking functions)
  - `test/valentine_web/live/components/entity_linker_component_test.exs` (extend)
- No impact on production code - tests only
- No breaking changes
- Follows existing test patterns and conventions from similar components
