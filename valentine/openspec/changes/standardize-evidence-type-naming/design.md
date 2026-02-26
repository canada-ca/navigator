## Context

Evidence types are represented in the database and code as enum atoms (`:json_data`, `:blob_store_link`) but need to be displayed to users with friendly names. Currently, these display names are generated inconsistently across the application using different approaches:

- **Evidence cards**: Use `format_evidence_type/1` function returning "JSON Data" and "File Link"
- **Form dropdowns**: Use `Phoenix.Naming.humanize/1` returning "Json data" and "Blob store link"
- **Filter dropdowns**: Use custom `humanize/1` in FilterComponent returning "Json data" and "Blob store link"
- **Validation errors**: Reference raw enum values "json_data" and "blob_store_link"
- **Error display field names**: Use `Phoenix.Naming.humanize/1` on field atoms, resulting in inconsistent names like "Blob store url" appearing alongside standardized evidence type names like "File Link" in the same error message

The codebase has an established pattern for domain-specific helpers (e.g., `ThreatHelpers` module in `lib/valentine_web/live/workspace_live/threat/components/threat_helpers.ex`) that can be imported and reused across multiple modules.

FilterComponent is a generic, reusable component used across multiple entity types (evidence, threats, mitigations, controls, assumptions) and relies on internal logic to convert values to display strings.

## Goals / Non-Goals

**Goals:**
- Standardize all evidence type displays to "JSON Content" and "File Link"
- Standardize field name formatting in validation error messages to match evidence terminology
- Create a single source of truth for evidence type formatting logic
- Follow established codebase patterns (helper modules like ThreatHelpers)
- Maintain FilterComponent's generic, reusable nature
- Ensure validation error messages reference user-friendly names

**Non-Goals:**
- Change database enum values (`:json_data`, `:blob_store_link` remain unchanged)
- Modify API contracts or JSON payloads
- Require database migration
- Break existing uses of FilterComponent with other entity types
- Add domain-specific logic to generic components

## Decisions

### Decision 1: Create EvidenceHelpers Module

**Choice**: Create `lib/valentine_web/live/workspace_live/evidence/components/evidence_helpers.ex` following the ThreatHelpers pattern.

**Rationale**:
- **Centralization**: Single source of truth for evidence type formatting eliminates code duplication
- **Consistency**: Following established patterns (ThreatHelpers) makes the codebase more maintainable
- **Reusability**: Can be imported by any module that needs to format evidence types
- **Discoverability**: Lives in the evidence domain namespace where developers expect to find it

**Alternatives Considered**:
- *Duplicate logic in each component*: Rejected due to maintenance burden and risk of inconsistency
- *Add to existing shared helpers*: Rejected as evidence-specific logic should live in evidence namespace
- *Use a protocol*: Rejected as overkill for simple display formatting

### Decision 2: FilterComponent Enhancement with Optional Labels Parameter

**Choice**: Add an optional `labels` parameter (map of `%{value => display_string}`) to FilterComponent that takes precedence over the default `humanize/1` function.

**Rationale**:
- **Preserves Genericity**: FilterComponent remains domain-agnostic; no evidence-specific code added
- **Backward Compatible**: Optional parameter means existing uses continue working unchanged
- **Flexible**: Any parent component can provide custom labels for any value type
- **Clean Architecture**: Keeps domain-specific display logic in domain modules, not generic components

**Alternatives Considered**:
- *Modify FilterComponent's humanize/1 with special cases*: Rejected as it couples a generic component to specific domain logic
- *Pass formatted strings as values*: Rejected as FilterComponent needs actual enum values for filtering logic (converts strings back to atoms via `String.to_existing_atom/1`)
- *Create evidence-specific filter component*: Rejected as unnecessary duplication

**Implementation Details**:
```elixir
# FilterComponent receives optional labels map
defp display_label(assigns, value) do
  case Map.get(assigns, :labels) do
    nil -> humanize(value)  # Default behavior
    labels when is_map(labels) -> Map.get(labels, value, humanize(value))
  end
end
```

### Decision 3: Helper Function Structure

**Choice**: Provide two functions in EvidenceHelpers:
1. `format_evidence_type/1` - Takes atom, returns display string
2. `evidence_type_labels/0` - Returns map of all enum values to display strings

**Rationale**:
- `format_evidence_type/1`: Used in templates and display logic where individual formatting is needed
- `evidence_type_labels/0`: Convenient for passing to FilterComponent, automatically generates map from all enum values

**Implementation**:
```elixir
def format_evidence_type(:json_data), do: "JSON Content"
def format_evidence_type(:blob_store_link), do: "File Link"

def evidence_type_labels do
  Valentine.Composer.Evidence
  |> Ecto.Enum.values(:evidence_type)
  |> Map.new(fn type -> {type, format_evidence_type(type)} end)
end
```

### Decision 4: Validation Error Message Updates

**Choice**: Update error messages in `lib/valentine/composer/evidence.ex` to reference "JSON Content" and "File Link" instead of enum values.

**Rationale**:
- Users see these error messages and should see the same terminology used throughout the UI
- Error messages like "Content must be provided when evidence_type is JSON Content" are more user-friendly than "...when evidence_type is json_data"

**Example**:
```elixir
# Before
add_error(changeset, :content, "must be provided when evidence_type is json_data")

# After
add_error(changeset, :content, "must be provided when evidence_type is JSON Content")
```

### Decision 5: Form Field Label Alignment

**Choice**: Update form field labels to exactly match the standardized evidence type names ("JSON Content" and "File Link").

**Rationale**:
- **Consistency**: When a user selects "JSON Content" from the dropdown, seeing a field labeled "JSON Content" below creates cognitive alignment
- **Clarity**: "File Link" is clearer than "Blob store URL" for users who don't need to know the technical implementation detail
- **User Experience**: Reduces mental translation between evidence type concept and field purpose
- **Professional Polish**: "JSON Content" (capitalized) is more polished than "JSON content"

**Implementation**:
```elixir
# Before
<h3>{gettext("JSON content")}</h3>  # Line 56
<h3>{gettext("Blob store URL")}</h3>  # Line 69

# After
<h3>{gettext("JSON Content")}</h3>
<h3>{gettext("File Link")}</h3>
```

**Impact**: Two `gettext()` strings in show.html.heex

### Decision 6: Import Strategy

**Choice**: Use `import ValentineWeb.WorkspaceLive.Evidence.Components.EvidenceHelpers` in modules that need evidence type formatting.

**Rationale**:
- Makes functions available without module prefix for cleaner template code
- Consistent with how other helpers are used in the codebase
- Clear dependency relationship

### Decision 7: Error Display Field Name Formatting

**Choice**: Create shared module attributes in EvidenceHelpers for both evidence types AND field names, providing explicit mappings for consistent terminology across all display contexts.

**Implementation**:
```elixir
# Module attributes at top of EvidenceHelpers
@evidence_type_labels %{
  json_data: "JSON Content",
  blob_store_link: "File Link"
}

@field_name_labels %{
  content: "JSON Content",
  blob_store_url: "File Link"
}

# Refactor format_evidence_type/1 to use module attribute
def format_evidence_type(type) when is_atom(type) do
  Map.get(@evidence_type_labels, type, default_format(type))
end

# New function for field name formatting
def format_field_name(field) when is_atom(field) do
  Map.get(@field_name_labels, field, Phoenix.Naming.humanize(field))
end
```

**Usage in template** (`show.html.heex` line 85):
```elixir
# Before
<li>{"#{Phoenix.Naming.humanize(field)} #{elem(error, 0)}"}</li>

# After
<li>{"#{EvidenceHelpers.format_field_name(field)} #{elem(error, 0)}"}</li>
```

**Rationale**:
- **Single Source of Truth**: Both evidence type labels and field name labels are defined together in module attributes, making it clear they represent the same concepts
- **Consistency**: "JSON Content" and "File Link" are defined once and reused for both evidence type display and field name display
- **Explicit and Clear**: The mappings are immediately visible at the top of the module, making the relationship obvious
- **Maintainable**: When adding new evidence types, developers see both mappings together and can update them in sync
- **Backward Compatible**: Falls back to `Phoenix.Naming.humanize/1` for any field not in the explicit mapping

**Alternatives Considered**:
- *Reuse `format_evidence_type/1` with conditional logic*: Rejected as it conflates two different concepts (evidence types vs. field names) even though they happen to have matching labels
- *Derive field names from evidence types programmatically*: Rejected as it couples field naming to type naming in a fragile way (e.g., `:blob_store_url` → `:blob_store_link` requires complex mapping logic)
- *Context-aware formatting function*: Rejected as unnecessarily complex; separate functions with shared data source is clearer

**Impact**:
- One new function: `format_field_name/1`
- Refactor existing function: `format_evidence_type/1` to use module attribute
- Update one template line: `show.html.heex` line 85
- Update one test file: `test/valentine/composer/evidence_test.exs`

**Example Error Message Transformation**:
```
Before: "Blob store url must be provided when evidence_type is File Link"
After:  "File Link must be provided when evidence_type is File Link"
```

## Risks / Trade-offs

**[Risk]** If new evidence types are added to the enum, developers must remember to add corresponding clauses to `format_evidence_type/1`  
**→ Mitigation**: Add a test that validates all enum values have corresponding format functions; add doctests/examples in EvidenceHelpers

**[Risk]** Field name labels and evidence type labels could fall out of sync if new types are added  
**→ Mitigation**: Both mappings are defined together in module attributes at the top of EvidenceHelpers, making their relationship immediately visible; comprehensive test coverage validates all mappings

**[Risk]** FilterComponent's optional labels parameter increases API surface area  
**→ Mitigation**: Parameter is optional and well-documented; backward compatibility maintained; clear use case demonstrated in evidence index

**[Risk]** Templates calling `format_evidence_type/1` will fail at runtime if import is missing  
**→ Mitigation**: Elixir compiler catches undefined function errors; clear error messages guide developers to add import

**[Trade-off]** Validation error messages now contain display strings instead of technical values, which may be less precise for debugging  
**→ Accepted**: User experience takes priority; developers can still see enum values in logs and database queries

**[Trade-off]** Adding a new directory (`evidence/components/`) for a single file  
**→ Accepted**: Follows established pattern (threat/components/), leaves room for future evidence-specific components, maintains consistent structure

## Migration Plan

**Deployment Steps**:
1. Create `evidence_helpers.ex` with formatting functions
2. Update FilterComponent to support optional labels parameter
3. Update all evidence-related modules to import and use EvidenceHelpers
4. Update form field labels in show.html.heex
5. Update validation error messages in Evidence schema
6. Update test assertions to match new display names
7. Deploy (no database migration needed, all changes are code-only)

**Rollback Strategy**:
- Pure code change with no data migration, can be rolled back via standard deployment rollback
- No API contract changes, so no coordination needed with external systems
- If issues arise, revert commit and redeploy previous version

**Testing Strategy**:
- Unit tests for EvidenceHelpers functions
- Update existing component tests to assert new display strings
- Update schema validation tests to assert new error messages
- Manual verification of UI displays in form, filter, and card views

**Open Questions**:

None - design is straightforward display layer change with clear implementation path.
