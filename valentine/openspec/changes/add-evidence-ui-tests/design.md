## Context

The evidence UI functionality was recently added to the Valentine application, introducing:
- `EvidenceComponent` - A display component for evidence cards
- `Evidence.Show` - A LiveView for creating and editing evidence with form controls
- `Evidence.Index` - Extended to support entity linking (assumptions, threats, mitigations)
- Six new Composer functions for evidence-to-entity linking
- Extended `EntityLinkerComponent` to support evidence as a source entity

Currently, these changes lack comprehensive test coverage. The codebase has established testing patterns for similar components (threats, assumptions, mitigations) that we should follow for consistency.

## Goals / Non-Goals

**Goals:**
- Achieve comprehensive test coverage for all new evidence UI functionality
- Follow existing test patterns from threats/assumptions/mitigations for consistency
- Test behavior rather than implementation details (user-facing functionality)
- Cover happy paths, error cases, and edge cases
- Ensure tests are maintainable and follow Elixir/Phoenix best practices

**Non-Goals:**
- Refactoring existing test infrastructure
- Testing existing evidence functionality that already has coverage (basic CRUD from earlier work)
- End-to-end/integration tests (focus on unit and LiveView tests)
- Testing third-party library behavior (PrimerLive, Phoenix LiveView core)

## Decisions

### 1. Test Organization Pattern

**Decision:** Mirror the existing test structure for threats/assumptions/mitigations.

**Rationale:**
- Consistency makes the codebase easier to navigate
- Existing patterns are proven and well-understood by the team
- New developers can reference similar test files for examples

**Structure:**
- Component tests in `test/valentine_web/live/components/`
- LiveView tests in `test/valentine_web/live/workspace_live/evidence/`
- Context tests in `test/valentine/composer_test.exs`

### 2. Test Scope and Coverage

**Decision:** Focus on behavior testing with strategic coverage of critical paths.

**Approach:**
- **EvidenceComponent:** Render behavior, helper function outputs, button actions
- **Evidence.Show:** Mount/params, form field updates, tag management, save operations (create/update), validation errors
- **Evidence.Index:** Entity linking actions (all three: assumptions, threats, mitigations), handle_info for saved entities
- **Composer functions:** All six new linking functions (add/remove for each entity type), error handling
- **EntityLinkerComponent:** Evidence as source for all three target entity types

**Rationale:**
- Tests validate user-facing functionality
- Critical paths are protected against regressions
- Internal implementation details can change without breaking tests

### 3. Test Data and Fixtures

**Decision:** Use existing `ComposerFixtures` for test data setup.

**Rationale:**
- Fixtures already exist for evidence, assumptions, threats, mitigations
- Promotes test data consistency across the suite
- Reduces test setup boilerplate

**Usage:**
```elixir
import Valentine.ComposerFixtures

workspace = workspace_fixture()
evidence = evidence_fixture(%{workspace_id: workspace.id})
assumption = assumption_fixture(%{workspace_id: workspace.id})
```

### 4. LiveView Testing Approach

**Decision:** Use hybrid testing with both unit tests (handle_event) and integration tests (full LiveView).

**Pattern:**
- For handle_event unit tests: Use properly initialized sockets with `Phoenix.LiveView.assign/3`
  ```elixir
  socket = %Phoenix.LiveView.Socket{}
  socket = Phoenix.LiveView.assign(socket, :workspace_id, workspace.id)
  socket = Phoenix.LiveView.assign(socket, :changes, %{})
  ```
- For integration tests: Use `live/3`, `form/2`, `render_submit/1` for complete workflows
- When accessing `view.assigns`: Call `render(view)` first to ensure LiveView is fully mounted
- Test public behavior only - private helper functions are tested indirectly through integration tests
- Follow the hybrid pattern: unit tests for fast feedback, integration tests for confidence

**Rationale:**
- Hybrid approach balances speed (unit) with confidence (integration)
- Properly initialized sockets avoid internal state issues with `__changed__` tracking
- Testing private functions couples tests to implementation details
- Repository pattern uses this hybrid approach consistently
- Direct assigns access requires full mount cycle to complete

### 5. Mocking Strategy

**Decision:** Use Mock library sparingly, only for external dependencies or complex Composer operations.

**When to mock:**
- In component tests when testing error scenarios that are hard to trigger naturally
- When testing specific edge cases in the Index tests

**When NOT to mock:**
- Simple CRUD operations in the database
- Basic LiveView state changes
- Helper function outputs

**Rationale:**
- Real database operations in tests provide better confidence
- ExUnit's built-in sandbox makes database tests fast and isolated
- Excessive mocking can create brittle tests that don't catch real issues

### 6. Validation Testing

**Decision:** Test validation errors at both the LiveView and Composer levels.

**Approach:**
- In `Evidence.Show` tests: Verify errors are assigned to socket and displayed
- In Composer tests: Verify changeset errors for invalid data
- Test both invalid JSON parsing and schema-level validations

**Rationale:**
- Validation can fail at multiple layers
- Users need appropriate feedback at the UI level
- Business logic should be protected at the context level

## Risks / Trade-offs

**Risk:** Tests might become brittle if they rely too heavily on HTML structure
→ **Mitigation:** Focus assertions on data attributes, IDs, and text content rather than CSS classes or element hierarchy

**Risk:** LiveView tests can be slower than unit tests
→ **Mitigation:** Use direct function testing (handle_event) where possible, limit full render tests to critical paths

**Risk:** Test coverage might miss edge cases in the entity linking logic
→ **Mitigation:** Follow the comprehensive coverage from existing EntityLinkerComponent tests, which already test all entity type combinations

**Trade-off:** Not testing every permutation of field updates in Evidence.Show
→ **Acceptance:** Test representative examples (content_raw, evidence_type, tags) rather than exhaustive field testing. Implementation is straightforward and similar to existing forms.

**Risk:** Changes to evidence-ui branch code could invalidate these test plans
→ **Mitigation:** Verify current implementation before writing tests, adjust test scenarios if needed
