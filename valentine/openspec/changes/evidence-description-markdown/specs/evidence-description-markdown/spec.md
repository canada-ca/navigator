## ADDED Requirements

### Requirement: Description field supports markdown editing
The evidence description field SHALL provide a Write/Preview tab interface for markdown editing, matching the user experience of threat comments.

#### Scenario: User writes markdown in description
- **WHEN** user is on the evidence create/edit page
- **THEN** the description field SHALL display Write and Preview tabs
- **THEN** the Write tab SHALL contain a textarea for entering markdown text
- **THEN** the textarea SHALL include a caption "Markdown is supported"
- **THEN** the textarea SHALL have placeholder text "Describe this evidence..."

#### Scenario: User previews markdown rendering
- **WHEN** user enters markdown text in the Write tab
- **THEN** switching to Preview tab SHALL render the markdown as formatted HTML
- **THEN** the Preview tab SHALL use the same MarkdownComponent used for threat comments
- **THEN** switching between tabs SHALL preserve the entered text

#### Scenario: User creates evidence with markdown description
- **WHEN** user enters markdown in the description field and saves
- **THEN** the markdown text SHALL be stored as plain text in the database
- **THEN** the evidence SHALL save successfully with the markdown content

### Requirement: Description displays as rendered markdown
The evidence description SHALL be rendered as formatted HTML in all views where evidence is displayed, not as raw markdown text.

#### Scenario: Evidence list shows formatted descriptions
- **WHEN** evidence with markdown description is displayed in the evidence list
- **THEN** the description SHALL be rendered as formatted HTML
- **THEN** markdown formatting (bold, italic, lists, links, etc.) SHALL be visible

#### Scenario: Evidence component shows formatted descriptions
- **WHEN** evidence with markdown description is displayed in the evidence component
- **THEN** the description SHALL be rendered using MarkdownComponent
- **THEN** the rendered output SHALL be wrapped in a div with class "markdown-body"

#### Scenario: Plain text descriptions render correctly
- **WHEN** evidence has a plain text description without markdown syntax
- **THEN** the description SHALL render as regular text without errors
- **THEN** special characters SHALL be escaped and display safely

### Requirement: Form structure prevents nested forms
The evidence form SHALL separate the description field into its own box to prevent nested form elements.

#### Scenario: Main evidence fields in first form
- **WHEN** user is editing evidence
- **THEN** the name, evidence type, and content fields SHALL be in the first form box
- **THEN** this form SHALL use phx-change="update_field" event

#### Scenario: Description field in separate form
- **WHEN** user is editing evidence
- **THEN** the description field SHALL be in a second, separate box below the main form
- **THEN** this box SHALL contain its own independent form
- **THEN** the description form SHALL use phx-change="update_field" event
- **THEN** there SHALL be no nested form elements

#### Scenario: Both forms update state independently
- **WHEN** user types in either the main form or description form
- **THEN** the respective field SHALL update the @changes assign
- **THEN** both forms SHALL trigger the same update_field event handler
- **THEN** changes SHALL be tracked independently for each field

### Requirement: Backward compatibility with existing data
The implementation SHALL maintain full backward compatibility with existing evidence descriptions that contain plain text.

#### Scenario: Existing plain text descriptions display correctly
- **WHEN** evidence created before this change is viewed
- **THEN** plain text descriptions SHALL render without errors
- **THEN** text SHALL display normally even if it contains markdown special characters

#### Scenario: Editing existing evidence preserves description
- **WHEN** user edits evidence created before this change
- **THEN** the existing description SHALL load in the Write tab
- **THEN** user SHALL be able to add markdown formatting
- **THEN** saving SHALL preserve all content

### Requirement: Markdown rendering is safe
The markdown rendering SHALL prevent execution of malicious content and XSS attacks.

#### Scenario: HTML in description is escaped
- **WHEN** user enters raw HTML in the description field
- **THEN** the HTML SHALL be escaped and rendered as text
- **THEN** HTML tags SHALL not execute or render as HTML elements

#### Scenario: JavaScript in description is neutralized
- **WHEN** user enters JavaScript code in the description field
- **THEN** the JavaScript SHALL not execute
- **THEN** the content SHALL render as plain text or code block
