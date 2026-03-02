## 1. Update LiveView Backend

- [x] 1.1 Add default `evidence_type: :json_data` to changes map in `apply_action(socket, :new, _params)` function (line 32 in show.ex)

## 2. Update Template - Fix Textarea Width

- [x] 2.1 Add `is_full_width` attribute to Description textarea component (line 35-41 in show.html.heex)
- [x] 2.2 Remove `class="form-control"` from Description textarea (line 39 in show.html.heex)
- [x] 2.3 Add `is_full_width` attribute to JSON content textarea component (line 65-71 in show.html.heex)
- [x] 2.4 Remove `class="form-control"` from JSON content textarea (line 69 in show.html.heex)

## 3. Update Template - Standardize Label Styling

- [x] 3.1 Replace `<label>` tag with `<h3>` for Name field label (lines 20-22 in show.html.heex)
- [x] 3.2 Replace `<label>` tag with `<h3>` for Description field label (lines 32-34 in show.html.heex)
- [x] 3.3 Replace `<label>` tag with `<h3>` for Evidence type field label (lines 45-47 in show.html.heex)
- [x] 3.4 Remove `for` attributes from the new h3 headings (they're not needed for h3 elements)

## 4. Manual Testing

- [ ] 4.1 Test creating new evidence - verify JSON content field appears by default
- [ ] 4.2 Test switching evidence type - verify Blob store URL field appears when selected
- [ ] 4.3 Verify all form fields are aligned and full-width
- [ ] 4.4 Verify label/heading styling is consistent across all sections
- [ ] 4.5 Test editing existing evidence - verify form displays correctly with existing data
