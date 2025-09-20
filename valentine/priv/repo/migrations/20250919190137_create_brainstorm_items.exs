defmodule Valentine.Repo.Migrations.CreateBrainstormItems do
  use Ecto.Migration

  def change do
    create table(:brainstorm_items, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :type, :string, null: false
      add :raw_text, :text, null: false
      add :normalized_text, :text
      add :status, :string, null: false, default: "draft"
      add :cluster_key, :string
      add :position, :integer
      add :used_in_threat_ids, {:array, :integer}
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end

    # Mandatory scoping index
    create index(:brainstorm_items, [:workspace_id])

    # Column rendering index
    create index(:brainstorm_items, [:workspace_id, :type])

    # Conversion/backlog metrics index
    create index(:brainstorm_items, [:workspace_id, :status])

    # Cluster retrieval index
    create index(:brainstorm_items, [:cluster_key])

    # Time-based analytics index
    create index(:brainstorm_items, [:workspace_id, :inserted_at])

    # Primary key index
    create unique_index(:brainstorm_items, [:id])

    # Check constraints for enum values
    create constraint(:brainstorm_items, :valid_type,
             check:
               "type IN ('threat', 'assumption', 'mitigation', 'evidence', 'requirement', 'asset', 'component', 'attack_vector', 'vulnerability', 'impact', 'control', 'risk', 'stakeholder', 'boundary', 'trust_zone', 'data_flow', 'process', 'data_store', 'external_entity')"
           )

    create constraint(:brainstorm_items, :valid_status,
             check: "status IN ('draft', 'clustered', 'candidate', 'used', 'archived')"
           )
  end
end
