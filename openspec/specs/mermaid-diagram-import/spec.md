# mermaid-diagram-import Specification

## Purpose
This specification defines the baseline behavior for importing Mermaid diagrams into Navigator data flow diagrams. It covers the supported Mermaid syntax subset, warning behavior for lossy conversion, and the normalized DFD payload produced after import.

## Requirements

### Requirement: Mermaid source can be converted into Navigator DFD structures
Navigator SHALL accept Mermaid source text for data flow import when the source uses `stateDiagram-v2`, `stateDiagram`, or another supported Mermaid variant whose nodes, edges, and simple grouping can be mapped unambiguously into Navigator DFD nodes, edges, and trust boundaries.

#### Scenario: Importing canonical Mermaid state diagram syntax
- **WHEN** a user provides valid `stateDiagram-v2` Mermaid that follows Navigator's exported structure
- **THEN** Navigator parses the Mermaid source into DFD nodes, edges, and trust-boundary relationships without blocking the import

#### Scenario: Importing supported non-canonical Mermaid syntax
- **WHEN** a user provides Mermaid source using a supported non-canonical variant such as `stateDiagram` or a simple `flowchart`/`graph` form
- **THEN** Navigator normalizes the supported syntax into the same internal DFD structure used for canonical Mermaid import
- **AND** records warnings for any inferred defaults or downgraded constructs required during normalization

#### Scenario: Rejecting unsupported or invalid Mermaid input
- **WHEN** a user provides Mermaid source that cannot be parsed safely into a meaningful DFD
- **THEN** Navigator rejects the import
- **AND** reports a validation error without mutating the workspace diagram

### Requirement: Lossy conversion is disclosed before import
Navigator SHALL summarize lossy conversion conditions before applying a Mermaid import, including replacement of an existing diagram, inferred node typing, metadata defaults, and unsupported constructs that cannot be represented in Navigator.

#### Scenario: Import requires metadata defaults
- **WHEN** Mermaid input omits Navigator-only metadata such as tags, linked threats, descriptions, or coordinates
- **THEN** Navigator lists a warning that default metadata values will be applied during import

#### Scenario: Import includes unsupported Mermaid constructs
- **WHEN** Mermaid input contains constructs that Navigator does not preserve, such as presentation-only directives or unsupported grouping semantics
- **THEN** Navigator lists those constructs as warnings before the user confirms import

### Requirement: Confirmed Mermaid import produces an editable DFD
Navigator SHALL convert a confirmed Mermaid import into a complete workspace DFD payload that is immediately editable in the existing diagram editor.

#### Scenario: Imported nodes and edges receive Navigator defaults
- **WHEN** a user confirms a valid Mermaid import
- **THEN** Navigator stores imported nodes and edges using the existing DFD shape with safe default metadata values for fields Mermaid cannot provide
- **AND** generates any required stable identifiers and positions needed by the editor

#### Scenario: Trust boundaries are preserved from supported grouping syntax
- **WHEN** Mermaid input includes supported state blocks or supported grouping syntax that maps to trust boundaries
- **THEN** Navigator stores the corresponding DFD nodes with parent-child relationships representing those trust boundaries