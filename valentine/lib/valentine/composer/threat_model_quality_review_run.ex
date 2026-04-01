defmodule Valentine.Composer.ThreatModelQualityReviewRun do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [
    :queued,
    :assembling_context,
    :reviewing,
    :persisting_results,
    :completed,
    :failed,
    :cancelled,
    :timed_out
  ]

  @derive {Jason.Encoder,
           only: [
             :id,
             :workspace_id,
             :owner,
             :runtime_agent_id,
             :status,
             :progress_message,
             :progress_percent,
             :failure_reason,
             :result_summary,
             :metadata,
             :requested_at,
             :started_at,
             :completed_at,
             :last_heartbeat_at,
             :cancel_requested_at,
             :inserted_at,
             :updated_at
           ]}

  schema "threat_model_quality_review_runs" do
    belongs_to :workspace, Valentine.Composer.Workspace

    field :owner, :string
    field :runtime_agent_id, :string
    field :status, Ecto.Enum, values: @statuses, default: :queued
    field :progress_message, :string
    field :progress_percent, :integer, default: 0
    field :failure_reason, :string
    field :result_summary, :map, default: %{}
    field :metadata, :map, default: %{}
    field :requested_at, :utc_datetime
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :last_heartbeat_at, :utc_datetime
    field :cancel_requested_at, :utc_datetime

    has_many :findings, Valentine.Composer.ThreatModelQualityReviewFinding,
      foreign_key: :run_id,
      on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :workspace_id,
      :owner,
      :runtime_agent_id,
      :status,
      :progress_message,
      :progress_percent,
      :failure_reason,
      :result_summary,
      :metadata,
      :requested_at,
      :started_at,
      :completed_at,
      :last_heartbeat_at,
      :cancel_requested_at
    ])
    |> validate_required([:workspace_id, :owner, :status])
    |> validate_length(:owner, max: 255)
    |> validate_length(:runtime_agent_id, max: 255)
    |> validate_number(:progress_percent, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:workspace_id)
  end
end
