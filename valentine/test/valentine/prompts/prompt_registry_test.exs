defmodule Valentine.Prompts.PromptRegistryTest do
  use ValentineWeb.ConnCase
  alias Valentine.Prompts.PromptRegistry

  import Valentine.ComposerFixtures

  describe "get_schema/2" do
    test "returns the base schema if the module does not exist" do
      assert PromptRegistry.get_schema(
               "NonExistentModule",
               "some_action"
             ) ==
               %{
                 name: "chat_reponse",
                 schema: %{
                   type: "object",
                   required: ["content"],
                   additionalProperties: false,
                   properties: %{
                     content: %{
                       type: "string",
                       description: "The main response text that will be shown to the user"
                     }
                   }
                 },
                 strict: true
               }
    end

    test "returns the base schema for workspace chat" do
      assert PromptRegistry.get_schema(
               "Index",
               "some_action"
             ) ==
               %{
                 name: "chat_reponse",
                 schema: %{
                   type: "object",
                   required: ["content"],
                   additionalProperties: false,
                   properties: %{
                     content: %{
                       type: "string",
                       description: "The main response text that will be shown to the user"
                     }
                   }
                 },
                 strict: true
               }
    end
  end

  describe "get_system_prompt/3" do
    test "returns the default system prompt if the module does not exist" do
      assert PromptRegistry.get_system_prompt(
               "NonExistentModule",
               "some_action",
               "some_workspace_id"
             ) =~
               "Respond with clear, direct prose only."
    end

    test "returns ApplicationInformation prompt" do
      workspace = workspace_fixture()

      assert PromptRegistry.get_system_prompt(
               "ApplicationInformation",
               "some_action",
               workspace.id
             ) =~
               Valentine.Prompts.ApplicationInformation.system_prompt(workspace.id, "some_action")
    end
  end

  describe "get_tag_line/2" do
    test "returns a random tag line if module_name and action do not exist" do
      assert String.length(
               PromptRegistry.get_tag_line(
                 "NonExistentModule",
                 "some_action"
               )
             ) > 0
    end

    test "returns ApplicationInformation tag line" do
      assert PromptRegistry.get_tag_line(
               "ApplicationInformation",
               :index
             ) ==
               Valentine.Prompts.ApplicationInformation.tag_line(:index)
    end
  end
end
