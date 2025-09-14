defmodule Valentine.Composer.EvidenceThreat do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "evidence_threats" do
    belongs_to :evidence, Valentine.Composer.Evidence
    belongs_to :threat, Valentine.Composer.Threat
    timestamps()
  end
end
