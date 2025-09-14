defmodule Valentine.Repo.Migrations.CreateEvidenceMitigations do
  use Ecto.Migration

  def change do
    create table(:evidence_mitigations, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false

      add(:evidence_id, references(:evidence, on_delete: :delete_all, type: :binary_id),
        primary_key: true
      )

      add(:mitigation_id, references(:mitigations, on_delete: :delete_all, type: :binary_id),
        primary_key: true
      )

      timestamps(type: :utc_datetime)
    end

    create index(:evidence_mitigations, [:evidence_id])
    create index(:evidence_mitigations, [:mitigation_id])
    create unique_index(:evidence_mitigations, [:evidence_id, :mitigation_id])
  end
end
