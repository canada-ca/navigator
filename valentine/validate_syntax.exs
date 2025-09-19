#!/usr/bin/env elixir

# Simple syntax validation for our Elixir files
# This script checks that our modules can be parsed without compilation

files_to_check = [
  "lib/valentine/composer/brainstorm_item.ex",
  "lib/valentine/composer/brainstorm_items.ex",
  "priv/repo/migrations/20250919190137_create_brainstorm_items.exs",
  "test/valentine/composer/brainstorm_item_test.exs",
  "test/valentine/composer/brainstorm_items_test.exs",
  "test/valentine/composer/brainstorm_item_normalization_test.exs"
]

IO.puts("Validating syntax for brainstorm board implementation files...")

all_valid = Enum.all?(files_to_check, fn file ->
  path = Path.join([__DIR__, file])
  
  if File.exists?(path) do
    try do
      content = File.read!(path)
      Code.string_to_quoted!(content)
      IO.puts("✓ #{file} - syntax valid")
      true
    rescue
      e ->
        IO.puts("✗ #{file} - syntax error: #{Exception.message(e)}")
        false
    end
  else
    IO.puts("✗ #{file} - file not found")
    false
  end
end)

if all_valid do
  IO.puts("\n✅ All files have valid Elixir syntax!")
  System.halt(0)
else
  IO.puts("\n❌ Some files have syntax errors!")
  System.halt(1)
end