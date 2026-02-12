defmodule Valentine.Composer.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Jason.Encoder,
           only: [
             :id,
             :workspace_id,
             :user_id,
             :role,
             :content,
             :context,
             :inserted_at,
             :updated_at
           ]}

  schema "chat_messages" do
    belongs_to :workspace, Valentine.Composer.Workspace

    field :user_id, :string
    field :role, Ecto.Enum, values: [:user, :assistant, :system]
    field :content, :string
    field :context, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:workspace_id, :user_id, :role, :content, :context])
    |> validate_required([:workspace_id, :user_id, :role, :content])
  end
end
