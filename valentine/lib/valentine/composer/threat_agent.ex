defmodule Valentine.Composer.ThreatAgent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Valentine.Composer.DeliberateThreatLevel

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @td_levels DeliberateThreatLevel.values()

  schema "threat_agents" do
    field :name, :string
    field :agent_class, :string
    field :capability, :string
    field :motivation, :string
    field :td_level, Ecto.Enum, values: @td_levels

    belongs_to :workspace, Valentine.Composer.Workspace

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(threat_agent, attrs) do
    threat_agent
    |> cast(attrs, [:workspace_id, :name, :agent_class, :capability, :motivation, :td_level])
    |> validate_required([:workspace_id, :name])
    |> unique_constraint(:name, name: :threat_agents_workspace_id_name_index)
    |> foreign_key_constraint(:workspace_id)
  end
end
