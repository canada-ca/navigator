## 1. Create EvidenceHelpers Module

- [x] 1.1 Create directory `lib/valentine_web/live/workspace_live/evidence/components/`
- [x] 1.2 Create `evidence_helpers.ex` with module definition and @moduledoc
- [x] 1.3 Implement `format_evidence_type(:json_data)` returning "JSON Content"
- [x] 1.4 Implement `format_evidence_type(:blob_store_link)` returning "File Link"
- [x] 1.5 Implement `evidence_type_labels/0` function that generates map from all enum values
- [x] 1.6 Add doctests/examples to the helper functions

## 2. Update FilterComponent

- [x] 2.1 Add `display_label/2` private function that accepts assigns and value
- [x] 2.2 Implement logic to check for optional `labels` parameter in assigns
- [x] 2.3 Update line 50 to call `display_label(assigns, value)` instead of `humanize(value)`
- [x] 2.4 Ensure backward compatibility when `labels` parameter is not provided

## 3. Update Evidence Component

- [x] 3.1 Add `import ValentineWeb.WorkspaceLive.Evidence.Components.EvidenceHelpers` at top of `evidence_component.ex`
- [x] 3.2 Remove the existing `format_evidence_type/3` private function (now imported from helpers)
- [x] 3.3 Verify line 15 still calls `format_evidence_type(@evidence.evidence_type)`

## 4. Update Evidence Show LiveView (Create/Edit Form)

- [x] 4.1 Add `import ValentineWeb.WorkspaceLive.Evidence.Components.EvidenceHelpers` at top of `show.ex`
- [x] 4.2 Update line 47 in `show.html.heex` to use `format_evidence_type(&1)` instead of `Phoenix.Naming.humanize(&1)`
- [x] 4.3 Update line 56 in `show.html.heex` to change `"JSON content"` to `"JSON Content"`
- [x] 4.4 Update line 69 in `show.html.heex` to change `"Blob store URL"` to `"File Link"`

## 5. Update Evidence Index LiveView (Filter)

- [x] 5.1 Add `import ValentineWeb.WorkspaceLive.Evidence.Components.EvidenceHelpers` at top of `index.ex`
- [x] 5.2 Update `index.html.heex` line ~45 to add `labels={evidence_type_labels()}` parameter to FilterComponent

## 6. Update Validation Error Messages

- [x] 6.1 Update line 83 in `lib/valentine/composer/evidence.ex` to reference "JSON Content" instead of "json_data"
- [x] 6.2 Update line 95 in `lib/valentine/composer/evidence.ex` to reference "File Link" instead of "blob_store_link"

## 7. Update Tests

- [x] 7.1 Update `test/valentine_web/live/components/evidence_component_test.exs` assertion to expect "JSON Content" instead of "JSON Data"
- [x] 7.2 Update `test/valentine/composer/evidence_test.exs` line ~86 to expect error message with "JSON Content"
- [x] 7.3 Update `test/valentine/composer/evidence_test.exs` line ~102 to expect error message with "File Link"
- [x] 7.4 Add test to validate all enum values have corresponding format functions in EvidenceHelpers

## 7.5 Implement Error Display Field Name Formatting

- [x] 7.5.1 Add `@evidence_type_labels` module attribute at top of `evidence_helpers.ex` with mapping for `:json_data` and `:blob_store_link`
- [x] 7.5.2 Add `@field_name_labels` module attribute with mapping for `:content` and `:blob_store_url`
- [x] 7.5.3 Refactor `format_evidence_type/1` to use `Map.get(@evidence_type_labels, type, default_format(type))`
- [x] 7.5.4 Create `default_format/1` private helper for fallback formatting
- [x] 7.5.5 Implement `format_field_name/1` function using `Map.get(@field_name_labels, field, Phoenix.Naming.humanize(field))`
- [x] 7.5.6 Update `show.html.heex` line 85 to use `EvidenceHelpers.format_field_name(field)` instead of `Phoenix.Naming.humanize(field)`
- [x] 7.5.7 Add tests in `test/valentine/composer/evidence_test.exs` for `format_field_name/1` with `:content`, `:blob_store_url`, and unknown field
- [x] 7.5.8 Run tests to verify field name formatting works correctly

## 8. Verification

- [x] 8.1 Run all tests to ensure they pass: `mix test`
- [x] 8.2 Start the application and verify evidence type dropdown shows "JSON Content" and "File Link"
- [x] 8.3 Verify form field labels display "JSON Content" and "File Link"
- [x] 8.4 Verify filter dropdown shows "JSON Content" and "File Link"
- [x] 8.5 Verify evidence cards display "JSON Content" and "File Link"
- [x] 8.6 Test validation errors display correct messages with consistent field names (e.g., "File Link must be provided..." not "Blob store url must be provided...")
- [x] 8.7 Verify other FilterComponent uses (threats, mitigations, etc.) still work correctly
