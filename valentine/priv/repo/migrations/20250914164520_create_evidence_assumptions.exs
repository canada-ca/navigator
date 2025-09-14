defmodule Valentine.Repo.Migrations.CreateEvidenceAssumptions do
  use Ecto.Migration

  def change do
    create table(:evidence_assumptions, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false

      add(:evidence_id, references(:evidence, on_delete: :delete_all, type: :binary_id),
        primary_key: true
      )

      add(:assumption_id, references(:assumptions, on_delete: :delete_all, type: :binary_id),
        primary_key: true
      )

      timestamps(type: :utc_datetime)
    end

    create index(:evidence_assumptions, [:evidence_id])
    create index(:evidence_assumptions, [:assumption_id])
    create unique_index(:evidence_assumptions, [:evidence_id, :assumption_id])
  end
end
