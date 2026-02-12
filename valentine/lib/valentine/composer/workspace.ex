defmodule Valentine.Composer.Workspace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :cloud_profile,
             :cloud_profile_type,
             :url,
             :owner,
             :permissions
           ]}

  @nist_id_regex ~r/^[A-Za-z]{2}-\d+(\.\d+)?$/

  schema "workspaces" do
    field :name, :string
    field :cloud_profile, :string
    field :cloud_profile_type, :string
    field :url, :string

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

    field :owner, :string
    field :permissions, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [:name, :cloud_profile, :cloud_profile_type, :url, :owner, :permissions])
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
end
