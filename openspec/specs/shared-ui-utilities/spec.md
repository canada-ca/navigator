## ADDED Requirements

### Requirement: Canonical shared display utilities
The system SHALL provide a canonical shared web-layer utility module for generic display-formatting behavior that is reused across multiple features or invoked from non-feature code. The canonical module MUST own common behaviors such as humanizing enum-like values, joining display lists, and selecting an indefinite article.

#### Scenario: Reused formatting behavior is centralized
- **WHEN** the same display-formatting behavior is needed in more than one web feature or from domain code
- **THEN** that behavior is implemented in the canonical shared utility module rather than duplicated in a feature-scoped helper

### Requirement: Feature helpers delegate generic fallback formatting
Feature-specific helper modules MAY retain product-specific label maps and feature-local wrappers, but they MUST delegate generic fallback formatting behavior to the canonical shared utility module instead of reimplementing their own normalization logic.

#### Scenario: Feature-specific labels use shared fallback behavior
- **WHEN** a feature helper formats a value that is not covered by a feature-specific label mapping
- **THEN** it delegates to the canonical shared utility module and returns the shared fallback formatting result

### Requirement: Shared helper boundaries remain consistent
Generic helper behavior used by more than one feature, or by modules outside the feature that introduced it, MUST NOT be defined only inside a feature-scoped module. Domain modules under `Valentine.Composer` MUST depend only on shared helpers or domain-local functions, not on feature-scoped LiveView helper modules.

#### Scenario: Domain code requires a shared formatting helper
- **WHEN** a domain module needs formatting behavior that also appears in a feature-scoped helper
- **THEN** the behavior is moved to or exposed by the canonical shared utility module before the domain module depends on it

### Requirement: Consolidated helper behavior is regression tested
The system SHALL include focused automated tests for the canonical shared utility module and for migrated call sites whose rendered wording or formatting is expected to remain stable.

#### Scenario: Consolidated output remains stable
- **WHEN** shared formatting behavior is extracted from duplicate helper implementations
- **THEN** automated tests verify the canonical helper output and the affected rendered text remain unchanged for existing supported inputs