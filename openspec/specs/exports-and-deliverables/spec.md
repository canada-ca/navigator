# exports-and-deliverables Specification

## Purpose
This specification defines the current baseline behavior for exporting workspace data and deliverables from Navigator. It covers the controller-driven download endpoints that turn workspace records into portable JSON, markdown, spreadsheet, and diagram artifacts.

## Requirements

### Requirement: Whole-workspace export
Navigator SHALL expose an export endpoint that downloads the current workspace as JSON.

#### Scenario: Exporting a workspace as JSON
- **WHEN** a user requests the workspace export endpoint
- **THEN** Navigator serializes the selected workspace as JSON
- **AND** returns it as a downloadable file with JSON content type and a workspace-specific filename

#### Scenario: Workspace export filenames are download-ready
- **WHEN** Navigator returns a whole-workspace export
- **THEN** the response uses an attachment filename derived from the workspace name
- **AND** preserves JSON download semantics through the response headers

### Requirement: Reference-pack-style exports for core entities
Navigator SHALL expose JSON export endpoints for assumptions, mitigations, and threats as standalone deliverables.

#### Scenario: Exporting assumptions as a reference pack
- **WHEN** a user requests the assumptions export endpoint for a workspace
- **THEN** Navigator returns a JSON file containing the workspace name, a generated assumptions description, and the serialized assumptions without linked threats or mitigations
- **AND** uses a reference-pack-style assumptions filename in the download headers

#### Scenario: Exporting mitigations as a reference pack
- **WHEN** a user requests the mitigations export endpoint for a workspace
- **THEN** Navigator returns a JSON file containing the workspace name, a generated mitigations description, and the serialized mitigations without linked assumptions or threats
- **AND** uses a reference-pack-style mitigations filename in the download headers

#### Scenario: Exporting threats as a reference pack
- **WHEN** a user requests the threats export endpoint for a workspace
- **THEN** Navigator returns a JSON file containing the workspace name, a generated threats description, and the serialized threats without linked assumptions or mitigations
- **AND** uses a reference-pack-style threats filename in the download headers

### Requirement: Report-oriented and specialized exports
Navigator SHALL expose specialized downloads for markdown threat-model reports, Excel-based SRTM exports, and Mermaid data flow diagram exports.

#### Scenario: Exporting a markdown threat model report
- **WHEN** a user requests the markdown threat model endpoint for a workspace
- **THEN** Navigator generates a markdown report from the current workspace data
- **AND** returns it as a downloadable markdown file with a workspace-specific filename

#### Scenario: Exporting an Excel SRTM deliverable
- **WHEN** a user requests the Excel SRTM endpoint for a workspace and generation succeeds
- **THEN** Navigator returns the generated spreadsheet as a downloadable Excel file with a workspace-specific filename

#### Scenario: Handling Excel generation failure
- **WHEN** Excel generation fails for the requested workspace
- **THEN** Navigator responds with an internal server error
- **AND** returns a JSON error describing that Excel generation failed

#### Scenario: Exporting a Mermaid diagram
- **WHEN** a user requests the Mermaid data flow endpoint for a workspace
- **THEN** Navigator generates the current workspace data flow diagram in Mermaid format
- **AND** returns it as a downloadable plain-text `.mmd` file

#### Scenario: Mermaid output is graph-ready text
- **WHEN** Navigator returns a Mermaid data flow export
- **THEN** the response body contains Mermaid diagram text rather than binary image data