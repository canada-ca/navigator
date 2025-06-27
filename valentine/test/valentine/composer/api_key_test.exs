defmodule Valentine.Composer.ApiKeyTest do
  use ExUnit.Case, async: true

  alias Valentine.Composer.ApiKey

  setup do
    workspace_id = System.unique_integer([:positive])
    {:ok, workspace_id: workspace_id}
  end

  test "generate_key/1 adds a JWT key to the api_key struct", %{workspace_id: workspace_id} do
    api_key = %ApiKey{
      id: "test-id",
      owner: "test-owner",
      label: "test-label",
      status: :active,
      workspace_id: workspace_id
    }

    updated_api_key = ApiKey.generate_key(api_key)

    assert updated_api_key.key != nil
    assert updated_api_key.id == api_key.id
  end
end
