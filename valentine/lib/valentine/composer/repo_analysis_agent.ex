defmodule Valentine.Composer.RepoAnalysisAgent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [
    :queued,
    :cloning,
    :indexing,
    :summarizing,
    :generating_dfd,
    :generating_threat_model,
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
             :github_url,
             :repo_full_name,
             :repo_default_branch,
             :runtime_agent_id,
             :status,
             :progress_message,
             :progress_percent,
             :failure_reason,
             :result_summary,
             :limits,
             :metadata,
             :requested_at,
             :started_at,
             :completed_at,
             :last_heartbeat_at,
             :cancel_requested_at,
             :inserted_at,
             :updated_at
           ]}

  schema "repo_analysis_agents" do
    belongs_to :workspace, Valentine.Composer.Workspace

    field :owner, :string
    field :github_url, :string
    field :repo_full_name, :string
    field :repo_default_branch, :string
    field :runtime_agent_id, :string

    field :status, Ecto.Enum, values: @statuses, default: :queued
    field :progress_message, :string
    field :progress_percent, :integer, default: 0
    field :failure_reason, :string
    field :result_summary, :map, default: %{}
    field :limits, :map, default: %{}
    field :metadata, :map, default: %{}

    field :requested_at, :utc_datetime
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :last_heartbeat_at, :utc_datetime
    field :cancel_requested_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc false
  def changeset(repo_analysis_agent, attrs) do
    repo_analysis_agent
    |> cast(attrs, [
      :workspace_id,
      :owner,
      :github_url,
      :repo_full_name,
      :repo_default_branch,
      :runtime_agent_id,
      :status,
      :progress_message,
      :progress_percent,
      :failure_reason,
      :result_summary,
      :limits,
      :metadata,
      :requested_at,
      :started_at,
      :completed_at,
      :last_heartbeat_at,
      :cancel_requested_at
    ])
    |> validate_required([:workspace_id, :owner, :github_url, :status])
    |> validate_length(:owner, max: 255)
    |> validate_length(:github_url, max: 2048)
    |> validate_length(:repo_full_name, max: 255)
    |> validate_length(:repo_default_branch, max: 255)
    |> validate_length(:runtime_agent_id, max: 255)
    |> validate_number(:progress_percent, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:workspace_id)
  end
end