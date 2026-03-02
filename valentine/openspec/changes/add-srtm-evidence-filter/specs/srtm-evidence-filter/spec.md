## ADDED Requirements

### Requirement: Display evidence filter options
The SRTM "In scope" tab SHALL display three mutually exclusive filter options: "All", "Needs evidence", and "Evidence attached".

#### Scenario: Filter UI is visible in "In scope" tab
- **WHEN** user navigates to SRTM and views the "In scope" tab
- **THEN** system displays an underline navigation component with three filter options

#### Scenario: Filter UI is not visible in other tabs
- **WHEN** user views "Not allocated" or "Out of scope" tabs
- **THEN** system does NOT display the evidence filter UI

### Requirement: Show counter badges on filter options
Each filter option SHALL display a counter badge showing the number of controls matching that filter.

#### Scenario: Counters show correct counts
- **WHEN** user views the evidence filter
- **THEN** "All" counter shows total in-scope controls count
- **AND** "Needs evidence" counter shows count of controls with zero evidence
- **AND** "Evidence attached" counter shows count of controls with one or more evidence

#### Scenario: Counters update when other filters change
- **WHEN** user changes Profile, Type, Class, or NIST Family filters
- **THEN** counter badges recalculate based on the new filtered control set

### Requirement: Filter controls by evidence status
The system SHALL filter the displayed in-scope controls based on the selected evidence filter option.

#### Scenario: "All" shows all in-scope controls
- **WHEN** user selects "All" filter (default state)
- **THEN** system displays all in-scope controls without filtering

#### Scenario: "Needs evidence" shows controls without evidence
- **WHEN** user selects "Needs evidence" filter
- **THEN** system displays only in-scope controls that have zero evidence attached

#### Scenario: "Evidence attached" shows controls with evidence
- **WHEN** user selects "Evidence attached" filter
- **THEN** system displays only in-scope controls that have one or more evidence attached

### Requirement: Show selected filter state
The system SHALL visually indicate which filter option is currently selected.

#### Scenario: Selected filter has underline
- **WHEN** user selects a filter option
- **THEN** system displays an underline beneath the selected option

#### Scenario: Default selection is "All"
- **WHEN** user first views the "In scope" tab
- **THEN** "All" filter is selected by default

### Requirement: Handle empty filter results
The system SHALL display an appropriate empty state when a filter returns no results.

#### Scenario: Show empty state for no results
- **WHEN** user selects a filter that returns zero controls
- **THEN** system displays a blankslate component with message "No results found"

#### Scenario: Show controls when results exist
- **WHEN** user selects a filter that returns one or more controls
- **THEN** system displays the matching controls in the standard list format

### Requirement: Persist filter across tab switches
The evidence filter selection SHALL remain active when user switches between SRTM tabs.

#### Scenario: Filter persists when switching to other tabs and back
- **WHEN** user selects "Needs evidence" filter
- **AND** switches to "Out of scope" tab
- **AND** switches back to "In scope" tab
- **THEN** "Needs evidence" filter remains selected

#### Scenario: Filter only affects "In scope" tab
- **WHEN** user selects "Needs evidence" filter
- **AND** switches to "Not allocated" tab
- **THEN** "Not allocated" tab shows all controls without evidence filtering

### Requirement: Reset filter when other filters change
The evidence filter SHALL reset to "All" when user changes other SRTM filters.

#### Scenario: Reset to "All" on Profile filter change
- **WHEN** user selects "Needs evidence" filter
- **AND** changes the Profile filter
- **THEN** evidence filter resets to "All"

#### Scenario: Reset to "All" on Type filter change
- **WHEN** user selects "Evidence attached" filter
- **AND** changes the Type filter
- **THEN** evidence filter resets to "All"

#### Scenario: Reset to "All" on Class filter change
- **WHEN** user selects "Needs evidence" filter
- **AND** changes the Class filter
- **THEN** evidence filter resets to "All"

#### Scenario: Reset to "All" on NIST Family filter change
- **WHEN** user selects "Evidence attached" filter
- **AND** changes the NIST Family filter
- **THEN** evidence filter resets to "All"

#### Scenario: Reset to "All" on clear all filters
- **WHEN** user selects "Needs evidence" filter
- **AND** clicks "Clear all filters"
- **THEN** evidence filter resets to "All"

### Requirement: Preserve evidence badge display
The system SHALL continue to display evidence badges on controls regardless of filter selection.

#### Scenario: Evidence badges visible in filtered view
- **WHEN** user selects any evidence filter option
- **THEN** controls with evidence display their evidence badges (e.g., #1, #2)
- **AND** evidence badges remain clickable links to evidence detail pages
