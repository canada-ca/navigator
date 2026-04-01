defmodule Valentine.Repo.Migrations.CreateThreatModelQualityReviews do
  use Ecto.Migration

  def change do
    create table(:threat_model_quality_review_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :owner, :string, null: false
      add :runtime_agent_id, :string
      add :status, :string, null: false, default: "queued"
      add :progress_message, :text
      add :progress_percent, :integer, null: false, default: 0
      add :failure_reason, :text
      add :result_summary, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}
      add :requested_at, :utc_datetime
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :last_heartbeat_at, :utc_datetime
      add :cancel_requested_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:threat_model_quality_review_runs, [:workspace_id])
    create index(:threat_model_quality_review_runs, [:owner])
    create index(:threat_model_quality_review_runs, [:status])

    create unique_index(:threat_model_quality_review_runs, [:runtime_agent_id],
             where: "runtime_agent_id IS NOT NULL"
           )

    create table(:threat_model_quality_review_findings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :run_id,
          references(:threat_model_quality_review_runs, type: :binary_id, on_delete: :delete_all),
          null: false

      add :title, :string, null: false
      add :category, :string, null: false
      add :severity, :string, null: false
      add :rationale, :text, null: false
      add :suggested_action, :text, null: false
      add :metadata, :map, null: false, default: %{}
      add :display_order, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:threat_model_quality_review_findings, [:run_id])
    create index(:threat_model_quality_review_findings, [:category])
    create index(:threat_model_quality_review_findings, [:severity])
  end
end
