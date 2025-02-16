defmodule Valentine.Repo.Migrations.AddOwnerToWorkspaces do
  use Ecto.Migration

  def change do
    alter table(:workspaces) do
      add :owner, :string
      add :permissions, :map, null: false, default: %{}
    end
  end
end
