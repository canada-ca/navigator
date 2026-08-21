defmodule Valentine.ComposerContextBoundariesTest do
  use Valentine.DataCase

  alias Valentine.Composer.AnalysisJobs
  alias Valentine.Composer.ApiKeys
  alias Valentine.Composer.Assumptions
  alias Valentine.Composer.Brainstorm
  alias Valentine.Composer.Controls
  alias Valentine.Composer.Documents
  alias Valentine.Composer.EvidenceManagement
  alias Valentine.Composer.Mitigations
  alias Valentine.Composer.ReferencePacks
  alias Valentine.Composer.Relationships
  alias Valentine.Composer.Threats
  alias Valentine.Composer.Users
  alias Valentine.Composer.Workspaces

  import Valentine.ComposerFixtures

  @capability_modules [
    AnalysisJobs,
    ApiKeys,
    Assumptions,
    Brainstorm,
    Controls,
    Documents,
    EvidenceManagement,
    Mitigations,
    ReferencePacks,
    Relationships,
    Threats,
    Users,
    Workspaces
  ]

  test "workspace and analysis APIs work through their capability owners" do
    workspace = workspace_fixture()

    analysis_job =
      repo_analysis_agent_fixture(%{workspace_id: workspace.id, owner: workspace.owner})

    assert Workspaces.get_workspace!(workspace.id) == workspace

    assert Enum.map(AnalysisJobs.list_repo_analysis_agents_by_workspace(workspace.id), & &1.id) ==
             [
               analysis_job.id
             ]
  end

  test "core entity APIs preserve filters, workspace isolation, and bang behavior" do
    workspace = workspace_fixture()
    other_workspace = workspace_fixture()
    threat = threat_fixture(%{workspace_id: workspace.id, status: :identified})
    assumption = assumption_fixture(%{workspace_id: workspace.id, status: :confirmed})
    mitigation = mitigation_fixture(%{workspace_id: workspace.id, status: :identified})

    assert Enum.map(
             Threats.list_threats_by_workspace(workspace.id, %{status: ["identified"]}),
             & &1.id
           ) == [
             threat.id
           ]

    assert Assumptions.list_assumptions_by_workspace(workspace.id, %{status: ["confirmed"]}) == [
             assumption
           ]

    assert Mitigations.list_mitigations_by_workspace(workspace.id, %{status: ["identified"]}) == [
             mitigation
           ]

    assert Threats.get_threat_for_workspace(other_workspace.id, threat.id) == nil

    assert_raise Ecto.NoResultsError, fn ->
      Threats.get_threat_for_workspace!(other_workspace.id, threat.id)
    end
  end

  test "relationship and evidence APIs preserve association results" do
    workspace = workspace_fixture()
    evidence = evidence_fixture(%{workspace_id: workspace.id})
    assumption = assumption_fixture(%{workspace_id: workspace.id})

    assert {:ok, linked_evidence} =
             Relationships.add_assumption_to_evidence(evidence, assumption)

    assert Enum.map(linked_evidence.assumptions, & &1.id) == [assumption.id]

    assert Enum.map(
             EvidenceManagement.get_evidence!(evidence.id, [:assumptions]).assumptions,
             & &1.id
           ) == [
             assumption.id
           ]
  end

  test "document, reference, and control APIs are available through their owners" do
    application_information = application_information_fixture()
    architecture = architecture_fixture()
    reference_pack_item = reference_pack_item_fixture()
    control = control_fixture()

    assert Documents.get_application_information!(application_information.id) ==
             application_information

    assert Documents.get_architecture!(architecture.id) == architecture

    assert ReferencePacks.get_reference_pack_item!(reference_pack_item.id) == reference_pack_item
    assert Controls.get_control!(control.id) == control
  end

  test "identity, API key, and brainstorm APIs are available through their owners" do
    user = user_fixture()
    api_key = api_key_fixture()
    brainstorm_item = brainstorm_item_fixture()

    assert Users.get_user(user.email) == user
    assert ApiKeys.get_api_key(api_key.id).id == api_key.id

    assert Brainstorm.get_brainstorm_item(brainstorm_item.workspace_id, brainstorm_item.id).id ==
             brainstorm_item.id
  end

  test "the broad facade is absent and capabilities remain directly loadable" do
    refute File.exists?(Path.expand("../../lib/valentine/composer.ex", __DIR__))

    for module <- @capability_modules do
      assert Code.ensure_loaded?(module)

      source = module_source(module)
      refute source =~ ~r/^\s+alias Valentine\.Composer\s*$/m
      refute source =~ ~r/(?<!Valentine\.)\bComposer\./
    end
  end

  test "application and test source contain no facade aliases or calls" do
    project_root = Path.expand("../..", __DIR__)

    facade_references =
      project_root
      |> Path.join("{lib,test}/**/*.{ex,exs}")
      |> Path.wildcard()
      |> Enum.flat_map(fn path ->
        source = File.read!(path)

        if source =~ ~r/^\s*defmodule Valentine\.Composer\s+do/m or
             source =~ ~r/^\s*alias Valentine\.Composer\s*$/m or
             source =~ ~r/\b(?:Valentine\.)?Composer\.[a-z_][a-zA-Z0-9_!?]*/ do
          [Path.relative_to(path, project_root)]
        else
          []
        end
      end)

    assert facade_references == []
  end

  defp module_source(module) do
    filename =
      module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    File.read!(Path.expand("../../lib/valentine/composer/#{filename}.ex", __DIR__))
  end
end
