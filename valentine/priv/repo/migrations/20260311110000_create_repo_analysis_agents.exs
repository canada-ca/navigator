defmodule Valentine.Repo.Migrations.CreateRepoAnalysisAgents do
  use Ecto.Migration

  def change do
    create table(:repo_analysis_agents, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :owner, :string, null: false
      add :github_url, :text, null: false
      add :repo_full_name, :string
      add :repo_default_branch, :string
      add :runtime_agent_id, :string
      add :status, :string, null: false, default: "queued"
      add :progress_message, :text
      add :progress_percent, :integer, null: false, default: 0
      add :failure_reason, :text
      add :result_summary, :map, null: false, default: %{}
      add :limits, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}
      add :requested_at, :utc_datetime
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :last_heartbeat_at, :utc_datetime
      add :cancel_requested_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:repo_analysis_agents, [:owner])
    create index(:repo_analysis_agents, [:workspace_id])
    create index(:repo_analysis_agents, [:status])

    create unique_index(:repo_analysis_agents, [:runtime_agent_id],
             where: "runtime_agent_id IS NOT NULL"
           )
  end
end
