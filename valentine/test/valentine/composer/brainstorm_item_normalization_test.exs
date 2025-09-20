defmodule Valentine.Composer.BrainstormItemNormalizationTest do
  use Valentine.DataCase, async: false

  import Valentine.ComposerFixtures
  alias Valentine.Composer.BrainstormItem

  describe "text normalization" do
    test "trimming whitespace" do
      workspace = workspace_fixture()

      cases = [
        {"  hello world  ", "hello world"},
        {"\n\thello world\t\n", "hello world"},
        {"   ", ""},
        {"", ""}
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        assert changeset.changes.normalized_text == expected
      end)
    end

    test "stripping terminal punctuation" do
      workspace = workspace_fixture()

      cases = [
        {"Hello world.", "hello world"},
        {"Hello world?", "hello world"},
        {"Hello world!", "hello world"},
        {"Hello world?!?.", "hello world"},
        {"Hello world...", "hello world"},
        # Only strips terminal
        {"Hello. world.", "hello. world"},
        # No change needed
        {"Hello world", "hello world"},
        # Only punctuation
        {"?!.", ""},
        # Only strips terminal
        {"Hello? world!", "hello? world"}
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        assert changeset.changes.normalized_text == expected
      end)
    end

    test "lowercase first character only" do
      workspace = workspace_fixture()

      cases = [
        {"Hello World", "hello World"},
        {"HELLO WORLD", "hELLO WORLD"},
        {"hello world", "hello world"},
        {"A", "a"},
        {"a", "a"},
        # Numbers unchanged
        {"1Hello", "1Hello"},
        {"", ""}
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        assert changeset.changes.normalized_text == expected
      end)
    end

    test "collapsing multiple internal spaces" do
      workspace = workspace_fixture()

      cases = [
        {"hello  world", "hello world"},
        {"hello   world   test", "hello world test"},
        {"hello\tworld", "hello world"},
        {"hello\nworld", "hello world"},
        {"hello\r\nworld", "hello world"},
        {"hello  \t  \n  world", "hello world"},
        # No change needed
        {"hello world", "hello world"}
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        assert changeset.changes.normalized_text == expected
      end)
    end

    test "comprehensive normalization" do
      workspace = workspace_fixture()

      # Test all rules together
      cases = [
        {
          "  A Malicious   User Could Exploit   SQL Injection!!! ",
          "a Malicious User Could Exploit SQL Injection"
        },
        {
          "\t\nSTRIDE ANALYSIS: \t\tThreat Assessment.\n\n",
          "sTRIDE ANALYSIS: Threat Assessment"
        },
        {
          "   AN   ATTACKER   WHO   GAINS   ACCESS...???   ",
          "aN ATTACKER WHO GAINS ACCESS"
        },
        {
          "Multiple.punctuation?!?!.here!",
          "multiple.punctuation?!?!.here"
        }
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        assert changeset.changes.normalized_text == expected
      end)
    end

    test "idempotency - normalizing already normalized text" do
      workspace = workspace_fixture()
      input = "a properly formatted threat statement"

      changeset =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: input
        })

      normalized = changeset.changes.normalized_text
      assert normalized == input

      # Normalize again
      changeset2 =
        BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: normalized
        })

      assert changeset2.changes.normalized_text == normalized
    end

    test "edge cases" do
      workspace = workspace_fixture()

      cases = [
        # Empty string
        {"", ""},
        # Only whitespace
        {" ", ""},
        # Only punctuation
        {".", ""},
        # Whitespace and punctuation
        {"   . ? !   ", ""},
        # Single char with punctuation
        {"A.", "a"},
        # Numbers only
        {"123", "123"},
        # Special chars (not terminal punct)
        {"!@#$%^&*()", "!@#$%^&*()"},
        # Mixed special chars
        {"Hello!@#$%World", "hello!@#$%World"},
        # Unicode
        {"Café", "café"},
        # Non-latin scripts
        {"文字", "文字"}
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        assert changeset.changes.normalized_text == expected
      end)
    end
  end
end
