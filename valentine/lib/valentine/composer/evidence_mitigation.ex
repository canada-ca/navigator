defmodule Valentine.Composer.EvidenceMitigation do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "evidence_mitigations" do
    belongs_to :evidence, Valentine.Composer.Evidence
    belongs_to :mitigation, Valentine.Composer.Mitigation
    timestamps()
  end
end
