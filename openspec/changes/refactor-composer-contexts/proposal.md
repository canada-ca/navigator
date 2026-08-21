## Why

`Valentine.Composer` has grown into a 2,856-line context containing persistence and query behavior for nearly every workspace capability. Its size and broad dependency surface make changes difficult to navigate, review, test in isolation, and evolve without unrelated recompilation or merge conflicts.

## What Changes

- Split Composer persistence and query behavior into capability-focused context modules under `Valentine.Composer`.
- Retain `Valentine.Composer` as a compatibility facade with the same public functions, arguments, defaults, return values, and exception behavior.
- Keep cross-capability relationship operations in an explicit relationship module rather than hiding them in individual entity contexts.
- Preserve existing schemas, database tables, migrations, PubSub behavior, workspace scoping, authorization behavior, and user-facing workflows.
- Add structural tests and verification that both the new capability modules and the facade preserve the established contracts.
- Do not rewrite all callers as part of this change; direct adoption of capability modules can happen incrementally after the compatibility facade lands.

## Capabilities

### New Capabilities

- `composer-context-boundaries`: Defines modular ownership of Composer persistence/query behavior and compatibility requirements for the existing Composer API.

### Modified Capabilities

None. This is an internal architecture refactor and does not change product requirements.

## Impact

- Affects `valentine/lib/valentine/composer.ex`, new capability modules under `valentine/lib/valentine/composer/`, and Composer-focused tests.
- Preserves the existing application-facing `Valentine.Composer` API, so LiveViews, controllers, MCP tools, AI workflows, exports, and tests remain compatible.
- Introduces no database migration, dependency, route, configuration, API, or deployment changes.
- Rollout is a normal application deployment; rollback is restoring the previous release because persisted data is unchanged.
