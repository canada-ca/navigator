## 1. Baseline and API Inventory

- [x] 1.1 Record the current `Valentine.Composer` public function name/arity inventory for facade parity checks
- [x] 1.2 Run the existing Composer-focused tests before code movement and record a clean behavioral baseline
- [x] 1.3 Confirm the complete test suite passes on the branch before the refactor

## 2. Shared Query Infrastructure

- [x] 2.1 Add `Valentine.Composer.QueryHelpers` for workspace-scoped lookup, preload, and query construction
- [x] 2.2 Move the shared enum filter behavior into `QueryHelpers` without changing supported schema types or boolean composition
- [x] 2.3 Add focused tests for shared workspace isolation and enum filtering behavior

## 3. Workspace and Analysis Capabilities

- [x] 3.1 Extract workspace CRUD, changesets, ownership/invitation updates, and permission checks into `Valentine.Composer.Workspaces`
- [x] 3.2 Verify workspace behavior directly through `Workspaces` with focused tests
- [x] 3.3 Extract repository analysis agents and quality review runs/findings into `Valentine.Composer.AnalysisJobs`
- [x] 3.4 Verify analysis job behavior directly through `AnalysisJobs` with focused tests

## 4. Core Threat-Model Capabilities

- [x] 4.1 Extract threat and threat-agent behavior into `Valentine.Composer.Threats`
- [x] 4.2 Extract assumption behavior into `Valentine.Composer.Assumptions`
- [x] 4.3 Extract mitigation behavior into `Valentine.Composer.Mitigations`
- [x] 4.4 Replace local workspace and enum helpers in the three modules with `QueryHelpers`
- [x] 4.5 Run focused threat, threat-agent, assumption, and mitigation tests through the extracted modules

## 5. Relationships and Evidence

- [x] 5.1 Extract threat/assumption/mitigation and evidence association operations into `Valentine.Composer.Relationships`
- [x] 5.2 Extract evidence CRUD, bulk creation, and association orchestration into `Valentine.Composer.EvidenceManagement`
- [x] 5.3 Replace evidence lookups with direct dependencies on `Threats`, `Assumptions`, and `Mitigations` without routing through the facade
- [x] 5.4 Run focused relationship and evidence tests through the extracted modules

## 6. Documents and Reference Material

- [x] 6.1 Extract application information, data-flow diagrams, and architecture documents into `Valentine.Composer.Documents`
- [x] 6.2 Extract reference pack and reference entry behavior into `Valentine.Composer.ReferencePacks`
- [x] 6.3 Extract control behavior and filters into `Valentine.Composer.Controls`
- [x] 6.4 Run focused document, reference pack, and control tests through the extracted modules

## 7. Identity and Access Capabilities

- [x] 7.1 Extract user lifecycle and provider identity lookups into `Valentine.Composer.Users`
- [x] 7.2 Extract API key lifecycle, hashing, lookup, and verification into `Valentine.Composer.ApiKeys`
- [x] 7.3 Run focused user and API key tests through the extracted modules

## 8. Brainstorm Capability

- [x] 8.1 Extract brainstorm sessions, ideas, voting, grouping, and workspace-scoped behavior into `Valentine.Composer.Brainstorm`
- [x] 8.2 Replace brainstorm workspace helpers with `QueryHelpers` where behavior is shared
- [x] 8.3 Run focused brainstorm tests through the extracted module

## 9. Compatibility Facade

- [x] 9.1 Replace implementation bodies in `Valentine.Composer` with delegates or thin wrappers to the owning capability modules
- [x] 9.2 Preserve all inventoried public names, arities, default arguments, guards, clause order, return values, and exceptions
- [x] 9.3 Ensure capability modules do not depend on the `Valentine.Composer` facade and resolve all compile warnings
- [x] 9.4 Add facade parity tests covering representative reads, writes, filters, relationships, workspace isolation, and bang behavior
- [x] 9.5 Add a structural test that keeps persistence/query implementation out of the facade

## 10. Verification and Handoff

- [x] 10.1 Run the formatter and formatting check for all changed Elixir files
- [x] 10.2 Run all Composer and extracted-capability focused tests
- [x] 10.3 Run the complete automated test suite and resolve every regression
- [x] 10.4 Review the final diff for accidental caller, schema, route, migration, configuration, permission, PubSub, export, or AI-provider behavior changes
- [x] 10.5 Confirm the OpenSpec task list and implementation artifacts accurately describe the completed refactor

## 11. Facade Removal Design and Inventory

- [x] 11.1 Inventory every production, fixture, and test call to the `Valentine.Composer` facade and map each function to its capability owner
- [x] 11.2 Update the OpenSpec proposal, design, specification, and tasks for an atomic caller migration and facade removal

## 12. Production Caller Migration

- [x] 12.1 Migrate core domain, AI workflow, prompt, repository analysis, quality review, seed, and MCP callers to capability modules
- [x] 12.2 Migrate controllers, authentication, authorization, export, and web helper callers to capability modules
- [x] 12.3 Migrate LiveViews and components to capability modules

## 13. Test Caller Migration

- [x] 13.1 Migrate Composer fixtures and domain/context tests to capability modules
- [x] 13.2 Migrate controller, helper, LiveView, and component tests to capability modules

## 14. Facade Deletion and Architecture Enforcement

- [x] 14.1 Replace facade parity assertions with direct capability ownership and behavior assertions
- [x] 14.2 Add a structural assertion that no facade definition, alias, or function call remains in Elixir source
- [x] 14.3 Delete `valentine/lib/valentine/composer.ex` after the repository facade-reference scan reaches zero

## 15. Final Verification

- [x] 15.1 Run formatting and a forced warnings-as-errors compilation
- [x] 15.2 Run focused capability and migrated caller tests
- [x] 15.3 Run the complete Elixir and frontend test suites and resolve regressions
- [x] 15.4 Validate OpenSpec and review the final diff for unintended behavioral changes
