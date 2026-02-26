## 1. Refactor Evidence Form Structure

- [x] 1.1 Open `lib/valentine_web/live/workspace_live/evidence/show.html.heex` and locate the description field (lines 29-38)
- [x] 1.2 Remove the description field block from the main form (delete lines 29-38)
- [x] 1.3 Verify the main form still contains: name, evidence_type, content_raw, and blob_store_url fields
- [x] 1.4 Verify the form closing tag and error display block remain intact

## 2. Add Description Box with Markdown Support

- [x] 2.1 After the closing `</.box>` tag of the main form (line 90), add a new `<.box class="p-4 mt-2">` element
- [x] 2.2 Add heading `<h3>{gettext("Description")}</h3>` inside the new box
- [x] 2.3 Add `<.live_component>` for TabNavComponent with id "tabs-component-evidence-description"
- [x] 2.4 Configure tabs array with Write (tab1) and Preview (tab2) using gettext for labels
- [x] 2.5 Add `:tab_content` slot with `case` statement to handle tab switching
- [x] 2.6 In "tab1" branch: add `<form phx-change="update_field">` wrapper
- [x] 2.7 Add `.textarea` component with name="description", rows="7", placeholder "Describe this evidence...", and caption "Markdown is supported"
- [x] 2.8 In "tab2" branch: add `<div class="markdown-body">` wrapper
- [x] 2.9 Add `<ValentineWeb.WorkspaceLive.Components.MarkdownComponent.render text={@changes[:description]} />` for preview
- [x] 2.10 Close all tags properly (form, tab_content, live_component, box)

## 3. Update Evidence Component for Markdown Rendering

- [x] 3.1 Open `lib/valentine_web/live/workspace_live/components/evidence_component.ex`
- [x] 3.2 Locate the description display code (lines 24-26)
- [x] 3.3 Replace the `<p>` tag with `<div>` tag, keeping the `:if={@evidence.description}` conditional
- [x] 3.4 Add nested `<div class="markdown-body">` wrapper inside the outer div
- [x] 3.5 Replace `{@evidence.description}` with `<ValentineWeb.WorkspaceLive.Components.MarkdownComponent.render text={@evidence.description} />`
- [x] 3.6 Verify the class "f5 color-fg-muted mb-2" remains on the outer div

## 4. Manual Testing

- [ ] 4.1 Start the development server and navigate to evidence create page
- [ ] 4.2 Verify the main form contains: Name, Evidence type, and conditional JSON/Blob fields
- [ ] 4.3 Verify the Description box appears as a separate section below the main form
- [ ] 4.4 Verify Write and Preview tabs are visible in the description box
- [ ] 4.5 Type markdown text in Write tab (e.g., "**Bold** and *italic*")
- [ ] 4.6 Switch to Preview tab and verify markdown is rendered as formatted HTML
- [ ] 4.7 Switch back to Write tab and verify text is preserved
- [ ] 4.8 Fill in required fields (Name, Evidence type) and save the evidence
- [ ] 4.9 Verify the evidence saves successfully and redirects to the evidence list
- [ ] 4.10 Verify the description appears with rendered markdown in the evidence list
- [ ] 4.11 Click to edit the evidence and verify the markdown loads in the Write tab
- [ ] 4.12 Test with empty description - verify it saves and displays correctly
- [ ] 4.13 Test editing an existing evidence with plain text description - verify it loads and displays correctly
- [ ] 4.14 Test with special characters (e.g., `<script>alert('xss')</script>`) and verify they are escaped

## 5. Edge Case Testing

- [ ] 5.1 Test creating evidence with very long markdown content (1000+ characters)
- [ ] 5.2 Test markdown with all common elements: headings, bold, italic, lists, links, code blocks
- [ ] 5.3 Test with markdown special characters in plain text (e.g., "Price: $5 * 2 = $10")
- [ ] 5.4 Test rapid switching between Write/Preview tabs
- [ ] 5.5 Test typing in Write tab and verifying live preview updates when switching tabs
- [ ] 5.6 Verify both forms (main + description) trigger updates independently
- [ ] 5.7 Test browser back button behavior after saving evidence
- [ ] 5.8 Test with browser dev tools - verify no nested form warnings or errors

## 6. Verification

- [ ] 6.1 Verify no console errors appear in browser dev tools
- [x] 6.2 Verify no Elixir compilation warnings
- [ ] 6.3 Verify the layout matches the threats comments pattern visually
- [ ] 6.4 Verify the description box appears in col-8 (left column) with proper spacing
- [ ] 6.5 Verify the NIST Controls and Tags sidebar (col-3) remains unchanged and functional
- [ ] 6.6 Compare with threats page comments section to ensure visual consistency
