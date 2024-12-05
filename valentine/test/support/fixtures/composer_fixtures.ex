defmodule Valentine.ComposerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Valentine.Composer` context.
  """

  @doc """
  Generate a random UUID.
  """
  def random_uuid() do
    Ecto.UUID.generate()
    |> to_string()
  end

  @doc """
  Generate a workspace.
  """
  def workspace_fixture(attrs \\ %{}) do
    {:ok, workspace} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Valentine.Composer.create_workspace()

    workspace
  end

  @doc """
  Generate a threat.
  """
  def threat_fixture(attrs \\ %{}) do
    workspace = workspace_fixture()

    {:ok, threat} =
      attrs
      |> Enum.into(%{
        display_order: 42,
        impacted_assets: ["option1", "option2"],
        impacted_goal: ["option1", "option2"],
        comments: "some comments",
        priority: :high,
        status: :identified,
        stride: [:spoofing],
        numeric_id: 42,
        prerequisites: "some prerequisites",
        threat_action: "some threat_action",
        threat_impact: "some threat_impact",
        threat_source: "some threat_source",
        tags: ["tag1", "tag2"],
        workspace_id: workspace.id
      })
      |> Valentine.Composer.create_threat()

    threat
    |> Ecto.reset_fields([:assumptions, :mitigations])
  end

  @doc """
  Generate a assumption.
  """
  def assumption_fixture(attrs \\ %{}) do
    workspace = workspace_fixture()

    {:ok, assumption} =
      attrs
      |> Enum.into(%{
        comments: "some comments",
        content: "some content",
        tags: ["option1", "option2"],
        numeric_id: 42,
        workspace_id: workspace.id
      })
      |> Valentine.Composer.create_assumption()

    assumption
  end

  @doc """
  Generate a mitigation.
  """
  def mitigation_fixture(attrs \\ %{}) do
    workspace = workspace_fixture()

    {:ok, mitigation} =
      attrs
      |> Enum.into(%{
        comments: "some comments",
        content: "some content",
        status: :identified,
        tags: ["option1", "option2"],
        numeric_id: 42,
        workspace_id: workspace.id
      })
      |> Valentine.Composer.create_mitigation()

    mitigation
  end

  def data_flow_diagram_fixture() do
    workspace = workspace_fixture()
    Valentine.Composer.DataFlowDiagram.get(workspace.id)
  end

  @doc """
  Generate an application_information.
  """
  def application_information_fixture(attrs \\ %{}) do
    workspace = workspace_fixture()

    {:ok, application_information} =
      attrs
      |> Enum.into(%{
        content: "some content",
        workspace_id: workspace.id
      })
      |> Valentine.Composer.create_application_information()

    application_information
  end

  @doc """
  Generate an architecture.
  """
  def architecture_fixture(attrs \\ %{}) do
    workspace = workspace_fixture()

    {:ok, architecture} =
      attrs
      |> Enum.into(%{
        content: "some content",
        image: "some image",
        workspace_id: workspace.id
      })
      |> Valentine.Composer.create_architecture()

    architecture
  end
end
