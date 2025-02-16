defmodule Valentine.Composer.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:email, :string, autogenerate: false}

  schema "users" do
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :updated_at])
    |> validate_required([:email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
  end
end
