defmodule Valentine.Composer.Threats do
  @moduledoc """
  Threat and threat-agent persistence and queries.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.Threat
  alias Valentine.Composer.ThreatAgent
  alias Valentine.Composer.QueryHelpers

  @doc """
  Returns the list of threats.

  ## Examples

      iex> list_threats()
      [%Threat{}, ...]

  """
  def list_threats do
    Repo.all(Threat)
  end

  @doc """
  Filters threats based on enum field values.

  Takes a queryable and a map of filters where keys are field names and values are selected enum values.
  Handles both array and parameterized enum fields.

  ## Examples

      iex> filters = %{severity: ["HIGH", "CRITICAL"], status: ["OPEN"]}
      iex> list_threats_with_enum_filters(Threat, filters)
      [%Threat{severity: "HIGH", status: "OPEN"}, ...]

  """
  def list_threats_with_enum_filters(m, filters) do
    QueryHelpers.apply_enum_filters(m, filters, Threat)
  end

  def list_threats_by_ids(ids) do
    from(t in Threat, where: t.id in ^ids)
    |> Repo.all()
  end

  @doc """
  Returns the list of threats for a specific workspace.

  ## Parameters

    * workspace_id - The UUID of the workspace to filter threats by

  ## Examples

      iex> list_threats_by_workspace("123e4567-e89b-12d3-a456-426614174000")
      [%Threat{}, ...]

      iex> list_threats_by_workspace("nonexistent-id")
      []
  """
  def list_threats_by_workspace(workspace_id, enum_filters \\ %{}) do
    from(t in Threat, where: t.workspace_id == ^workspace_id)
    |> list_threats_with_enum_filters(enum_filters)
    |> order_by([t], desc: t.numeric_id)
    |> preload([:assumptions, :mitigations])
    |> Repo.all()
  end

  @doc """
  Gets a single threat.

  Raises `Ecto.NoResultsError` if the Threat does not exist.

  ## Examples

      iex> get_threat!(123)
      %Threat{}

      iex> get_threat!(456)
      ** (Ecto.NoResultsError)

  """
  def get_threat!(id, _preload \\ nil)

  def get_threat!(id, preload) when is_list(preload) do
    Repo.get!(Threat, id)
    |> Repo.preload(preload)
  end

  def get_threat!(id, preload) when is_nil(preload), do: Repo.get!(Threat, id)

  def get_threat_for_workspace!(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity!(Threat, workspace_id, id, preload)
  end

  def get_threat_for_workspace(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity(Threat, workspace_id, id, preload)
  end

  @doc """
  Creates a threat.

  ## Examples

      iex> create_threat(%{field: value})
      {:ok, %Threat{}}

      iex> create_threat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_threat(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:threat, fn _ ->
      %Threat{}
      |> Threat.changeset(attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{threat: threat}} -> {:ok, threat}
      {:error, :threat, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates a threat.

  ## Examples

      iex> update_threat(threat, %{field: new_value})
      {:ok, %Threat{}}

      iex> update_threat(threat, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_threat(%Threat{} = threat, attrs) do
    threat
    |> Threat.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a threat.

  ## Examples

      iex> delete_threat(threat)
      {:ok, %Threat{}}

      iex> delete_threat(threat)
      {:error, %Ecto.Changeset{}}

  """
  def delete_threat(%Threat{} = threat) do
    Repo.delete(threat)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking threat changes.

  ## Examples

      iex> change_threat(threat)
      %Ecto.Changeset{data: %Threat{}}

  """
  def change_threat(%Threat{} = threat, attrs \\ %{}) do
    Threat.changeset(threat, attrs)
  end

  @doc """
  Returns the list of threat agents for a specific workspace.
  """
  def list_threat_agents(workspace_id) do
    from(ta in ThreatAgent,
      where: ta.workspace_id == ^workspace_id,
      order_by: [asc: ta.name]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single threat agent.
  """
  def get_threat_agent!(id, preload \\ nil)

  def get_threat_agent!(id, preload) when is_list(preload) do
    Repo.get!(ThreatAgent, id)
    |> Repo.preload(preload)
  end

  def get_threat_agent!(id, preload) when is_nil(preload), do: Repo.get!(ThreatAgent, id)

  def get_threat_agent_for_workspace!(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity!(ThreatAgent, workspace_id, id, preload)
  end

  def get_threat_agent_for_workspace(workspace_id, id, preload \\ nil) do
    QueryHelpers.get_workspace_entity(ThreatAgent, workspace_id, id, preload)
  end

  @doc """
  Creates a threat agent.
  """
  def create_threat_agent(attrs \\ %{}) do
    %ThreatAgent{}
    |> ThreatAgent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a threat agent.
  """
  def update_threat_agent(%ThreatAgent{} = threat_agent, attrs) do
    threat_agent
    |> ThreatAgent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a threat agent.
  """
  def delete_threat_agent(%ThreatAgent{} = threat_agent) do
    Repo.delete(threat_agent)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking threat agent changes.
  """
  def change_threat_agent(%ThreatAgent{} = threat_agent, attrs \\ %{}) do
    ThreatAgent.changeset(threat_agent, attrs)
  end
end
