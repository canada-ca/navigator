defmodule Valentine.Composer.Documents do
  @moduledoc """
  Application information, data-flow diagram, and architecture documents.
  """

  import Ecto.Query, warn: false
  alias Valentine.Repo

  alias Valentine.Composer.ApplicationInformation
  alias Valentine.Composer.Architecture
  alias Valentine.Composer.DataFlowDiagram

  @doc """
  Returns the list of application_informations.

  ## Examples

      iex> list_application_informations()
      [%ApplicationInformation{}, ...]

  """
  def list_application_informations do
    Repo.all(ApplicationInformation)
  end

  @doc """
  Gets a single application_information.

  Raises `Ecto.NoResultsError` if the ApplicationInformation does not exist.

  ## Examples

      iex> get_application_information!(123)
      %ApplicationInformation{}

      iex> get_application_information!(456)
      ** (Ecto.NoResultsError)

  """
  def get_application_information!(id), do: Repo.get!(ApplicationInformation, id)

  @doc """
  Creates a application_information.

  ## Examples

      iex> create_application_information(%{field: value})
      {:ok, %ApplicationInformation{}}

      iex> create_application_information(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_application_information(attrs \\ %{}) do
    %ApplicationInformation{}
    |> ApplicationInformation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a application_information.

  ## Examples

      iex> update_application_information(application_information, %{field: new_value})
      {:ok, %ApplicationInformation{}}

      iex> update_application_information(application_information, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_application_information(%ApplicationInformation{} = application_information, attrs) do
    application_information
    |> ApplicationInformation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a application_information.

  ## Examples

      iex> delete_application_information(application_information)
      {:ok, %ApplicationInformation{}}

      iex> delete_application_information(application_information)
      {:error, %Ecto.Changeset{}}

  """
  def delete_application_information(%ApplicationInformation{} = application_information) do
    Repo.delete(application_information)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking application_information changes.

  ## Examples

      iex> change_application_information(application_information)
      %Ecto.Changeset{data: %ApplicationInformation{}}

  """
  def change_application_information(
        %ApplicationInformation{} = application_information,
        attrs \\ %{}
      ) do
    ApplicationInformation.changeset(application_information, attrs)
  end

  @doc """
  Returns the list of data_flow_diagrams.

  ## Examples

      iex> list_data_flow_diagrams()
      [%DataFlowDiagram{}, ...]

  """
  def list_data_flow_diagrams do
    Repo.all(DataFlowDiagram)
  end

  def get_data_flow_diagram_by_workspace_id(workspace_id) do
    Repo.get_by(DataFlowDiagram, workspace_id: workspace_id)
  end

  @doc """
  Gets a single data_flow_diagram.

  Raises `Ecto.NoResultsError` if the DataFlowDiagram does not exist.

  ## Examples

      iex> get_data_flow_diagram!(123)
      %DataFlowDiagram{}

      iex> get_data_flow_diagram!(456)
      ** (Ecto.NoResultsError)

  """
  def get_data_flow_diagram!(id), do: Repo.get!(DataFlowDiagram, id)

  @doc """
  Creates a data_flow_diagram.

  ## Examples

      iex> create_data_flow_diagram(%{field: value})
      {:ok, %DataFlowDiagram{}}

      iex> create_data_flow_diagram(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_data_flow_diagram(attrs \\ %{}) do
    %DataFlowDiagram{}
    |> DataFlowDiagram.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a data_flow_diagram.

  ## Examples

      iex> update_data_flow_diagram(data_flow_diagram, %{field: new_value})
      {:ok, %DataFlowDiagram{}}

      iex> update_data_flow_diagram(data_flow_diagram, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_data_flow_diagram(%DataFlowDiagram{} = data_flow_diagram, attrs) do
    data_flow_diagram
    |> DataFlowDiagram.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a data_flow_diagram.

  ## Examples

      iex> delete_data_flow_diagram(data_flow_diagram)
      {:ok, %DataFlowDiagram{}}

      iex> delete_data_flow_diagram(data_flow_diagram)
      {:error, %Ecto.Changeset{}}

  """
  def delete_data_flow_diagram(%DataFlowDiagram{} = data_flow_diagram) do
    Repo.delete(data_flow_diagram)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking data_flow_diagram changes.

  ## Examples

      iex> change_data_flow_diagram(data_flow_diagram)
      %Ecto.Changeset{data: %DataFlowDiagram{}}

  """
  def change_data_flow_diagram(
        %DataFlowDiagram{} = data_flow_diagram,
        attrs \\ %{}
      ) do
    DataFlowDiagram.changeset(data_flow_diagram, attrs)
  end

  @doc """
  Returns the list of architectures.

  ## Examples

      iex> list_architectures()
      [%Architecture{}, ...]

  """
  def list_architectures do
    Repo.all(Architecture)
  end

  @doc """
  Gets a single architecture.

  Raises `Ecto.NoResultsError` if the Architecture does not exist.

  ## Examples

      iex> get_architecture!(123)
      %Architecture{}

      iex> get_architecture!(456)
      ** (Ecto.NoResultsError)

  """
  def get_architecture!(id), do: Repo.get!(Architecture, id)

  @doc """
  Creates a architecture.

  ## Examples

      iex> create_architecture(%{field: value})
      {:ok, %Architecture{}}

      iex> create_architecture(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_architecture(attrs \\ %{}) do
    %Architecture{}
    |> Architecture.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a architecture.

  ## Examples

      iex> update_architecture(architecture, %{field: new_value})
      {:ok, %Architecture{}}

      iex> update_architecture(architecture, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_architecture(%Architecture{} = architecture, attrs) do
    architecture
    |> Architecture.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a architecture.

  ## Examples

      iex> delete_architecture(architecture)
      {:ok, %Architecture{}}

      iex> delete_architecture(architecture)
      {:error, %Ecto.Changeset{}}

  """
  def delete_architecture(%Architecture{} = architecture) do
    Repo.delete(architecture)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking architecture changes.

  ## Examples

      iex> change_architecture(architecture)
      %Ecto.Changeset{data: %Architecture{}}

  """
  def change_architecture(
        %Architecture{} = architecture,
        attrs \\ %{}
      ) do
    Architecture.changeset(architecture, attrs)
  end
end
