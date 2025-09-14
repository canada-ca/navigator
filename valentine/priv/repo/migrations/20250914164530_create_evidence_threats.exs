defmodule Valentine.Repo.Migrations.CreateEvidenceThreats do
  use Ecto.Migration

  def change do
    create table(:evidence_threats, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false

      add(:evidence_id, references(:evidence, on_delete: :delete_all, type: :binary_id),
        primary_key: true
      )

      add(:threat_id, references(:threats, on_delete: :delete_all, type: :binary_id),
        primary_key: true
      )

      timestamps(type: :utc_datetime)
    end

    create index(:evidence_threats, [:evidence_id])
    create index(:evidence_threats, [:threat_id])
    create unique_index(:evidence_threats, [:evidence_id, :threat_id])
  end
end
