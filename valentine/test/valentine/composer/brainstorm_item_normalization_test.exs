defmodule Valentine.Composer.BrainstormItemNormalizationTest do
  use ExUnit.Case, async: true

  alias Valentine.Composer.BrainstormItem

  describe "text normalization" do
    test "trimming whitespace" do
      cases = [
        {"  hello world  ", "hello world"},
        {"\n\thello world\t\n", "hello world"},
        {"   ", ""},
        {"", ""}
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset = BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: Ecto.UUID.generate(),
          type: :threat,
          raw_text: input
        })
        
        assert changeset.changes.normalized_text == expected
      end)
    end

    test "stripping terminal punctuation" do
      cases = [
        {"Hello world.", "hello world"},
        {"Hello world?", "hello world"},
        {"Hello world!", "hello world"},
        {"Hello world?!?.", "hello world"},
        {"Hello world...", "hello world"},
        {"Hello. world.", "hello. world"},  # Only strips terminal
        {"Hello world", "hello world"},     # No change needed
        {"?!.", ""},                        # Only punctuation
        {"Hello? world!", "hello? world"}   # Only strips terminal
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset = BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: Ecto.UUID.generate(),
          type: :threat,
          raw_text: input
        })
        
        assert changeset.changes.normalized_text == expected
      end)
    end

    test "lowercase first character only" do
      cases = [
        {"Hello World", "hello World"},
        {"HELLO WORLD", "hELLO WORLD"},
        {"hello world", "hello world"},
        {"A", "a"},
        {"a", "a"},
        {"1Hello", "1Hello"},  # Numbers unchanged
        {"", ""}
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset = BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: Ecto.UUID.generate(),
          type: :threat,
          raw_text: input
        })
        
        assert changeset.changes.normalized_text == expected
      end)
    end

    test "collapsing multiple internal spaces" do
      cases = [
        {"hello  world", "hello world"},
        {"hello   world   test", "hello world test"},
        {"hello\tworld", "hello world"},
        {"hello\nworld", "hello world"},
        {"hello\r\nworld", "hello world"},
        {"hello  \t  \n  world", "hello world"},
        {"hello world", "hello world"}  # No change needed
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset = BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: Ecto.UUID.generate(),
          type: :threat,
          raw_text: input
        })
        
        assert changeset.changes.normalized_text == expected
      end)
    end

    test "comprehensive normalization" do
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
        changeset = BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: Ecto.UUID.generate(),
          type: :threat,
          raw_text: input
        })
        
        assert changeset.changes.normalized_text == expected
      end)
    end

    test "idempotency - normalizing already normalized text" do
      input = "a properly formatted threat statement"
      
      changeset = BrainstormItem.changeset(%BrainstormItem{}, %{
        workspace_id: Ecto.UUID.generate(),
        type: :threat,
        raw_text: input
      })
      
      normalized = changeset.changes.normalized_text
      assert normalized == input
      
      # Normalize again
      changeset2 = BrainstormItem.changeset(%BrainstormItem{}, %{
        workspace_id: Ecto.UUID.generate(),
        type: :threat,
        raw_text: normalized
      })
      
      assert changeset2.changes.normalized_text == normalized
    end

    test "edge cases" do
      cases = [
        {"", ""},                              # Empty string
        {" ", ""},                             # Only whitespace
        {".", ""},                             # Only punctuation
        {"   . ? !   ", ""},                   # Whitespace and punctuation
        {"A.", "a"},                           # Single char with punctuation
        {"123", "123"},                        # Numbers only
        {"!@#$%^&*()", "!@#$%^&*()"},         # Special chars (not terminal punct)
        {"Hello!@#$%World", "hello!@#$%World"}, # Mixed special chars
        {"Café", "café"},                      # Unicode
        {"文字", "文字"}                        # Non-latin scripts
      ]

      Enum.each(cases, fn {input, expected} ->
        changeset = BrainstormItem.changeset(%BrainstormItem{}, %{
          workspace_id: Ecto.UUID.generate(),
          type: :threat,
          raw_text: input
        })
        
        assert changeset.changes.normalized_text == expected
      end)
    end
  end
end