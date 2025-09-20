defmodule Valentine.Composer.BrainstormItem do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder,
           only: [
             :id,
             :workspace_id,
             :type,
             :raw_text,
             :normalized_text,
             :status,
             :cluster_key,
             :position,
             :used_in_threat_ids,
             :metadata,
             :inserted_at,
             :updated_at
           ]}

  schema "brainstorm_items" do
    belongs_to :workspace, Valentine.Composer.Workspace

    field :type, Ecto.Enum,
          values: [
            :threat,
            :assumption,
            :mitigation,
            :evidence,
            :requirement,
            :asset,
            :component,
            :attack_vector,
            :vulnerability,
            :impact,
            :control,
            :risk,
            :stakeholder,
            :boundary,
            :trust_zone,
            :data_flow,
            :process,
            :data_store,
            :external_entity
          ]

    field :raw_text, :string
    field :normalized_text, :string
    
    field :status, Ecto.Enum,
          values: [:draft, :clustered, :candidate, :used, :archived],
          default: :draft

    field :cluster_key, :string
    field :position, :integer
    field :used_in_threat_ids, {:array, :integer}, default: []
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(brainstorm_item, attrs) do
    brainstorm_item
    |> cast(attrs, [
      :workspace_id,
      :type,
      :raw_text,
      :normalized_text,
      :status,
      :cluster_key,
      :position,
      :used_in_threat_ids,
      :metadata
    ])
    |> validate_required([:workspace_id, :type, :raw_text])
    |> validate_length(:raw_text, max: 10_000)
    |> validate_length(:cluster_key, max: 255)
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_status_transition()
    |> normalize_text()
    |> check_duplicate_warning()
    |> unique_constraint(:id)
    |> foreign_key_constraint(:workspace_id)
  end

  @doc """
  Normalizes the raw text according to the specified rules:
  1. Trim whitespace
  2. Strip terminal punctuation (.?!)
  3. Lowercase first character only
  4. Collapse multiple internal spaces
  """
  def normalize_text(changeset) do
    case get_change(changeset, :raw_text) do
      nil ->
        changeset

      raw_text when is_binary(raw_text) ->
        normalized =
          raw_text
          |> String.trim()
          |> String.replace(~r/[.?!]+$/, "")
          |> lowercase_first_char()
          |> String.replace(~r/\s+/, " ")

        put_change(changeset, :normalized_text, normalized)

      _ ->
        changeset
    end
  end

  defp lowercase_first_char(text) when is_binary(text) do
    case String.length(text) do
      0 -> text
      1 -> String.downcase(text)
      _ -> String.downcase(String.at(text, 0)) <> String.slice(text, 1..-1)
    end
  end

  @doc """
  Validates status transitions according to the lifecycle rules.
  """
  def validate_status_transition(changeset) do
    old_status = get_field(changeset, :status)
    new_status = get_change(changeset, :status)

    case {old_status, new_status} do
      {_, nil} -> changeset
      {same, same} -> changeset
      {old, new} when not is_nil(old) and not is_nil(new) ->
        if valid_transition?(old, new) do
          changeset
        else
          add_error(changeset, :status, "invalid transition from #{old} to #{new}")
        end
      _ -> changeset
    end
  end

  defp valid_transition?(from_status, to_status) do
    case {from_status, to_status} do
      {:draft, :clustered} -> true
      {:draft, :archived} -> true
      {:clustered, :candidate} -> true
      {:clustered, :archived} -> true
      {:candidate, :used} -> true
      {:candidate, :archived} -> true
      {:used, :archived} -> true
      _ -> false
    end
  end

  @doc """
  Checks for duplicates and adds a warning to metadata if found.
  Uses normalized text for comparison within the same workspace and type.
  """
  def check_duplicate_warning(changeset) do
    workspace_id = get_field(changeset, :workspace_id)
    type = get_field(changeset, :type)
    normalized_text = get_field(changeset, :normalized_text)
    current_id = get_field(changeset, :id)

    case {workspace_id, type, normalized_text} do
      {ws_id, item_type, norm_text} when not is_nil(ws_id) and not is_nil(item_type) and not is_nil(norm_text) ->
        query = from(bi in __MODULE__,
          where: bi.workspace_id == ^ws_id and
                 bi.type == ^item_type and
                 bi.normalized_text == ^norm_text
        )

        query = if current_id, do: where(query, [bi], bi.id != ^current_id), else: query

        case Valentine.Repo.one(query) do
          nil ->
            changeset
          _existing ->
            metadata = get_field(changeset, :metadata) || %{}
            updated_metadata = Map.put(metadata, :duplicate_warning, true)
            put_change(changeset, :metadata, updated_metadata)
        end

      _ ->
        changeset
    end
  end

  @doc """
  Updates the cluster_key for a brainstorm item.
  """
  def assign_to_cluster(brainstorm_item, cluster_key) do
    changeset(brainstorm_item, %{cluster_key: cluster_key})
  end

  @doc """
  Updates the position for ordering within a column.
  """
  def update_position(brainstorm_item, position) do
    changeset(brainstorm_item, %{position: position})
  end

  @doc """
  Updates the used_in_threat_ids array when item is used in a threat.
  """
  def mark_used_in_threat(brainstorm_item, threat_id) when is_integer(threat_id) do
    current_ids = brainstorm_item.used_in_threat_ids || []
    
    if threat_id in current_ids do
      {:ok, brainstorm_item}
    else
      updated_ids = [threat_id | current_ids] |> Enum.sort()
      changeset(brainstorm_item, %{
        used_in_threat_ids: updated_ids,
        status: :used
      })
    end
  end

  @doc """
  Removes a threat ID from used_in_threat_ids array.
  """
  def unmark_used_in_threat(brainstorm_item, threat_id) when is_integer(threat_id) do
    current_ids = brainstorm_item.used_in_threat_ids || []
    updated_ids = List.delete(current_ids, threat_id)
    
    # If no more threats are using this item, potentially change status back
    new_status = if Enum.empty?(updated_ids), do: :candidate, else: :used
    
    changeset(brainstorm_item, %{
      used_in_threat_ids: updated_ids,
      status: new_status
    })
  end
end