defmodule Valentine.Seed do
  @moduledoc """
  Module for seeding control data from CSV files into the database.
  """

  alias Valentine.Composer.Controls

  @common_profile_tags [
    "CSP Full Stack",
    "CSP Stacked PaaS",
    "CSP Stacked SaaS",
    "Client IaaS / PaaS",
    "Client SaaS"
  ]

  def run do
    {:ok, _} = Application.ensure_all_started(:valentine)

    if controls_empty?() do
      seed_medium_profile()
      seed_low_profile()
      IO.puts("NIST Controls seeded into DB")
    else
      IO.puts("Controls already exist in the database")
    end
  end

  defp controls_empty?, do: length(Controls.list_controls()) == 0

  defp seed_medium_profile do
    get_csv_path("cccs-cloud-medium-profile.csv")
    |> process_csv_file(profile_tag: "CCCS Medium Profile for Cloud")
  end

  defp seed_low_profile do
    get_csv_path("cccs-cloud-low-profile.csv")
    |> process_csv_file(profile_tag: "CCCS Low Profile for Cloud", update_existing: true)
  end

  defp get_csv_path(filename) do
    Application.app_dir(:valentine, ["priv", "repo", "seed_data", filename])
  end

  defp process_csv_file(path, opts) do
    path
    |> File.stream!()
    |> CSV.decode!(headers: true, escape_max_lines: 20)
    |> Enum.each(&process_row(&1, opts))
  end

  defp process_row(row, profile_tag: tag, update_existing: true) do
    nist_id = row["ID"] |> nist_id() |> String.trim()

    case Controls.get_control_by_nist_id(nist_id) do
      nil -> create_control(row, [tag])
      control -> update_existing_control(control, tag)
    end
  end

  defp process_row(row, profile_tag: tag) do
    create_control(row, [tag])
  end

  defp create_control(row, additional_tags) do
    %{
      name: String.trim(row["Title"]),
      description: String.trim(row["Definition"]),
      class: String.trim(row["Class"]),
      guidance: String.trim(row["Supplemental Guidance"]),
      nist_id: row["ID"] |> nist_id() |> String.trim(),
      nist_family: String.trim(row["Name"]),
      stride: [],
      tags: extract_tags(row) ++ additional_tags
    }
    |> Controls.create_control()
  end

  defp update_existing_control(control, new_tag) do
    Controls.update_control(control, %{
      tags: control.tags ++ [new_tag]
    })
  end

  defp extract_tags(row) do
    @common_profile_tags
    |> Enum.filter(&(row[&1] == "X"))
  end

  defp nist_id(id) do
    case Regex.replace(~r/(\w+)-(\d+)\((\d+)\)/, id, "\\1-\\2.\\3") do
      ^id -> id
      result -> result
    end
  end
end
