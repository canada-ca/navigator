defmodule Valentine.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :owner, :string
      add :label, :string, null: false
      add :key, :string
      add :status, :string
      add :last_used, :utc_datetime
      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:api_keys, [:workspace_id])
    create unique_index(:api_keys, [:id])
  end
end
