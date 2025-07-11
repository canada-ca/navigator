defmodule ValentineWeb.Workspace.Excel do
  alias Elixlsx.Workbook
  alias Elixlsx.Sheet

  alias Valentine.Composer

  def generate(workspace) do
    controls =
      if workspace.cloud_profile == nil && workspace.cloud_profile_type == nil do
        Composer.list_controls()
      else
        Composer.list_controls_by_filters(%{
          tags: [workspace.cloud_profile, workspace.cloud_profile_type]
        })
      end
      |> sort_into_families()
      |> append_tagged_entities(workspace)

    sheets = generate_sheets(controls)

    %Workbook{sheets: sheets}
    |> Elixlsx.write_to_memory("srtm.xlsx")
  end

  defp append_tagged_entities(controls, workspace) do
    assumptions = Composer.Workspace.get_tagged_with_controls(workspace.assumptions)
    mitigations = Composer.Workspace.get_tagged_with_controls(workspace.mitigations)
    threats = Composer.Workspace.get_tagged_with_controls(workspace.threats)

    controls
    |> Enum.map(fn {k, v} ->
      {k,
       v
       |> Enum.map(fn c ->
         %{
           control: c,
           assumptions: assumptions[c.nist_id],
           mitigations: mitigations[c.nist_id],
           threats: threats[c.nist_id]
         }
       end)}
    end)
    |> Enum.into(%{})
  end

  defp generate_rows(controls) do
    [
      title_row()
      | Enum.map(controls, fn c ->
          [
            c.control.nist_id,
            c.control.nist_family,
            c.control.class,
            c.control.name,
            c.control.description,
            if(c.mitigations != nil or c.threats != nil,
              do: "In scope",
              else: "Out of scope"
            ),
            if(c.assumptions != nil,
              do: [
                Enum.map(c.assumptions, fn i -> i.content end) |> Enum.join("\n"),
                wrap_text: true
              ],
              else: ""
            ),
            if(c.threats != nil,
              do: [
                Enum.map(c.threats, &Composer.Threat.show_statement/1) |> Enum.join("\n"),
                wrap_text: true
              ],
              else: ""
            ),
            if(c.mitigations != nil,
              do: [
                Enum.map(c.mitigations, fn i -> i.content end) |> Enum.join("\n"),
                wrap_text: true
              ],
              else: ""
            )
          ]
        end)
    ]
  end

  defp generate_sheets(controls) do
    [
      %Sheet{
        name: "Control summary",
        rows: generate_summary(controls)
      }
      |> Sheet.set_col_width("A", 18.0)
      | Enum.map(controls, fn {k, v} ->
          %Sheet{name: k, rows: generate_rows(v)}
          |> Sheet.set_pane_freeze(1, 9)
          |> Sheet.set_col_width("A", 18.0)
          |> Sheet.set_col_width("B", 18.0)
          |> Sheet.set_col_width("C", 18.0)
          |> Sheet.set_col_width("D", 18.0)
          |> Sheet.set_col_width("E", 18.0)
          |> Sheet.set_col_width("F", 18.0)
          |> Sheet.set_col_width("G", 18.0)
          |> Sheet.set_col_width("H", 18.0)
          |> Sheet.set_col_width("I", 18.0)
        end)
    ]
  end

  defp generate_summary(controls) do
    [
      [
        [
          "Control status",
          bold: true,
          border: [right: [style: :double, color: "#cc3311"]]
        ]
        | Enum.map(controls, fn {k, _} ->
            [k, bold: true, border: [bottom: [style: :double, color: "#cc3311"]]]
          end)
      ],
      [
        ["Satisfied", bold: true, border: [right: [style: :double, color: "#cc3311"]]]
        | Enum.map(controls, fn {_, v} ->
            [
              Enum.map(v, fn c -> if(c.mitigations != nil, do: length(c.mitigations), else: 0) end)
              |> Enum.sum()
            ]
          end)
      ],
      [
        ["Out of scope", bold: true, border: [right: [style: :double, color: "#cc3311"]]]
        | Enum.map(controls, fn {_, v} ->
            [
              Enum.map(v, fn c -> if(c.assumptions == nil, do: 1, else: 0) end)
              |> Enum.sum()
            ]
          end)
      ],
      [
        ["Risk Register", bold: true, border: [right: [style: :double, color: "#cc3311"]]]
        | Enum.map(controls, fn {_, v} ->
            [
              Enum.map(v, fn c ->
                if(c.threats != nil && c.mitigations == nil, do: length(c.threats), else: 0)
              end)
              |> Enum.sum()
            ]
          end)
      ]
    ]
  end

  defp sort_into_families(controls) do
    controls
    |> Enum.group_by(fn c -> String.split(c.nist_id, "-") |> List.first() end)
  end

  defp title_row do
    [
      ["Control ID", bold: true, border: [bottom: [style: :double, color: "#cc3311"]]],
      ["Name", bold: true, border: [bottom: [style: :double, color: "#cc3311"]]],
      ["Class", bold: true, border: [bottom: [style: :double, color: "#cc3311"]]],
      ["Title", bold: true, border: [bottom: [style: :double, color: "#cc3311"]]],
      ["Definition", bold: true, border: [bottom: [style: :double, color: "#cc3311"]]],
      ["Scope", bold: true, border: [bottom: [style: :double, color: "#cc3311"]]],
      ["Assumptions", bold: true, border: [bottom: [style: :double, color: "#cc3311"]]],
      ["Threats", bold: true, border: [bottom: [style: :double, color: "#cc3311"]]],
      ["Mitigations", bold: true, border: [bottom: [style: :double, color: "#cc3311"]]]
    ]
  end
end
