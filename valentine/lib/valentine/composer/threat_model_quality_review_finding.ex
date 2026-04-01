defmodule Valentine.Composer.ThreatModelQualityReviewFinding do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @categories [
    :duplicate_threat,
    :stride_gap,
    :orphaned_mitigation,
    :assumption_gap,
    :artifact_contradiction,
    :informational
  ]

  @severities [:info, :low, :medium, :high]

  @derive {Jason.Encoder,
           only: [
             :id,
             :run_id,
             :title,
             :category,
             :severity,
             :rationale,
             :suggested_action,
             :metadata,
             :display_order,
             :inserted_at,
             :updated_at
           ]}

  schema "threat_model_quality_review_findings" do
    belongs_to :run, Valentine.Composer.ThreatModelQualityReviewRun

    field :title, :string
    field :category, Ecto.Enum, values: @categories
    field :severity, Ecto.Enum, values: @severities
    field :rationale, :string
    field :suggested_action, :string
    field :metadata, :map, default: %{}
    field :display_order, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def categories, do: @categories
  def severities, do: @severities

  def changeset(finding, attrs) do
    finding
    |> cast(attrs, [
      :run_id,
      :title,
      :category,
      :severity,
      :rationale,
      :suggested_action,
      :metadata,
      :display_order
    ])
    |> validate_required([:run_id, :title, :category, :severity, :rationale, :suggested_action])
    |> validate_length(:title, max: 255)
    |> foreign_key_constraint(:run_id)
  end
end
