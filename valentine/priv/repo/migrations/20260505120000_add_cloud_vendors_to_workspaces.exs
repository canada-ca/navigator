defmodule Valentine.Repo.Migrations.AddCloudVendorsToWorkspaces do
  use Ecto.Migration

  def change do
    alter table(:workspaces) do
      add :cloud_vendors, {:array, :string}, null: false, default: []
    end
  end
end
