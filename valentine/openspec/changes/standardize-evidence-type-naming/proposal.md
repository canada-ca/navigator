## Why

Evidence type options are currently displayed inconsistently across the application. The form dropdown shows "Json data" and "Blob store link" (using generic humanization), the filter dropdown shows similar generic formatting, display cards show "JSON Data" and "File Link", and validation error messages reference the raw enum values "json_data" and "blob_store_link". This creates a confusing user experience where the same concept is referred to with different names throughout the interface.

## What Changes

- Standardize all evidence type displays to consistently use "JSON Content" and "File Link"
- Update form field labels to match standardized evidence type names: "JSON Content" (not "JSON content") and "File Link" (not "Blob store URL")
- Standardize field name formatting in validation error messages to use consistent terminology (e.g., "JSON Content" instead of "Content", "File Link" instead of "Blob store url")
- Create a shared `EvidenceHelpers` module following the established pattern (like `ThreatHelpers`) to centralize formatting logic and eliminate code duplication
- Enhance `FilterComponent` with an optional `labels` parameter to support custom display names while maintaining its generic, reusable nature
- Update validation error messages to reference the standardized user-friendly names instead of technical enum values
- Update all affected templates, LiveViews, and components to use the centralized helper functions

## Capabilities

### New Capabilities
- `evidence-type-formatting`: Centralized helper functions for formatting evidence type enum values into consistent user-friendly display strings across all UI contexts
- `filter-component-custom-labels`: Optional labels parameter for FilterComponent allowing parent components to provide custom display names while keeping the component generic and reusable

### Modified Capabilities

(No existing capabilities are being modified - this change only affects display/presentation layer)

## Impact

**Affected Components:**
- `lib/valentine_web/live/workspace_live/components/evidence_component.ex` - Display cards
- `lib/valentine_web/live/workspace_live/evidence/show.ex` - Create/edit form LiveView
- `lib/valentine_web/live/workspace_live/evidence/show.html.heex` - Form template and error display
- `lib/valentine_web/live/workspace_live/evidence/index.ex` - Index page LiveView
- `lib/valentine_web/live/workspace_live/evidence/index.html.heex` - Filter template
- `lib/valentine_web/live/workspace_live/components/filter_component.ex` - Generic filter component
- `lib/valentine/composer/evidence.ex` - Validation error messages

**New Files:**
- `lib/valentine_web/live/workspace_live/evidence/components/evidence_helpers.ex` - Shared helper module

**Test Files:**
- `test/valentine_web/live/components/evidence_component_test.exs`
- `test/valentine/composer/evidence_test.exs`

**What's NOT Impacted:**
- Database schema (enum values `:json_data` and `:blob_store_link` remain unchanged)
- API contracts (enum values in JSON payloads remain unchanged)
- Existing data (no migration needed)
- Other uses of FilterComponent (enhancement is backward compatible via optional parameter)
