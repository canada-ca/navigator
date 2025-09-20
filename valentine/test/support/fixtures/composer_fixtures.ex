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
        name: "some name",
        cloud_profile: "some cloud_profile",
        cloud_profile_type: "some cloud_profile_type",
        url: "some url",
        owner: "some owner",
        permissions: %{}
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
        status: :confirmed,
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

  def data_flow_diagram_fixture(attr \\ %{}) do
    workspace =
      if attr[:workspace_id] do
        Valentine.Composer.get_workspace!(attr[:workspace_id])
      else
        workspace_fixture()
      end

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

  @doc """
  Generate an reference_pack_item.
  """
  def reference_pack_item_fixture(attrs \\ %{}) do
    {:ok, reference_pack_item} =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description",
        collection_id: random_uuid(),
        collection_type: :mitigation,
        collection_name: "some collection_name",
        data: %{"content" => "some content"}
      })
      |> Valentine.Composer.create_reference_pack_item()

    reference_pack_item
  end

  @doc """
  Generate an control.
  """
  def control_fixture(attrs \\ %{}) do
    {:ok, control} =
      attrs
      |> Enum.into(%{
        name: "some name",
        class: "some class",
        description: "some description",
        guidance: "some guidance",
        nist_id: "some nist_id",
        nist_family: "some nist_family",
        stride: [:spoofing],
        tags: ["tag1", "tag2"]
      })
      |> Valentine.Composer.create_control()

    control
  end

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "some.user@localhost"
      })
      |> Valentine.Composer.create_user()

    user
  end

  @doc """
  Generate an API key.
  """
  def api_key_fixture(attrs \\ %{}) do
    workspace = workspace_fixture()

    {:ok, api_key} =
      attrs
      |> Enum.into(%{
        owner: "some owner",
        label: "some label",
        status: :active,
        last_used: DateTime.utc_now(),
        workspace_id: workspace.id
      })
      |> Valentine.Composer.create_api_key()

    api_key
  end

  @doc """
  Generate evidence.
  """
  def evidence_fixture(attrs \\ %{}) do
    workspace = workspace_fixture()

    {:ok, evidence} =
      attrs
      |> Enum.into(%{
        name: "some evidence",
        description: "some description",
        evidence_type: :json_data,
        content: %{"document_type" => "OSCAL", "data" => "some data"},
        nist_controls: ["AC-1", "SC-7.4"],
        tags: ["security", "compliance"],
        workspace_id: workspace.id
      })
      |> Valentine.Composer.create_evidence()

    evidence
  end

  @doc """
  Generate blob store evidence.
  """
  def blob_evidence_fixture(attrs \\ %{}) do
    workspace = workspace_fixture()

    {:ok, evidence} =
      attrs
      |> Enum.into(%{
        name: "some blob evidence",
        description: "some external file description",
        evidence_type: :blob_store_link,
        blob_store_url: "https://example.com/evidence/document.pdf",
        nist_controls: ["AU-12"],
        tags: ["external", "document"],
        workspace_id: workspace.id
      })
      |> Valentine.Composer.create_evidence()

    evidence
  end

  @doc """
  Generate a brainstorm item.
  """
  def brainstorm_item_fixture(attrs \\ %{}) do
    workspace = workspace_fixture()

    {:ok, brainstorm_item} =
      attrs
      |> Enum.into(%{
        workspace_id: workspace.id,
        type: :threat,
        raw_text: "some brainstorm item text"
      })
      |> Valentine.Composer.create_brainstorm_item()

    brainstorm_item
  end
end
