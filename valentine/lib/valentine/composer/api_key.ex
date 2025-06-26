defmodule Valentine.Composer.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder,
           only: [
             :id,
             :owner,
             :label,
             :status,
             :last_used,
             :workspace_id
           ]}

  schema "api_keys" do
    belongs_to :workspace, Valentine.Composer.Workspace

    field :owner, :string
    field :label, :string
    field :key, :string
    field :status, Ecto.Enum, values: [:init, :active, :expired, :revoked]
    field :last_used, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [
      :owner,
      :label,
      :key,
      :status,
      :last_used,
      :workspace_id
    ])
    |> validate_required([:owner, :label, :status])
    |> unique_constraint(:id)
    |> foreign_key_constraint(:workspace_id)
  end

  def generate_key(api_key) do
    {:ok, token, _claims} =
      Valentine.Guardian.encode_and_sign(api_key, %{}, token_type: "api_key")

    %{api_key | key: token}
  end
end
