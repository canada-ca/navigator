defmodule ValentineWeb.Helpers.DisplayHelperTest do
  use ExUnit.Case, async: true

  alias ValentineWeb.Helpers.DisplayHelper

  describe "indefinite_article/2" do
    test "returns lowercase article for consonants and vowels" do
      assert DisplayHelper.indefinite_article("word") == "a"
      assert DisplayHelper.indefinite_article("apple") == "an"
    end

    test "returns capitalized article when requested" do
      assert DisplayHelper.indefinite_article("word", true) == "A"
      assert DisplayHelper.indefinite_article("apple", true) == "An"
    end

    test "falls back to a/A for nil and empty input" do
      assert DisplayHelper.indefinite_article(nil) == "a"
      assert DisplayHelper.indefinite_article("", true) == "A"
    end
  end

  describe "join_display_list/2" do
    test "supports nil, empty, and singleton values" do
      assert DisplayHelper.join_display_list(nil) == ""
      assert DisplayHelper.join_display_list([]) == ""
      assert DisplayHelper.join_display_list(["item"]) == "item"
    end

    test "joins two items without an Oxford comma" do
      assert DisplayHelper.join_display_list(["item1", "item2"]) == "item1 and item2"
      assert DisplayHelper.join_display_list(["item1", "item2"], "or") == "item1 or item2"
    end

    test "joins multiple items with an Oxford comma" do
      assert DisplayHelper.join_display_list(["item1", "item2", "item3"]) ==
               "item1, item2, and item3"

      assert DisplayHelper.join_display_list(["item1", "item2", "item3"], "or") ==
               "item1, item2, or item3"
    end
  end

  describe "enum_label/1" do
    test "humanizes atoms and enum-like strings" do
      assert DisplayHelper.enum_label(:information_disclosure) == "Information disclosure"
      assert DisplayHelper.enum_label("timed_out") == "Timed out"
      assert DisplayHelper.enum_label("queued") == "Queued"
    end
  end

  describe "display_label/2" do
    test "uses feature-specific labels when provided" do
      assert DisplayHelper.display_label(:json_data, %{json_data: "JSON Content (OSCAL)"}) ==
               "JSON Content (OSCAL)"
    end

    test "falls back to shared formatting for atoms" do
      assert DisplayHelper.display_label(:workspace_id) == "Workspace"
    end

    test "preserves plain binary labels while humanizing underscore strings" do
      assert DisplayHelper.display_label("Contractor Insider") == "Contractor Insider"
      assert DisplayHelper.display_label("timed_out") == "Timed out"
    end
  end

  describe "repo_analysis_status_label/1" do
    test "matches enum labeling for repo analysis statuses" do
      assert DisplayHelper.repo_analysis_status_label(:completed) == "Completed"
      assert DisplayHelper.repo_analysis_status_label(:timed_out) == "Timed out"
    end
  end
end
