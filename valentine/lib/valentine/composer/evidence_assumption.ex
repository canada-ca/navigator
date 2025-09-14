defmodule Valentine.Composer.EvidenceAssumption do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "evidence_assumptions" do
    belongs_to :evidence, Valentine.Composer.Evidence
    belongs_to :assumption, Valentine.Composer.Assumption
    timestamps()
  end
end
