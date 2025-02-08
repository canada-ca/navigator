defmodule ValentineWeb.Workspace.Excel do
  alias Elixlsx.Workbook
  alias Elixlsx.Sheet

  alias Valentine.Composer

  def generate(workspace) do
    controls =
      Composer.list_controls_by_tags([workspace.cloud_profile, workspace.cloud_profile_type])
      |> sort_into_families()

    sheets = generate_sheets(Map.keys(controls))

    %Workbook{sheets: sheets}
    |> Elixlsx.write_to_memory("srtm.xlsx")
  end

  defp generate_sheets(families) do
    [
      Sheet.with_name("Control summary")
      | families
        |> Enum.map(fn n -> Sheet.with_name(n) end)
    ]
  end

  defp sort_into_families(controls) do
    controls
    |> Enum.group_by(fn c -> String.split(c.nist_id, "-") |> List.first() end)
  end
end
