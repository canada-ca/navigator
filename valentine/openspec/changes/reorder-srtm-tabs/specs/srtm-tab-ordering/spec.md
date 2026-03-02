## ADDED Requirements

### Requirement: SRTM percentage boxes SHALL display in priority order
The SRTM view percentage summary boxes SHALL display in the order: In scope, Out of scope, Not allocated. This order SHALL prioritize the most relevant information (in-scope controls) first.

#### Scenario: User views SRTM percentage summary
- **WHEN** user navigates to the SRTM page
- **THEN** the percentage boxes SHALL appear in the following left-to-right order:
  1. In scope (left section, first box)
  2. Out of scope (left section, second box)
  3. Not allocated (right section, solo box)

#### Scenario: Layout adapts to screen size
- **WHEN** user views SRTM on desktop viewport (≥768px width)
- **THEN** In scope and Out of scope boxes SHALL share 8 columns on the left
- **AND** Not allocated box SHALL occupy 4 columns on the right

#### Scenario: Mobile viewport layout
- **WHEN** user views SRTM on mobile viewport (<768px width)
- **THEN** all three percentage boxes SHALL stack vertically in order: In scope, Out of scope, Not allocated

### Requirement: SRTM tabs SHALL display in priority order
The SRTM view tab navigation SHALL display tabs in the order: In scope, Out of scope, Not allocated. This order SHALL match the percentage summary order for consistency.

#### Scenario: User views SRTM tabs
- **WHEN** user views the SRTM tab navigation
- **THEN** tabs SHALL appear in the following left-to-right order:
  1. In scope
  2. Out of scope
  3. Not allocated

#### Scenario: Tab content loads correctly
- **WHEN** user clicks any tab in the new order
- **THEN** the corresponding control list SHALL display correctly
- **AND** all existing functionality (evidence filtering, control details) SHALL work without changes

### Requirement: Visual layout SHALL maintain proper borders and styling
The percentage boxes SHALL render with proper borders to create a unified visual block for In scope and Out of scope boxes, while Not allocated remains visually separate.

#### Scenario: Adjacent boxes render correctly
- **WHEN** In scope and Out of scope boxes are displayed side-by-side
- **THEN** In scope box SHALL have left border and rounded left corners
- **AND** Out of scope box SHALL have right border and rounded right corners
- **AND** the two boxes SHALL appear as a single unified visual block

#### Scenario: Not allocated box renders independently
- **WHEN** Not allocated box is displayed
- **THEN** it SHALL have all borders and fully rounded corners
- **AND** it SHALL appear visually distinct from the In scope/Out of scope block

### Requirement: Existing functionality SHALL remain unchanged
All existing SRTM functionality SHALL continue to work exactly as before, with only the display order changing.

#### Scenario: Evidence filtering works in In scope tab
- **WHEN** user selects "Needs evidence" filter in the In scope tab
- **THEN** the system SHALL filter controls to show only those without evidence
- **AND** the filter counts SHALL display correctly

#### Scenario: Control details expand correctly
- **WHEN** user clicks "More information" on any control
- **THEN** the control details SHALL expand and display correctly
- **AND** all control metadata (NIST ID, name, description) SHALL render properly

#### Scenario: Export functionality preserves logical order
- **WHEN** user clicks "Export to Excel"
- **THEN** the exported data SHALL include controls in their logical groups
- **AND** the export order SHALL be determined by backend logic, not display order
