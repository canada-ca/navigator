## Why

`Valentine.Composer` has grown into a 2,856-line context containing persistence and query behavior for nearly every workspace capability. Its size and broad dependency surface make changes difficult to navigate, review, test in isolation, and evolve without unrelated recompilation or merge conflicts.

## What Changes

- Split Composer persistence and query behavior into capability-focused context modules under `Valentine.Composer`.
- Migrate every application, fixture, and test caller from `Valentine.Composer` to the capability module that owns the operation.
- Remove the `Valentine.Composer` compatibility facade after no callers remain.
- Keep cross-capability relationship operations in an explicit relationship module rather than hiding them in individual entity contexts.
- Preserve existing schemas, database tables, migrations, PubSub behavior, workspace scoping, authorization behavior, and user-facing workflows.
- Add structural tests that enforce direct capability ownership and prevent the broad facade from returning.

## Capabilities

### New Capabilities

- `composer-context-boundaries`: Defines modular ownership of Composer persistence/query behavior and direct capability dependency requirements.

### Modified Capabilities

None. This is an internal architecture refactor and does not change product requirements.

## Impact

- Removes `valentine/lib/valentine/composer.ex` and updates LiveViews, controllers, MCP tools, AI workflows, exports, fixtures, and tests to call capability modules directly.
- Removes the internal application-facing `Valentine.Composer` API; compile-time verification ensures no repository caller remains.
- Introduces no database migration, dependency, route, configuration, API, or deployment changes.
- Rollout is a normal application deployment; rollback is restoring the previous release because persisted data is unchanged.
