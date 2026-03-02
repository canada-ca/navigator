## ADDED Requirements

### Requirement: Evidence data loading
The system SHALL preload evidence records when loading the SRTM workspace view.

#### Scenario: Workspace with evidence loaded
- **WHEN** the SRTM page mounts for a workspace
- **THEN** the workspace evidence collection SHALL be preloaded from the database
- **AND** the evidence data SHALL be available in the socket assigns

#### Scenario: Evidence grouped by NIST controls
- **WHEN** evidence records are loaded
- **THEN** evidence SHALL be grouped by their NIST control IDs into a map structure
- **AND** the map SHALL use NIST control IDs as keys and lists of evidence as values
- **AND** only evidence with non-nil nist_controls SHALL be included

### Requirement: NIST control ID validation
The system SHALL validate NIST control IDs using regex pattern matching before grouping evidence.

#### Scenario: Valid NIST control ID format
- **WHEN** processing evidence nist_controls array
- **THEN** only control IDs matching the regex pattern `^[A-Za-z]{2}-\d+(\.\d+)?$` SHALL be included
- **AND** invalid control IDs SHALL be filtered out

#### Scenario: Multiple control IDs per evidence
- **WHEN** an evidence record has multiple NIST control IDs
- **THEN** the evidence SHALL appear in the map under each valid control ID
- **AND** the same evidence instance SHALL be referenced (not duplicated)

### Requirement: Evidence display in In Scope tab
The system SHALL display evidence reference labels next to NIST control IDs in the SRTM "In scope" tab.

#### Scenario: Control with linked evidence
- **WHEN** displaying a NIST control ID in the "In scope" tab
- **AND** evidence records exist with that control ID in their nist_controls array
- **THEN** evidence reference labels SHALL be displayed after the control ID
- **AND** each label SHALL display the evidence numeric_id in brackets format `[#N]`
- **AND** labels SHALL be sorted by evidence numeric_id in ascending order

#### Scenario: Control without evidence
- **WHEN** displaying a NIST control ID in the "In scope" tab
- **AND** no evidence records have that control ID
- **THEN** only the control ID SHALL be displayed
- **AND** no error SHALL occur

#### Scenario: Evidence not shown in other tabs
- **WHEN** displaying controls in the "Out of scope" tab
- **THEN** evidence reference labels SHALL NOT be displayed
- **WHEN** displaying controls in the "Not allocated" tab
- **THEN** evidence reference labels SHALL NOT be displayed

### Requirement: Evidence label interactivity
Evidence reference labels SHALL be clickable links that navigate to the evidence detail page.

#### Scenario: Clicking evidence label
- **WHEN** user clicks on an evidence reference label `[#N]`
- **THEN** the evidence detail page SHALL open in a new browser tab
- **AND** the URL SHALL be `/workspaces/:workspace_id/evidence/:evidence_id`
- **AND** the current SRTM page SHALL remain open

#### Scenario: Evidence label tooltip
- **WHEN** user hovers over an evidence reference label
- **THEN** a tooltip SHALL display showing the evidence name
- **AND** the tooltip SHALL use native browser tooltip behavior

### Requirement: Evidence label styling
Evidence reference labels SHALL use consistent styling matching existing evidence component patterns.

#### Scenario: Label appearance
- **WHEN** evidence labels are displayed
- **THEN** labels SHALL use small state label styling with open status (green)
- **AND** labels SHALL have left margin spacing of 4px between each label
- **AND** labels SHALL display the numeric ID with hash prefix format `#N`

#### Scenario: Visual consistency with evidence component
- **WHEN** evidence labels are rendered
- **THEN** styling SHALL use PrimerLive `.state_label` component
- **AND** SHALL use `is_small` and `is_open` attributes for size and status styling

### Requirement: Evidence data updates
Evidence data SHALL be refreshed when the SRTM page is manually refreshed or filters are updated.

#### Scenario: Manual page refresh
- **WHEN** user refreshes the browser page
- **THEN** evidence data SHALL be reloaded from the database
- **AND** evidence labels SHALL reflect current evidence records and their NIST controls

#### Scenario: Filter changes
- **WHEN** user applies filters to the SRTM view
- **THEN** evidence grouping SHALL be recalculated
- **AND** evidence labels SHALL remain consistent with the filtered controls

#### Scenario: No automatic updates
- **WHEN** evidence records are modified in another session
- **THEN** the SRTM page SHALL NOT automatically update
- **AND** user SHALL refresh the page manually to see changes

### Requirement: Performance characteristics
Evidence loading and display SHALL maintain acceptable page performance.

#### Scenario: Evidence preloading
- **WHEN** loading workspace with evidence
- **THEN** evidence SHALL be loaded in a single database query via Ecto preload
- **AND** no N+1 query problems SHALL occur

#### Scenario: Evidence grouping efficiency
- **WHEN** grouping evidence by NIST control IDs
- **THEN** grouping operation SHALL complete in O(n) time complexity
- **AND** map lookups for control IDs SHALL be O(1) operations
