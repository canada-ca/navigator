defmodule ValentineWeb.WorkspaceLive.Evidence.Components.EvidenceHelpers do
  @moduledoc """
  Helper functions for formatting and displaying evidence-related data.

  This module provides centralized formatting for evidence type enum values,
  ensuring consistent display strings across all UI contexts including forms,
  filters, cards, and validation messages.
  """

  # Module attributes defining standardized display labels
  @evidence_type_labels %{
    description_only: "Description Only",
    json_data: "JSON Content (OSCAL)",
    blob_store_link: "File Link"
  }

  @field_name_labels %{
    content: "JSON Content (OSCAL)",
    blob_store_url: "File Link"
  }

  @doc """
  Formats an evidence type enum value into a user-friendly display string.

  ## Examples

      iex> format_evidence_type(:json_data)
      "JSON Content (OSCAL)"

      iex> format_evidence_type(:blob_store_link)
      "File Link"

      iex> format_evidence_type(:description_only)
      "Description Only"

  """
  def format_evidence_type(type) when is_atom(type) do
    Map.get(@evidence_type_labels, type, default_format(type))
  end

  @doc """
  Formats an evidence field name into a user-friendly display string.

  This is used primarily in error messages to maintain consistent terminology
  with evidence type names.

  ## Examples

      iex> format_field_name(:content)
      "JSON Content (OSCAL)"

      iex> format_field_name(:blob_store_url)
      "File Link"

      iex> format_field_name(:name)
      "Name"

  """
  def format_field_name(field) when is_atom(field) do
    Map.get(@field_name_labels, field, Phoenix.Naming.humanize(field))
  end

  # Private helper for default formatting of unknown types
  defp default_format(type) when is_atom(type) do
    type |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
  end

  @doc """
  Returns a map of all evidence type enum values to their display strings.

  This is useful for passing to components like FilterComponent that need
  a complete mapping of values to labels.

  ## Examples

      iex> evidence_type_labels()
      %{
        description_only: "Description Only",
        json_data: "JSON Content (OSCAL)",
        blob_store_link: "File Link"
      }

  """
  def evidence_type_labels do
    Valentine.Composer.Evidence
    |> Ecto.Enum.values(:evidence_type)
    |> Map.new(fn type -> {type, format_evidence_type(type)} end)
  end
end
