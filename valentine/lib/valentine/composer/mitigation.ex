defmodule Valentine.Composer.Mitigation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder,
           only: [
             :id,
             :workspace_id,
             :numeric_id,
             :content,
             :comments,
             :status,
             :tags
           ]}

  schema "mitigations" do
    belongs_to :workspace, Valentine.Composer.Workspace

    field :comments, :string
    field :numeric_id, :integer
    field :content, :string
    field :status, Ecto.Enum, values: [:identified, :in_progress, :resolved, :will_not_action]
    field :tags, {:array, :string}, default: []

    has_many :assumption_mitigations, Valentine.Composer.AssumptionMitigation, on_replace: :delete
    has_many :assumptions, through: [:assumption_mitigations, :assumption]

    has_many :mitigation_threats, Valentine.Composer.MitigationThreat, on_replace: :delete
    has_many :threats, through: [:mitigation_threats, :threat]

    has_many :evidence_mitigations, Valentine.Composer.EvidenceMitigation, on_replace: :delete
    has_many :evidence, through: [:evidence_mitigations, :evidence]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mitigation, attrs) do
    mitigation
    |> cast(attrs, [:content, :comments, :status, :tags, :workspace_id])
    |> validate_required([:content, :workspace_id])
    |> set_numeric_id()
    |> unique_constraint(:numeric_id, name: :mitigations_workspace_id_numeric_id_index)
    |> unique_constraint(:id)
    |> foreign_key_constraint(:workspace_id)
  end

  defp set_numeric_id(changeset) do
    case get_field(changeset, :numeric_id) do
      nil ->
        case get_field(changeset, :workspace_id) do
          nil ->
            changeset

          workspace_id ->
            last_mitigation =
              Valentine.Repo.one(
                from t in __MODULE__,
                  where: t.workspace_id == ^workspace_id,
                  order_by: [desc: t.numeric_id],
                  limit: 1
              )

            put_change(
              changeset,
              :numeric_id,
              (last_mitigation && last_mitigation.numeric_id + 1) || 1
            )
        end

      _ ->
        changeset
    end
  end
end
