defmodule ValentineWeb.WorkspaceLive.Evidence.Components.EvidenceHelpersTest do
  use ExUnit.Case, async: true
  alias ValentineWeb.WorkspaceLive.Evidence.Components.EvidenceHelpers
  alias Valentine.Composer.Evidence

  describe "format_evidence_type/1" do
    test "all evidence type enum values have corresponding format functions" do
      # Get all enum values from the schema
      enum_values = Ecto.Enum.values(Evidence, :evidence_type)

      # Verify each enum value has a format function
      for value <- enum_values do
        # Should not raise an error
        formatted = EvidenceHelpers.format_evidence_type(value)
        # Should return a non-empty string
        assert is_binary(formatted)
        assert String.length(formatted) > 0
      end
    end
  end

  describe "format_field_name/1" do
    test "returns standardized name for content field" do
      assert EvidenceHelpers.format_field_name(:content) == "JSON Content (OSCAL)"
    end

    test "returns standardized name for blob_store_url field" do
      assert EvidenceHelpers.format_field_name(:blob_store_url) == "File Link"
    end

    test "falls back to humanize for unknown fields" do
      # Test with a generic field name
      assert EvidenceHelpers.format_field_name(:name) == "Name"
      assert EvidenceHelpers.format_field_name(:description) == "Description"
      assert EvidenceHelpers.format_field_name(:workspace_id) == "Workspace"
    end
  end
end
