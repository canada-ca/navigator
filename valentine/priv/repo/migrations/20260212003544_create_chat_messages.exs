defmodule Valentine.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false

      add :workspace_id, references(:workspaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, :string, null: false
      add :role, :string, null: false
      add :content, :text, null: false
      add :context, :map

      timestamps(type: :utc_datetime)
    end

    # Index for efficient retrieval of chat history by workspace and user
    create index(:chat_messages, [:workspace_id, :user_id, :inserted_at])

    # Index for workspace-level queries
    create index(:chat_messages, [:workspace_id])

    # Primary key index
    create unique_index(:chat_messages, [:id])

    # Check constraint for valid role values
    create constraint(:chat_messages, :valid_role,
             check: "role IN ('user', 'assistant', 'system')"
           )
  end
end
