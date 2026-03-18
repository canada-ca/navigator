defmodule Valentine.Composer.Evidence do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  # Allowed URL schemes for blob_store_url validation
  # Includes common web protocols and cloud storage schemes
  @allowed_url_schemes ["http", "https", "s3", "gs", "ftp", "ftps"]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder,
           only: [
             :id,
             :workspace_id,
             :numeric_id,
             :name,
             :description,
             :evidence_type,
             :content,
             :blob_store_url,
             :nist_controls,
             :tags,
             :assumptions,
             :threats,
             :mitigations
           ]}

  schema "evidence" do
    belongs_to :workspace, Valentine.Composer.Workspace

    field :numeric_id, :integer
    field :name, :string
    field :description, :string
    field :evidence_type, Ecto.Enum, values: [:description_only, :json_data, :blob_store_link]
    # For JSON data like OSCAL documents
    field :content, :map
    # For external file links (images, documents, etc.)
    field :blob_store_url, :string
    # NIST control IDs
    field :nist_controls, {:array, :string}, default: []
    field :tags, {:array, :string}, default: []

    # Many-to-many relationships through join tables
    has_many :evidence_assumptions, Valentine.Composer.EvidenceAssumption, on_replace: :delete
    has_many :assumptions, through: [:evidence_assumptions, :assumption]

    has_many :evidence_threats, Valentine.Composer.EvidenceThreat, on_replace: :delete
    has_many :threats, through: [:evidence_threats, :threat]

    has_many :evidence_mitigations, Valentine.Composer.EvidenceMitigation, on_replace: :delete
    has_many :mitigations, through: [:evidence_mitigations, :mitigation]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(evidence, attrs) do
    evidence
    |> cast(attrs, [
      :workspace_id,
      :name,
      :description,
      :evidence_type,
      :content,
      :blob_store_url,
      :nist_controls,
      :tags
    ])
    |> validate_required([:workspace_id, :name, :description, :evidence_type])
    |> validate_evidence_type_content()
    |> validate_nist_controls()
    |> set_numeric_id()
    |> unique_constraint(:numeric_id, name: :evidence_workspace_id_numeric_id_index)
    |> unique_constraint(:id)
    |> foreign_key_constraint(:workspace_id)
  end

  defp validate_evidence_type_content(changeset) do
    evidence_type = get_field(changeset, :evidence_type)
    content = get_field(changeset, :content)
    blob_store_url = get_field(changeset, :blob_store_url)

    case evidence_type do
      :description_only ->
        # Description-only evidence should not have attachment fields
        if !is_nil(content) or (!is_nil(blob_store_url) and blob_store_url != "") do
          add_error(
            changeset,
            :evidence_type,
            "description_only evidence cannot have content or blob_store_url"
          )
        else
          changeset
          |> put_change(:content, nil)
          |> put_change(:blob_store_url, nil)
        end

      :json_data ->
        if is_nil(content) do
          add_error(changeset, :content, "must be provided for this evidence type")
        else
          changeset
          # Clear blob_store_url for json_data type
          |> put_change(:blob_store_url, nil)
        end

      :blob_store_link ->
        if is_nil(blob_store_url) or blob_store_url == "" do
          add_error(
            changeset,
            :blob_store_url,
            "must be provided for this evidence type"
          )
        else
          changeset
          # Clear content for blob_store_link type
          |> put_change(:content, nil)
          |> validate_blob_store_url()
        end

      _ ->
        changeset
    end
  end

  defp validate_blob_store_url(changeset) do
    blob_store_url = get_field(changeset, :blob_store_url)

    # Skip validation if URL is nil or empty (already validated by validate_evidence_type_content)
    if is_nil(blob_store_url) or blob_store_url == "" do
      changeset
    else
      case URI.new(blob_store_url) do
        {:ok, %URI{scheme: scheme, host: host}} ->
          cond do
            is_nil(scheme) or scheme == "" ->
              add_error(
                changeset,
                :blob_store_url,
                "must be a valid URL with a scheme (e.g., https://example.com)"
              )

            scheme not in @allowed_url_schemes ->
              add_error(
                changeset,
                :blob_store_url,
                "must use an allowed URL scheme (http, https, s3, gs, ftp, ftps)"
              )

            is_nil(host) or host == "" ->
              add_error(
                changeset,
                :blob_store_url,
                "must include a host (e.g., https://example.com)"
              )

            true ->
              changeset
          end

        {:error, _part} ->
          add_error(changeset, :blob_store_url, "must be a valid URL")
      end
    end
  end

  defp validate_nist_controls(changeset) do
    nist_controls = get_field(changeset, :nist_controls) || []

    # NIST control ID pattern: e.g., "AC-1", "SC-7.4", "AU-12"
    nist_id_regex = ~r/^[A-Z]{2}-\d+(\.\d+)?$/

    invalid_controls =
      nist_controls
      |> Enum.reject(&Regex.match?(nist_id_regex, &1))

    if length(invalid_controls) > 0 do
      add_error(
        changeset,
        :nist_controls,
        "contains invalid NIST control IDs: #{Enum.join(invalid_controls, ", ")}"
      )
    else
      changeset
    end
  end

  defp set_numeric_id(changeset) do
    case get_field(changeset, :numeric_id) do
      nil ->
        case get_field(changeset, :workspace_id) do
          nil ->
            changeset

          workspace_id ->
            last_evidence =
              Valentine.Repo.one(
                from e in __MODULE__,
                  where: e.workspace_id == ^workspace_id,
                  order_by: [desc: e.numeric_id],
                  limit: 1
              )

            put_change(
              changeset,
              :numeric_id,
              (last_evidence && last_evidence.numeric_id + 1) || 1
            )
        end

      _ ->
        changeset
    end
  end
end
