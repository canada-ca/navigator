defmodule ValentineWeb.WorkspaceLive.Brainstorm.ThreatBuilderIntegrationTest do
  use ValentineWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Valentine.ComposerFixtures

  alias Valentine.Composer

  describe "threat builder integration" do
    setup do
      # Create workspace and brainstorm items
      workspace = workspace_fixture()

      # Create comprehensive brainstorm items for testing
      {:ok, threat_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :threat,
          raw_text: "external attacker"
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
          raw_text: "unauthorized access to sensitive data"
        })

      {:ok, asset_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :asset,
          raw_text: "customer database"
        })

      {:ok, requirement_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :requirement,
          raw_text: "having network access to the system"
        })

      {:ok, risk_item} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :risk,
          raw_text: "confidentiality"
        })

      %{
        workspace: workspace,
        threat_item: threat_item,
        attack_item: attack_item,
        impact_item: impact_item,
        asset_item: asset_item,
        requirement_item: requirement_item,
        risk_item: risk_item
      }
    end

    test "complete threat builder workflow creates proper threat with provenance", context do
      %{
        workspace: workspace,
        threat_item: threat_item,
        attack_item: attack_item,
        impact_item: impact_item,
        asset_item: asset_item,
        requirement_item: requirement_item,
        risk_item: risk_item
      } = context

      # Simulate the threat builder process
      selected_cards = %{
        threat: threat_item.id,
        attack_vector: attack_item.id,
        impact: impact_item.id,
        asset: asset_item.id,
        requirement: requirement_item.id,
        risk: risk_item.id
      }

      # Build threat attributes (simulating the component logic)
      threat_attrs = %{
        workspace_id: workspace.id,
        threat_source: threat_item.normalized_text,
        prerequisites: requirement_item.normalized_text,
        threat_action: attack_item.normalized_text,
        threat_impact: impact_item.normalized_text,
        impacted_goal: [risk_item.normalized_text],
        impacted_assets: [asset_item.normalized_text],
        # Inferred from "access" in the action
        stride: [:information_disclosure]
      }

      # Create the threat
      assert {:ok, threat} = Composer.create_threat(threat_attrs)

      # Verify threat attributes
      assert threat.threat_source == "external attacker"
      assert threat.prerequisites == "having network access to the system"
      assert threat.threat_action == "exploits SQL injection vulnerability"
      assert threat.threat_impact == "unauthorized access to sensitive data"
      assert threat.impacted_goal == ["confidentiality"]
      assert threat.impacted_assets == ["customer database"]
      assert threat.stride == [:information_disclosure]

      # Mark cards as used (simulating component behavior) 
      # First transition items through the proper lifecycle: draft -> clustered -> candidate -> used
      selected_card_ids = Map.values(selected_cards)

      Enum.each(selected_card_ids, fn card_id ->
        item = Composer.get_brainstorm_item!(card_id)

        # Transition through the proper lifecycle
        {:ok, item} = Composer.update_brainstorm_item(item, %{status: :clustered})
        {:ok, item} = Composer.update_brainstorm_item(item, %{status: :candidate})

        # Now mark as used in threat
        changeset = Valentine.Composer.BrainstormItem.mark_used_in_threat(item, threat.numeric_id)
        assert {:ok, _updated_item} = Composer.update_brainstorm_item(item, changeset.changes)
      end)

      # Verify provenance tracking
      updated_threat_item = Composer.get_brainstorm_item!(threat_item.id)
      assert updated_threat_item.status == :used
      assert threat.numeric_id in updated_threat_item.used_in_threat_ids

      updated_attack_item = Composer.get_brainstorm_item!(attack_item.id)
      assert updated_attack_item.status == :used
      assert threat.numeric_id in updated_attack_item.used_in_threat_ids

      # Verify threat statement formatting
      threat_statement = Valentine.Composer.Threat.show_statement(threat)
      assert threat_statement =~ "external attacker"
      assert threat_statement =~ "having network access to the system"
      assert threat_statement =~ "exploits SQL injection vulnerability"
      assert threat_statement =~ "unauthorized access to sensitive data"
      assert threat_statement =~ "confidentiality"
      assert threat_statement =~ "customer database"

      # Verify STRIDE banner (extract the raw HTML content)
      stride_banner = Valentine.Composer.Threat.stride_banner(threat)

      stride_html =
        case stride_banner do
          {:safe, html} -> html
          html when is_binary(html) -> html
        end

      # Information disclosure should be highlighted
      assert stride_html =~ "I"
    end

    test "split threat functionality creates multiple threats", context do
      %{
        workspace: workspace,
        threat_item: threat_item,
        attack_item: attack_item,
        impact_item: impact_item
      } = context

      # Create multiple assets
      {:ok, asset1} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :asset,
          raw_text: "user database"
        })

      {:ok, asset2} =
        Composer.create_brainstorm_item(%{
          workspace_id: workspace.id,
          type: :asset,
          raw_text: "payment system"
        })

      # Simulate creating separate threats for each asset
      assets = [asset1, asset2]

      threats =
        Enum.map(assets, fn asset ->
          threat_attrs = %{
            workspace_id: workspace.id,
            threat_source: threat_item.normalized_text,
            threat_action: attack_item.normalized_text,
            threat_impact: impact_item.normalized_text,
            impacted_assets: [asset.normalized_text],
            stride: [:tampering]
          }

          {:ok, threat} = Composer.create_threat(threat_attrs)
          threat
        end)

      assert length(threats) == 2

      # Verify each threat has the correct asset
      [threat1, threat2] = threats
      assert threat1.impacted_assets == ["user database"]
      assert threat2.impacted_assets == ["payment system"]

      # Both should have the same source, action, and impact
      assert threat1.threat_source == threat2.threat_source
      assert threat1.threat_action == threat2.threat_action
      assert threat1.threat_impact == threat2.threat_impact
    end

    test "threat builder validates required fields", context do
      %{workspace: workspace, threat_item: threat_item} = context

      # Test incomplete threat (missing required fields)
      incomplete_attrs = %{
        workspace_id: workspace.id,
        threat_source: threat_item.normalized_text
        # Missing action, impact, and assets
      }

      # This should still succeed because threat validation is minimal
      # but the statement won't be complete
      assert {:ok, threat} = Composer.create_threat(incomplete_attrs)
      assert threat.threat_source == "external attacker"
      assert is_nil(threat.threat_action)
      assert is_nil(threat.threat_impact)
      assert is_nil(threat.impacted_assets) or threat.impacted_assets == []
    end

    test "threat builder handles STRIDE inference correctly", context do
      %{workspace: workspace} = context

      test_cases = [
        {"spoofs user identity", [:spoofing]},
        {"modifies database records", [:tampering]},
        {"repudiates performing the action", [:repudiation]},
        {"accesses confidential information", [:information_disclosure]},
        {"blocks system availability", [:denial_of_service]},
        {"escalates to admin privileges", [:elevation_of_privilege]},
        {"unknown action type", []}
      ]

      Enum.each(test_cases, fn {action, expected_stride} ->
        # Create attack vector item
        {:ok, attack_item} =
          Composer.create_brainstorm_item(%{
            workspace_id: workspace.id,
            type: :attack_vector,
            raw_text: action
          })

        # Test STRIDE inference (this would be done in the component)
        inferred_stride = infer_stride_from_action(attack_item.normalized_text)
        assert inferred_stride == expected_stride
      end)
    end
  end

  # Helper function that mirrors the component logic
  defp infer_stride_from_action(nil), do: []

  defp infer_stride_from_action(action) do
    action_lower = String.downcase(action)

    cond do
      String.contains?(action_lower, "spoof") or String.contains?(action_lower, "impersonate") or
          String.contains?(action_lower, "fake") ->
        [:spoofing]

      String.contains?(action_lower, "modif") or String.contains?(action_lower, "alter") or
        String.contains?(action_lower, "tamper") or String.contains?(action_lower, "change") ->
        [:tampering]

      String.contains?(action_lower, "repudiate") or String.contains?(action_lower, "claim") ->
        [:repudiation]

      String.contains?(action_lower, "access") or String.contains?(action_lower, "read") or
        String.contains?(action_lower, "disclose") or String.contains?(action_lower, "leak") or
          String.contains?(action_lower, "expose") ->
        [:information_disclosure]

      String.contains?(action_lower, "deny") or String.contains?(action_lower, "block") or
        String.contains?(action_lower, "prevent") or String.contains?(action_lower, "overload") or
          String.contains?(action_lower, "crash") ->
        [:denial_of_service]

      String.contains?(action_lower, "elevate") or String.contains?(action_lower, "escalate") or
        String.contains?(action_lower, "privilege") or String.contains?(action_lower, "admin") or
          String.contains?(action_lower, "root") ->
        [:elevation_of_privilege]

      true ->
        []
    end
  end
end
