defmodule Valentine.Repo.Migrations.CreateEvidence do
  use Ecto.Migration

  def change do
    create table(:evidence, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :numeric_id, :integer
      add :name, :string, null: false
      add :description, :text
      add :evidence_type, :string, null: false
      add :content, :map  # For JSON data like OSCAL documents
      add :blob_store_url, :string  # For external file links
      add :nist_controls, {:array, :string}, default: []
      add :tags, {:array, :string}, default: []
      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:evidence, [:workspace_id])
    create unique_index(:evidence, [:id])
    create unique_index(:evidence, [:workspace_id, :numeric_id])
  end
end