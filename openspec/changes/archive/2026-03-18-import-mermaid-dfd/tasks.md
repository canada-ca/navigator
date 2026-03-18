## 1. Mermaid Parsing Foundation

- [x] 1.1 Add a Mermaid import parser/normalizer module alongside the existing Mermaid exporter to convert supported Mermaid syntax into Navigator DFD node, edge, and trust-boundary structures.
- [x] 1.2 Implement support for canonical `stateDiagram-v2`, legacy `stateDiagram`, and the agreed supported subset of `flowchart`/`graph` syntax with explicit warning generation for lossy conversions.
- [x] 1.3 Add unit tests covering canonical imports, supported non-canonical imports, unsupported constructs, invalid input, default metadata assignment, and trust-boundary mapping.

## 2. DFD Domain Integration

- [x] 2.1 Add a whole-diagram import/replacement function in `Valentine.Composer.DataFlowDiagram` that persists imported nodes and edges through the existing cache and history flow.
- [x] 2.2 Ensure confirmed imports can be undone and redone using the existing history model without partial writes or stale cache state.
- [x] 2.3 Add domain-level tests for confirmed import persistence, unchanged state on rejected import, and history restoration after undo.

## 3. Data Flow Editor Import Workflow

- [x] 3.1 Extend the data flow LiveView and toolbar UI with a Mermaid import entry point and workspace-scoped form state for Mermaid source text.
- [x] 3.2 Implement preview/validation events that summarize import counts and warnings, including destructive replacement warnings when the current diagram is non-empty.
- [x] 3.3 Implement confirmation and cancel flows so confirmed imports refresh the canvas for local and remote clients, while cancelled imports leave the diagram unchanged.
- [x] 3.4 Add LiveView tests for opening import, previewing warnings, confirming import, cancelling import, and remote refresh behavior.

## 4. Supported Behavior and Spec Alignment

- [x] 4.1 Confirm the implementation keeps Mermaid export canonical on `stateDiagram-v2` while importing the supported tolerant subset defined in the new spec.
- [x] 4.2 Adjust parser warnings, supported-syntax messaging, and any user-facing copy so they match the accepted behavior captured in the OpenSpec proposal, design, and spec files.

## 5. Verification

- [x] 5.1 Run `make fmt` and resolve formatting issues.
- [x] 5.2 Run `make test` and resolve regressions in Mermaid, DFD, controller, and LiveView coverage.
- [x] 5.3 Manually verify importing Mermaid into an empty diagram, importing over an existing diagram with warnings, cancelling import, and undoing a confirmed import.
- [x] 5.4 Manually verify Mermaid export still produces the canonical download format after importing and editing a diagram.