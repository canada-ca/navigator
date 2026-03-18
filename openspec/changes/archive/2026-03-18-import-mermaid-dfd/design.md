## Context

Navigator already exports workspace data flow diagrams as Mermaid through `ValentineWeb.Workspace.Mermaid`, but the editor only supports diagram creation through direct canvas mutations in `Valentine.Composer.DataFlowDiagram` and `ValentineWeb.WorkspaceLive.DataFlow.Index`. The DFD record stores rich node and edge maps, including tags, linked threats, out-of-scope flags, coordinates, and trust-boundary parentage, while Mermaid source mostly captures labels, relationships, and limited structural nesting.

This change spans multiple layers:
- `valentine/lib/valentine_web/workspace/mermaid.ex` and related tests for Mermaid-specific normalization rules.
- `valentine/lib/valentine/composer/data_flow_diagram.ex` for a whole-diagram replacement path that preserves cache and undo/redo history.
- `valentine/lib/valentine_web/live/workspace_live/data_flow/index.ex` and `index.html.heex` for import UI, warning review, confirmation, and collaborative refresh behavior.

The main constraints are: preserve workspace-scoped collaboration semantics, avoid silent data loss during lossy conversion, and keep Navigator's exported `stateDiagram-v2` format as the canonical round-trip target even while tolerating other Mermaid variants during import.

## Goals / Non-Goals

**Goals:**
- Import Mermaid source text into Navigator node and edge records for the current workspace.
- Prefer `stateDiagram-v2` as the canonical format while accepting common Mermaid variants that can be mapped safely.
- Surface import warnings before mutation when Navigator must infer defaults, ignore unsupported syntax, or replace an existing diagram.
- Reuse existing DFD cache, persistence, and history patterns so imported diagrams collaborate like any other diagram update.
- Add focused parser, domain, and LiveView test coverage for supported inputs, warning cases, and invalid input handling.

**Non-Goals:**
- Full support for every Mermaid diagram family or advanced state-diagram feature.
- Preservation of Mermaid presentation-only details such as comments, classes, styling directives, or layout hints.
- Reconstruction of Navigator metadata that Mermaid cannot encode, beyond documented defaults.
- New database schema, permissions model, or separate import storage tables.

## Decisions

### Decision 1: Add a dedicated Mermaid import module beside the existing exporter

**Chosen**: Keep `ValentineWeb.Workspace.Mermaid` as the canonical export entry point and add a dedicated import-focused module under the same namespace, for example `ValentineWeb.Workspace.Mermaid.Import`, responsible for parsing, normalization, warning generation, and conversion into Navigator DFD maps.

**Rationale**: Export and import share Mermaid-specific concepts but have different responsibilities. Keeping them adjacent avoids scattering logic while preventing the current export module from becoming a mixed parser/renderer grab bag.

**Alternatives considered**:
- Put parsing directly into `ValentineWeb.Workspace.Mermaid`: rejected because it would mix outward rendering with tolerant parsing and warning bookkeeping.
- Put parsing into `Valentine.Composer.DataFlowDiagram`: rejected because Mermaid syntax handling is a web/import concern, not the core diagram domain model.

### Decision 2: Support a tolerant subset, not arbitrary Mermaid

**Chosen**: Accept canonical `stateDiagram-v2`, legacy `stateDiagram`, and a constrained subset of `flowchart`/`graph` Mermaid input when nodes, relationships, and simple grouping can be unambiguously mapped to Navigator concepts. Unsupported directives or constructs produce warnings; structurally invalid input produces a blocking error.

**Rationale**: This matches the user's stated need for robustness without pretending Navigator can faithfully import every Mermaid dialect. Supporting a bounded subset makes behavior testable and keeps warnings meaningful.

**Alternatives considered**:
- Only accept `stateDiagram-v2`: rejected because it fails the interoperability goal.
- Attempt to parse all Mermaid syntax: rejected because it would be fragile, slow to validate, and misleading about fidelity.

### Decision 3: Use explicit warning classes for lossy conversion

**Chosen**: The importer returns both a normalized DFD payload and a warning list, with machine-readable categories such as `replacement`, `metadata_defaults`, `unsupported_construct`, `inferred_node_type`, and `implicit_boundary`.

**Rationale**: The UI needs more than a single boolean warning. Structured warnings let the LiveView summarize risk clearly and support future UI refinements without changing parser semantics.

**Alternatives considered**:
- Return only a human-readable warning string: rejected because it is harder to test and extend.
- Fail on any lossy conversion: rejected because most Mermaid imports will necessarily require metadata defaults.

### Decision 4: Import replaces the whole workspace diagram through the DFD domain module

**Chosen**: Add a whole-diagram import/replacement function in `Valentine.Composer.DataFlowDiagram` that accepts already-normalized nodes and edges, writes the new diagram through existing cache and persistence helpers, and records the prior state in undo history.

**Rationale**: Import is semantically closer to `clear_dfd` plus bulk insert than to a sequence of client mutation events. Centralizing the replacement inside the DFD domain module preserves history, avoids partial writes, and keeps LiveView orchestration thin.

**Alternatives considered**:
- Update the `data_flow_diagrams` record directly from the LiveView via `Composer.update_data_flow_diagram/2`: rejected because it bypasses the DFD module's history and cache conventions.
- Replay imported nodes one event at a time: rejected because it is slower, noisier to broadcast, and harder to roll back atomically.

### Decision 5: Use a two-step LiveView import flow

**Chosen**: The data flow editor adds an import entry point that opens a modal or equivalent form, accepts Mermaid source text, runs a validation/preview pass, displays warnings and summary counts, and only mutates the workspace diagram after explicit user confirmation.

**Rationale**: The user explicitly asked for a warning before import because Mermaid lacks Navigator metadata richness. A two-step flow makes destructive replacement explicit and avoids surprising users with inferred defaults.

**Alternatives considered**:
- Immediate import on paste/upload: rejected because it hides destructive effects.
- A separate controller endpoint for preview: rejected because existing editor behavior already lives in LiveView and benefits from staying workspace-context aware.

### Decision 6: Apply deterministic defaults during conversion

**Chosen**: Imported nodes and edges receive Navigator-safe defaults for fields Mermaid cannot provide, including empty tag arrays, nil descriptions, empty linked-threat collections, `out_of_scope` set to `"false"`, generated stable IDs when Mermaid identifiers are absent or unsuitable, and auto-laid-out positions when coordinates are unavailable.

**Rationale**: Import needs a complete DFD payload immediately usable by the existing editor and metadata panel. Deterministic defaults keep imported diagrams editable without additional migration steps.

**Alternatives considered**:
- Leave fields missing or null wherever possible: rejected because existing code expects the current DFD shape.
- Prompt for metadata interactively during import: rejected as too heavy for the first version.

## Risks / Trade-offs

- Unsupported Mermaid constructs may still surprise users -> Mitigation: warn clearly, reject when the graph would be ambiguous, and document the supported subset.
- Auto-inferred node types may not match user intent -> Mitigation: default conservatively, show warnings, and let users edit types after import.
- Whole-diagram replacement can overwrite in-progress edits -> Mitigation: require confirmation, mention replacement explicitly, and store the previous state in undo history.
- Fallback layout may produce cluttered positioning -> Mitigation: apply deterministic spacing and rely on the existing canvas tools for refinement after import.
- Parser complexity can grow quickly if syntax support sprawls -> Mitigation: keep the supported grammar narrow and codify each accepted variant in tests.

## Migration Plan

1. Add the Mermaid import parser/normalizer and its unit tests.
2. Add a DFD domain function for atomic diagram replacement with history support.
3. Extend the data flow LiveView and template with import entry, preview state, warnings, and confirmation handling.
4. Broadcast a full graph refresh after confirmed import so local and remote clients see the imported diagram immediately.
5. Run `make fmt` and `make test`, then manually validate import preview, confirm, cancel, and undo behavior.

Rollback: remove the import UI and new parser/domain entry points; no database rollback is required because this change does not add schema.

## Open Questions

- Whether the first version should expose paste-only Mermaid input or also include file upload in the same modal.
- Whether simple `subgraph` blocks from flowchart syntax should map directly to trust boundaries in version one or be accepted only when trivially structured.