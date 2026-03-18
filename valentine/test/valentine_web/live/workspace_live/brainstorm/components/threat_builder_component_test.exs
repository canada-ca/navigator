defmodule ValentineWeb.WorkspaceLive.Brainstorm.Components.ThreatBuilderComponentTest do
  use ValentineWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias Valentine.Composer
  alias ValentineWeb.WorkspaceLive.Brainstorm.Components.ThreatBuilderComponent

  describe "threat builder component" do
    setup do
      workspace = workspace_fixture()

      # Create brainstorm items for testing
      {:ok, threat_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "malicious user"
        })

      {:ok, attack_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :attack_vector,
          raw_text: "exploits SQL injection vulnerability"
        })

      {:ok, impact_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :impact,
          raw_text: "unauthorized data access"
        })

      {:ok, asset_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :asset,
          raw_text: "customer database"
        })

      %{
        workspace: workspace,
        threat_item: threat_item,
        attack_item: attack_item,
        impact_item: impact_item,
        asset_item: asset_item
      }
    end

    test "shows missing-category guidance when required cards are not yet eligible", %{
      workspace: workspace
    } do
      assigns = %{
        __changed__: %{},
        workspace_id: workspace.id,
        cluster_key: nil,
        id: "threat-builder"
      }

      html = render_component(ThreatBuilderComponent, assigns)

      assert html =~ "Statement Builder"
      assert html =~ "Only Candidate and Used cards appear here"
      assert html =~ "More brainstorm cards are needed"
      assert html =~ "No eligible threat cards available"
      assert html =~ "No eligible asset cards available"
    end

    test "renders eligible card choices once required items are candidates", %{
      workspace: workspace,
      threat_item: threat_item,
      attack_item: attack_item,
      impact_item: impact_item,
      asset_item: asset_item
    } do
      promote_to_candidate(threat_item)
      promote_to_candidate(attack_item)
      promote_to_candidate(impact_item)
      promote_to_candidate(asset_item)

      assigns = %{
        __changed__: %{},
        workspace_id: workspace.id,
        cluster_key: nil,
        id: "threat-builder"
      }

      html = render_component(ThreatBuilderComponent, assigns)

      assert html =~ "Statement Builder"
      assert html =~ "Select threat..."
      assert html =~ "Select attack vector..."
      assert html =~ "Threat Impact"
      assert html =~ "malicious user"
      assert html =~ "customer database"
      refute html =~ "Required</span>"
    end

    test "labels used cards in the selector", %{
      workspace: workspace,
      threat_item: threat_item,
      attack_item: attack_item,
      impact_item: impact_item,
      asset_item: asset_item
    } do
      promote_to_candidate(threat_item)
      promote_to_candidate(attack_item)
      promote_to_candidate(impact_item)
      {:ok, asset_item} = promote_to_candidate(asset_item)

      {:ok, _asset_item} = Composer.update_brainstorm_item(asset_item, %{status: :used})

      assigns = %{
        __changed__: %{},
        workspace_id: workspace.id,
        cluster_key: nil,
        id: "threat-builder"
      }

      html = render_component(ThreatBuilderComponent, assigns)

      assert html =~ "Statement Builder"
      assert html =~ "customer database (already used)"
    end

    test "renders asset selection as multi-select checkboxes", %{
      workspace: workspace,
      threat_item: threat_item,
      attack_item: attack_item,
      impact_item: impact_item,
      asset_item: asset_item
    } do
      promote_to_candidate(threat_item)
      promote_to_candidate(attack_item)
      promote_to_candidate(impact_item)
      promote_to_candidate(asset_item)

      {:ok, second_asset} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :asset,
          raw_text: "billing service"
        })

      promote_to_candidate(second_asset)

      assigns = %{
        __changed__: %{},
        workspace_id: workspace.id,
        cluster_key: nil,
        id: "threat-builder"
      }

      html = render_component(ThreatBuilderComponent, assigns)

      assert html =~ "Select one or more impacted assets."
      assert html =~ "name=\"asset[]\""
      assert html =~ "customer database"
      assert html =~ "billing service"
    end
  end

  defp promote_to_candidate(item) do
    {:ok, item} = Composer.update_brainstorm_item(item, %{status: :clustered})
    {:ok, _item} = Composer.update_brainstorm_item(item, %{status: :candidate})
  end
end
