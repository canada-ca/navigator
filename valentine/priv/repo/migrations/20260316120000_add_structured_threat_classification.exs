defmodule Valentine.Repo.Migrations.AddStructuredThreatClassification do
  use Ecto.Migration

  def change do
    alter table(:workspaces) do
      add :max_threat_level, :string
    end

    alter table(:threats) do
      add :mitre_tactic, :string
      add :kill_chain_phase, :string
      add :threat_level, :string
    end

    create table(:threat_agents, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :string, null: false
      add :agent_class, :string
      add :capability, :string
      add :motivation, :string
      add :td_level, :string

      timestamps(type: :utc_datetime)
    end

    create index(:threat_agents, [:workspace_id])
    create unique_index(:threat_agents, [:workspace_id, :name])
    create index(:threats, [:workspace_id, :threat_level])
    create index(:workspaces, [:max_threat_level])
  end
end
