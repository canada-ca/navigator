defmodule Valentine.Composer.Threat do
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
             :status,
             :priority,
             :stride,
             :comments,
             :threat_source,
             :prerequisites,
             :threat_action,
             :threat_impact,
             :impacted_goal,
             :impacted_assets,
             :tags
           ]}

  schema "threats" do
    belongs_to :workspace, Valentine.Composer.Workspace

    field :numeric_id, :integer
    field :status, Ecto.Enum, values: [:identified, :resolved, :not_useful]
    field :priority, Ecto.Enum, values: [:low, :medium, :high]

    field :stride,
          {:array, Ecto.Enum},
          values: [
            :spoofing,
            :tampering,
            :repudiation,
            :information_disclosure,
            :denial_of_service,
            :elevation_of_privilege
          ]

    field :comments, :string
    field :threat_source, :string
    field :prerequisites, :string
    field :threat_action, :string
    field :threat_impact, :string
    field :impacted_goal, {:array, :string}
    field :impacted_assets, {:array, :string}
    field :tags, {:array, :string}, default: []

    has_many :assumption_threats, Valentine.Composer.AssumptionThreat, on_replace: :delete
    has_many :assumptions, through: [:assumption_threats, :assumption]

    has_many :mitigation_threats, Valentine.Composer.MitigationThreat, on_replace: :delete
    has_many :mitigations, through: [:mitigation_threats, :mitigation]

    has_many :evidence_threats, Valentine.Composer.EvidenceThreat, on_replace: :delete
    has_many :evidence, through: [:evidence_threats, :evidence]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(threat, attrs) do
    threat
    |> cast(attrs, [
      :workspace_id,
      :status,
      :priority,
      :stride,
      :comments,
      :threat_source,
      :prerequisites,
      :threat_action,
      :threat_impact,
      :impacted_goal,
      :impacted_assets,
      :tags
    ])
    |> validate_required([
      :workspace_id
    ])
    |> set_numeric_id()
    |> unique_constraint(:numeric_id, name: :threats_workspace_id_numeric_id_index)
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
            last_threat =
              Valentine.Repo.one(
                from t in __MODULE__,
                  where: t.workspace_id == ^workspace_id,
                  order_by: [desc: t.numeric_id],
                  limit: 1
              )

            put_change(changeset, :numeric_id, (last_threat && last_threat.numeric_id + 1) || 1)
        end

      _ ->
        changeset
    end
  end

  def show_statement(threat) do
    "#{ValentineWeb.WorkspaceLive.Threat.Components.ThreatHelpers.a_or_an(threat.threat_source,
    true)} #{threat.threat_source} #{threat.prerequisites} can #{threat.threat_action}#{if(threat.threat_impact != nil, do: ", which leads to #{threat.threat_impact}")}#{if(threat.impacted_goal && threat.impacted_goal != [],
    do: ", resulting in reduced " <> ValentineWeb.WorkspaceLive.Threat.Components.ThreatHelpers.join_list(threat.impacted_goal))} negatively impacting #{ValentineWeb.WorkspaceLive.Threat.Components.ThreatHelpers.join_list(threat.impacted_assets)}."
  end

  def stride_banner(threat) do
    case threat.stride do
      nil ->
        "STRIDE"

      stride when is_list(stride) ->
        [
          :spoofing,
          :tampering,
          :repudiation,
          :information_disclosure,
          :denial_of_service,
          :elevation_of_privilege
        ]
        |> Enum.reduce("", fn c, acc ->
          first_char = Atom.to_string(c) |> String.at(0) |> String.upcase()

          acc <>
            if Enum.member?(stride, c),
              do: "<span class=\"Label--accent\">#{first_char}</span>",
              else: first_char
        end)
        |> Phoenix.HTML.raw()
    end
  end
end
