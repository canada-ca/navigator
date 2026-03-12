defmodule Valentine.RepoAnalysis.GitHub do
  @moduledoc false

  defmodule RepoRef do
    @moduledoc false

    @enforce_keys [:owner, :name, :full_name, :clone_url]
    defstruct [:owner, :name, :full_name, :clone_url]
  end

  defmodule Snapshot do
    @moduledoc false

    @enforce_keys [:repo, :default_branch, :directory_tree, :documents, :metadata]
    defstruct [:repo, :default_branch, :directory_tree, :documents, :metadata]
  end

  @allowed_extensions ~w(.ex .exs .md .txt .json .yaml .yml .toml .xml .js .ts .tsx .jsx .py .java .go .rb .cs .kt .scala .rs .php .sh .sql .dockerfile .tf .tfvars .hcl)
  @preferred_files ~w(README.md README.adoc README.rst README.txt mix.exs package.json Dockerfile docker-compose.yml compose.yml go.mod pom.xml Cargo.toml requirements.txt pyproject.toml)
  @preferred_prefixes [
    ".github/workflows/",
    ".devcontainer/",
    "config/",
    "deploy/",
    "docker/",
    "docs/",
    "helm/",
    "infra/",
    "k8s/",
    "priv/",
    "terraform/"
  ]
  @deprioritized_prefixes ["cover/", "examples/", "priv/static/", "test/", "tmp/"]

  def parse_public_url(github_url) do
    {:ok, parse_public_url!(github_url)}
  rescue
    error in RuntimeError -> {:error, Exception.message(error)}
  end

  def parse_public_url!(github_url) do
    uri = URI.parse(github_url)

    unless uri.scheme in ["http", "https"] and uri.host in ["github.com", "www.github.com"] do
      raise "Only public GitHub repository URLs are supported"
    end

    path = String.trim(uri.path || "", "/")
    [owner, repo | _] = String.split(path, "/")

    if owner in [nil, ""] or repo in [nil, ""] do
      raise "GitHub URL must point to a repository"
    end

    repo = String.replace_suffix(repo, ".git", "")

    %RepoRef{
      owner: owner,
      name: repo,
      full_name: "#{owner}/#{repo}",
      clone_url: "https://github.com/#{owner}/#{repo}.git"
    }
  rescue
    MatchError -> raise "GitHub URL must point to a repository"
  end

  def clone(repo_ref, repo_analysis_agent_id, limits) do
    working_dir = fetch_limit!(limits, "working_dir")
    clone_dir = Path.join([working_dir, repo_analysis_agent_id])
    _ = File.rm_rf(clone_dir)
    :ok = File.mkdir_p!(working_dir)

    {output, exit_code} =
      run_command_with_timeout(
        "git",
        ["clone", "--depth", "1", repo_ref.clone_url, clone_dir],
        [stderr_to_stdout: true],
        fetch_limit!(limits, "clone_timeout_ms")
      )

    case exit_code do
      0 ->
        {:ok, clone_dir,
         %{
           "clone_dir" => clone_dir,
           "clone_output" => truncate(output, 2_000)
         }}

      _ ->
        _ = File.rm_rf(clone_dir)
        raise "Failed to clone repository: #{truncate(output, 2_000)}"
    end
  end

  def build_snapshot(clone_dir, repo_ref, limits) do
    files = tracked_files(clone_dir)

    if length(files) > fetch_limit!(limits, "max_repo_files") do
      raise "Repository exceeds the configured file limit"
    end

    selected_files =
      files
      |> prioritize_files()
      |> Enum.take(fetch_limit!(limits, "max_selected_files"))

    documents =
      selected_files
      |> Enum.map(&read_document(clone_dir, &1, fetch_limit!(limits, "max_file_bytes")))
      |> Enum.reject(&is_nil/1)

    {:ok,
     %Snapshot{
       repo: repo_ref,
       default_branch: git_default_branch(clone_dir),
       directory_tree: render_tree(files),
       documents: documents,
       metadata: %{
         "total_files" => length(files),
         "selected_files" => Enum.map(documents, & &1.path),
         "languages" => language_breakdown(files),
         "stack_hints" => stack_hints(files),
         "priority_paths" => Enum.take(selected_files, 10)
       }
     }}
  end

  defp tracked_files(clone_dir) do
    {output, 0} = System.cmd("git", ["-C", clone_dir, "ls-files"], stderr_to_stdout: true)

    output
    |> String.split("\n", trim: true)
    |> Enum.filter(&eligible_file?/1)
  end

  defp eligible_file?(path) do
    extension = Path.extname(path)
    basename = Path.basename(path)

    basename in @preferred_files or extension in @allowed_extensions or
      String.starts_with?(basename, "README")
  end

  defp prioritize_files(files) do
    Enum.sort_by(files, &file_priority/1)
  end

  defp file_priority(path) do
    basename = Path.basename(path)

    cond do
      basename in @preferred_files -> 0
      String.starts_with?(basename, "README") -> 1
      Enum.any?(@preferred_prefixes, &String.starts_with?(path, &1)) -> 2
      infrastructure_manifest?(path) -> 3
      Enum.any?(@deprioritized_prefixes, &String.starts_with?(path, &1)) -> 6
      true -> 4
    end
  end

  defp infrastructure_manifest?(path) do
    basename = Path.basename(path)

    basename in ["Chart.yaml", "values.yaml", "Procfile"] or
      String.ends_with?(basename, ".tf") or
      String.ends_with?(basename, ".tfvars") or
      String.ends_with?(basename, ".hcl")
  end

  defp read_document(clone_dir, relative_path, max_file_bytes) do
    full_path = Path.join(clone_dir, relative_path)

    case File.stat(full_path) do
      {:ok, %{size: size}} when size <= max_file_bytes ->
        case File.read(full_path) do
          {:ok, content} -> %{path: relative_path, content: content}
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp git_default_branch(clone_dir) do
    case System.cmd("git", ["-C", clone_dir, "branch", "--show-current"], stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      _ -> "main"
    end
  end

  defp render_tree(files) do
    files
    |> Enum.take(250)
    |> Enum.join("\n")
  end

  defp language_breakdown(files) do
    files
    |> Enum.map(&Path.extname/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.frequencies()
  end

  defp stack_hints(files) do
    hints = [
      {"Phoenix/Elixir", Enum.any?(files, &(&1 == "mix.exs"))},
      {"Node.js", Enum.any?(files, &(&1 == "package.json"))},
      {"Python", Enum.any?(files, &(&1 == "pyproject.toml" or &1 == "requirements.txt"))},
      {"Go", Enum.any?(files, &(&1 == "go.mod"))},
      {"Rust", Enum.any?(files, &(&1 == "Cargo.toml"))},
      {"Java", Enum.any?(files, &(&1 == "pom.xml"))},
      {"Containers",
       Enum.any?(
         files,
         &(Path.basename(&1) in ["Dockerfile", "docker-compose.yml", "compose.yml"])
       )},
      {"Infrastructure as Code", Enum.any?(files, &infrastructure_manifest?/1)},
      {"GitHub Actions", Enum.any?(files, &String.starts_with?(&1, ".github/workflows/"))}
    ]

    hints
    |> Enum.filter(fn {_label, present?} -> present? end)
    |> Enum.map(&elem(&1, 0))
  end

  defp truncate(text, max_bytes) when byte_size(text) <= max_bytes, do: text
  defp truncate(text, max_bytes), do: binary_part(text, 0, max_bytes) <> "..."

  defp run_command_with_timeout(command, args, opts, timeout_ms) do
    task = Task.async(fn -> System.cmd(command, args, opts) end)

    case Task.yield(task, timeout_ms) do
      {:ok, result} ->
        result

      nil ->
        _ = Task.shutdown(task, :brutal_kill)
        raise "Command timed out after #{timeout_ms}ms: #{command} #{Enum.join(args, " ")}"
    end
  end

  defp fetch_limit!(limits, key) do
    case Map.fetch(limits, key) do
      {:ok, value} -> value
      :error -> Map.fetch!(limits, String.to_atom(key))
    end
  end
end
