defmodule Valentine.Prompts.PromptRegistry do
  alias Valentine.Prompts.{
    ApplicationInformation,
    DataFlow,
    Architecture,
    Threat,
    Assumption,
    Mitigation,
    # ThreatModel
    Workspace
  }

  @modules %{
    "ApplicationInformation" => ApplicationInformation,
    "Index" => Workspace,
    "DataFlow" => DataFlow,
    "Architecture" => Architecture,
    "Threat" => Threat,
    "Assumption" => Assumption,
    "Mitigation" => Mitigation
    # "ThreatModel" => ThreatModel
  }

  def extract_images(content) do
    # Extract all image tags from the content
    image_tags = Regex.scan(~r{<img[^>]*>}, content) |> List.flatten()

    # Remove the image tags from the content
    content = Regex.replace(~r{<img[^>]*>}, content, "")

    [
      %{
        "type" => "text",
        "text" => content
      }
    ]
    |> Enum.concat(
      Enum.map(image_tags, fn tag ->
        %{
          "type" => "image_url",
          "image_url" => %{"url" => Regex.named_captures(~r{src="(?<url>[^"]+)"}, tag)["url"]}
        }
      end)
    )

    # For now just remove the images to save on tokens while this is being rejigged.
    content
  end

  def get_schema(_module_name, _action), do: base_schema()

  def get_system_prompt(module_name, action, workspace_id) do
    case Map.get(@modules, module_name) do
      nil ->
        base_prompt()

      module ->
        extract_images(base_prompt() <> module.system_prompt(workspace_id, action))
    end
  end

  def get_tag_line(module_name, action) do
    case Map.get(@modules, module_name) do
      nil -> random_tag_line()
      module -> module.tag_line(action)
    end
  end

  def base_prompt() do
    """
    FACTS:
    1. You are an expert threat modeling assistant focused on helping users manage their workspaces effectively.
    2. Each workspace contains multiple components: application information, architecture, data flows, assumptions, threats, and mitigations. Depending on context, more information about each of these will be provided to you.
    3. Respond with clear, direct prose only.
    """
  end

  def base_schema() do
    %{
      name: "chat_reponse",
      strict: true,
      schema: %{
        type: "object",
        properties: %{
          content: %{
            type: "string",
            description: "The main response text that will be shown to the user"
          }
        },
        required: ["content"],
        additionalProperties: false
      }
    }
  end

  defp random_tag_line() do
    [
      "The pastry chef kneaded a break from his job.",
      "Time flies when you're a watchmaker.",
      "The mathematician counted on his fingers.",
      "That vegetable gardener really knows how to turnip.",
      "The optometrist made a spectacle of himself.",
      "The astronaut needed some space to think.",
      "Piano teachers always note their students' progress.",
      "The electrician conducted himself with shocking professionalism.",
      "The tired calendar just needed a few more dates.",
      "That cheese joke wasn't very mature."
    ]
    |> Enum.random()
  end
end
