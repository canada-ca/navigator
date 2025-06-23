defmodule Valentine.Repo.Migrations.AddStatusToAssumptions do
  use Ecto.Migration

  def change do
    alter table(:assumptions) do
      add :status, :string
    end
  end
end
