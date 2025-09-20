defmodule Valentine.Composer.BrainstormItemPropertyTest do
  use Valentine.DataCase, async: false

  import Valentine.ComposerFixtures
  alias Valentine.Composer.BrainstormItem

  # Property-based test for normalization idempotency
  describe "normalization properties" do
    test "normalization is idempotent" do
      workspace = workspace_fixture()

      test_cases = [
        "Hello World!",
        "  Multiple   Spaces   Here  ",
        "UPPERCASE TEXT.",
        "mixed CASE text?",
        "   Leading and trailing   ",
        "!!!Punctuation???",
        "Single char: A.",
        "",
        "   ",
        "Already normalized text",
        "café unicode",
        "123 numbers only",
        "Special !@#$% chars"
      ]

      Enum.each(test_cases, fn raw_text ->
        # First normalization
        changeset1 =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: raw_text
          })

        normalized1 = changeset1.changes.normalized_text

        # Second normalization on already normalized text
        changeset2 =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: normalized1
          })

        normalized2 = changeset2.changes.normalized_text

        # Should be the same (idempotent)
        assert normalized1 == normalized2,
               "Normalization not idempotent for: #{inspect(raw_text)} -> #{inspect(normalized1)} -> #{inspect(normalized2)}"
      end)
    end

    test "normalization handles all whitespace types" do
      workspace = workspace_fixture()

      whitespace_variants = [
        # tab
        "hello\tworld",
        # newline  
        "hello\nworld",
        # carriage return
        "hello\rworld",
        # CRLF
        "hello\r\nworld",
        # non-breaking space
        "hello\u00A0world",
        # em space
        "hello\u2003world",
        # regular space
        "hello world"
      ]

      Enum.each(whitespace_variants, fn text ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: text
          })

        normalized = changeset.changes.normalized_text

        # All should collapse to single space
        assert String.contains?(normalized, " "),
               "Failed to normalize whitespace in: #{inspect(text)} -> #{inspect(normalized)}"

        # Should not contain original whitespace characters
        refute String.contains?(normalized, "\t")
        refute String.contains?(normalized, "\n")
        refute String.contains?(normalized, "\r")
      end)
    end

    test "normalization preserves word boundaries" do
      workspace = workspace_fixture()

      test_cases = [
        {"hello world", "hello world"},
        {"hello  world", "hello world"},
        {"hello\tworld", "hello world"},
        {"   hello   world   ", "hello world"},
        {"hello\n\nworld", "hello world"}
      ]

      Enum.each(test_cases, fn {input, expected_words} ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        normalized = changeset.changes.normalized_text
        words = String.split(normalized, " ", trim: true)
        expected_word_list = String.split(expected_words, " ", trim: true)

        assert words == expected_word_list,
               "Word boundaries not preserved: #{inspect(input)} -> #{inspect(normalized)}"
      end)
    end

    test "first character lowercasing works with unicode" do
      workspace = workspace_fixture()

      test_cases = [
        {"Café", "café"},
        {"ÉCLAIR", "éCLAIR"},
        {"Москва", "москва"},
        # Should remain unchanged for non-latin
        {"北京", "北京"},
        {"Åpple", "åpple"},
        {"Ñoño", "ñoño"}
      ]

      Enum.each(test_cases, fn {input, expected} ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        normalized = changeset.changes.normalized_text

        assert String.starts_with?(normalized, String.slice(expected, 0, 1)),
               "Unicode first char lowercasing failed: #{inspect(input)} -> #{inspect(normalized)}, expected to start with #{inspect(String.slice(expected, 0, 1))}"
      end)
    end

    test "terminal punctuation stripping is precise" do
      workspace = workspace_fixture()

      test_cases = [
        {"Hello.", "hello"},
        {"Hello?", "hello"},
        {"Hello!", "hello"},
        {"Hello...", "hello"},
        {"Hello?!?", "hello"},
        # Only strips terminal
        {"Hello. World.", "hello. World"},
        # Preserves internal periods
        {"Dr. Smith", "dr. Smith"},
        # Only strips terminal
        {"What? Really!", "what? Really"},
        {"", ""},
        {"...", ""},
        {"!?.", ""}
      ]

      Enum.each(test_cases, fn {input, expected} ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        normalized = changeset.changes.normalized_text

        assert normalized == expected,
               "Terminal punctuation stripping failed: #{inspect(input)} -> #{inspect(normalized)}, expected #{inspect(expected)}"
      end)
    end

    test "normalization never increases text length unreasonably" do
      workspace = workspace_fixture()

      # Test that normalization doesn't accidentally expand text
      test_inputs = [
        String.duplicate("Hello World! ", 100),
        String.duplicate(" \t\n", 50) <> "Text" <> String.duplicate(" \t\n", 50),
        String.duplicate("A", 1000) <> "...",
        "Short text."
      ]

      Enum.each(test_inputs, fn input ->
        changeset =
          BrainstormItem.changeset(%BrainstormItem{}, %{
            workspace_id: workspace.id,
            type: :threat,
            raw_text: input
          })

        normalized = changeset.changes.normalized_text

        # Normalized should never be longer than trimmed input
        trimmed_input = String.trim(input)

        assert String.length(normalized) <= String.length(trimmed_input),
               "Normalization increased length: #{String.length(input)} -> #{String.length(normalized)}"
      end)
    end
  end
end
