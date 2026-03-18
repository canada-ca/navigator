## Why

Navigator can already export a data flow diagram as Mermaid, but teams cannot bring Mermaid diagrams back into the editor. That creates a one-way workflow, blocks reuse of diagrams created outside Navigator, and makes Mermaid export less useful as an interchange format.

## What Changes

- Add Mermaid-to-DFD import support so a workspace data flow diagram can be created or replaced from Mermaid text.
- Accept Mermaid input that is closest to Navigator's exported `stateDiagram-v2` format while tolerating common syntax variations and non-canonical whitespace, identifiers, and block ordering.
- Show an import review warning before applying a Mermaid import when Navigator must infer missing DFD metadata or when the import will replace an existing diagram.
- Map imported Mermaid structures into Navigator node, edge, and trust-boundary records with safe defaults for metadata that Mermaid cannot express.
- Report parse warnings and unsupported constructs without silently discarding diagram content.

## Capabilities

### New Capabilities
- `mermaid-diagram-import`: Parse Mermaid text into Navigator DFD structures, surface warnings for lossy conversions, and apply validated imports to a workspace diagram.

### Modified Capabilities
- `data-flow-diagrams`: The data flow editor gains an import workflow that previews warnings, confirms replacement of the current diagram, and refreshes the collaborative canvas after import.

## Impact

- Affected code will likely include the existing Mermaid conversion module, the data flow LiveView, the data flow toolbar UI, and Composer-level diagram persistence paths.
- New parser and validation coverage will be needed for Mermaid variants, warning generation, and imported diagram persistence.
- Existing Mermaid export behavior remains supported and should continue emitting Navigator's canonical `stateDiagram-v2` representation.

### Non-Goals

- Round-tripping every Mermaid diagram type or every advanced Mermaid state feature.
- Preserving Mermaid-only presentation details such as comments, styling, direction hints, or arbitrary state classes.
- Reconstructing rich Navigator metadata that is not present in Mermaid source beyond documented defaults and warnings.