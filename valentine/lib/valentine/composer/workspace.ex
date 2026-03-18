defmodule Valentine.Composer.Workspace do
  use Ecto.Schema
  import Ecto.Changeset

  alias Valentine.Composer.DeliberateThreatLevel

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :cloud_profile,
             :cloud_profile_type,
             :url,
             :max_threat_level,
             :owner,
             :permissions
           ]}

  @nist_id_regex ~r/^[A-Za-z]{2}-\d+(\.\d+)?$/
  @td_levels DeliberateThreatLevel.values()

  schema "workspaces" do
    field :name, :string
    field :cloud_profile, :string
    field :cloud_profile_type, :string
    field :url, :string
    field :max_threat_level, Ecto.Enum, values: @td_levels

    has_one :application_information, Valentine.Composer.ApplicationInformation,
      on_delete: :delete_all

    has_one :architecture, Valentine.Composer.Architecture, on_delete: :delete_all

    has_one :data_flow_diagram, Valentine.Composer.DataFlowDiagram, on_delete: :delete_all

    has_many :assumptions, Valentine.Composer.Assumption, on_delete: :delete_all
    has_many :mitigations, Valentine.Composer.Mitigation, on_delete: :delete_all
    has_many :threats, Valentine.Composer.Threat, on_delete: :delete_all
    has_many :evidence, Valentine.Composer.Evidence, on_delete: :delete_all
    has_many :api_keys, Valentine.Composer.ApiKey, on_delete: :delete_all
    has_many :brainstorm_items, Valentine.Composer.BrainstormItem, on_delete: :delete_all
    has_many :repo_analysis_agents, Valentine.Composer.RepoAnalysisAgent, on_delete: :delete_all
    has_many :threat_agents, Valentine.Composer.ThreatAgent, on_delete: :delete_all

    field :owner, :string
    field :permissions, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [
      :name,
      :cloud_profile,
      :cloud_profile_type,
      :url,
      :max_threat_level,
      :owner,
      :permissions
    ])
    |> validate_required([:name, :owner, :permissions])
  end

  def check_workspace_permissions(workspace, identity) do
    case workspace.owner do
      ^identity -> "owner"
      _ -> workspace.permissions |> Map.get(identity)
    end
  end

  def get_tagged_with_controls(collection) do
    collection
    |> Enum.filter(&(&1.tags != nil))
    |> Enum.reduce(%{}, fn item, acc ->
      item.tags
      |> Enum.filter(&Regex.match?(@nist_id_regex, &1))
      |> Enum.reduce(acc, fn tag, acc ->
        Map.update(acc, tag, [item], &(&1 ++ [item]))
      end)
    end)
  end

  @doc """
  Groups evidence by their NIST control IDs.

  Returns a map where keys are NIST control IDs (e.g., "AC-1") and values
  are lists of evidence that have that control ID.

  ## Examples

      iex> evidence = [
      ...>   %Valentine.Composer.Evidence{id: 1, nist_controls: ["AC-1", "SC-7"]},
      ...>   %Valentine.Composer.Evidence{id: 2, nist_controls: ["AC-1"]}
      ...> ]
      iex> get_evidence_by_controls(evidence)
      %{
      ...>   "AC-1" => [
      ...>     %Valentine.Composer.Evidence{id: 2},
      ...>     %Valentine.Composer.Evidence{id: 1}
      ...>   ],
      ...>   "SC-7" => [
      ...>     %Valentine.Composer.Evidence{id: 1}
      ...>   ]
      ...> }
  """
  def get_evidence_by_controls(evidence_collection) do
    evidence_collection
    |> Enum.filter(&(&1.nist_controls != nil))
    |> Enum.reduce(%{}, fn evidence, acc ->
      evidence.nist_controls
      |> Enum.filter(&Regex.match?(@nist_id_regex, &1))
      |> Enum.reduce(acc, fn control_id, acc ->
        Map.update(acc, control_id, [evidence], &[evidence | &1])
      end)
    end)
  end
end
