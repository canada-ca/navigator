defmodule Valentine.ControlCategorizerTest do
  use Valentine.DataCase

  import Mock
  import Valentine.ComposerFixtures

  alias Valentine.ControlCategorizer

  describe "normalize_response/1" do
    test "normalizes and sorts controls with string or atom keys" do
      assert ControlCategorizer.normalize_response(%{
               controls: [
                 %{control: "AC-2", name: "Accounts", rational: "Needed"},
                 %{"control" => "AC-1", "name" => "Policy", "rational" => "Because"}
               ]
             }) == [
               %{"control" => "AC-1", "name" => "Policy", "rational" => "Because"},
               %{"control" => "AC-2", "name" => "Accounts", "rational" => "Needed"}
             ]
    end
  end

  describe "suggest/2" do
    test "uses the shared structured-output request and normalizes its response" do
      mitigation = mitigation_fixture(%{comments: "Confirm provider support"})
      mitigation = Valentine.Composer.get_mitigation!(mitigation.id, [:threats])

      with_mock ReqLLM,
        generate_object!: fn model_spec, context, schema, opts ->
          user_message = Enum.find(context.messages, &(&1.role == :user))
          user_text = user_message.content |> List.first() |> Map.fetch!(:text)

          assert model_spec.provider == :openai
          assert user_text =~ "Confirm provider support"
          assert get_in(schema, ["properties", "controls", "type"]) == "array"
          assert is_binary(opts[:base_url]) and opts[:base_url] != ""

          %{
            "controls" => %{
              control: "AC-1",
              name: "Policy",
              rational: "Because"
            }
          }
        end do
        assert ControlCategorizer.suggest(:mitigation, mitigation) ==
                 {:ok, [%{"control" => "AC-1", "name" => "Policy", "rational" => "Because"}]}
      end
    end
  end

  describe "selected_tags/1" do
    test "returns only selected control IDs" do
      assert ControlCategorizer.selected_tags(%{
               "AC-1" => "true",
               "AC-2" => "false",
               "SA-1" => "true"
             }) == ["AC-1", "SA-1"]
    end
  end

  describe "prompts/2" do
    test "builds an assumption-specific prompt with linked context" do
      assumption = assumption_fixture(%{comments: "Verify this assumption"})

      mitigation =
        mitigation_fixture(%{
          workspace_id: assumption.workspace_id,
          content: "Require phishing-resistant authentication"
        })

      {:ok, assumption} = Valentine.Composer.add_mitigation_to_assumption(assumption, mitigation)
      assumption = Valentine.Composer.get_assumption!(assumption.id, [:mitigations, :threats])

      prompts = ControlCategorizer.prompts(:assumption, assumption)

      assert prompts.system =~ "categorize the assumption"
      assert prompts.user =~ "Verify this assumption"
      assert prompts.user =~ "Require phishing-resistant authentication"
    end

    test "uses mitigation comments instead of repeating mitigation content" do
      mitigation =
        mitigation_fixture(%{
          content: "Require phishing-resistant authentication",
          comments: "Confirm support with the identity provider"
        })

      mitigation = Valentine.Composer.get_mitigation!(mitigation.id, [:threats])
      prompts = ControlCategorizer.prompts(:mitigation, mitigation)

      assert prompts.system =~ "categorize the mitigation"
      assert prompts.user =~ "Comments about this mitigation:"
      assert prompts.user =~ "Confirm support with the identity provider"
      refute prompts.user =~ "Comments about this mitigation:application"
    end
  end

  describe "save_tags/3" do
    test "persists tags for assumptions and mitigations" do
      assumption = assumption_fixture(%{tags: ["existing"]})
      mitigation = mitigation_fixture(%{tags: ["existing"]})

      assert {:ok, updated_assumption} =
               ControlCategorizer.save_tags(:assumption, assumption, ["AC-1"])

      assert {:ok, updated_mitigation} =
               ControlCategorizer.save_tags(:mitigation, mitigation, ["SC-7"])

      assert updated_assumption.tags == ["existing", "AC-1"]
      assert updated_mitigation.tags == ["existing", "SC-7"]
    end
  end
end
