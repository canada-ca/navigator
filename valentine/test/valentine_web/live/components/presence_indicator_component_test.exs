defmodule ValentineWeb.WorkspaceLive.Components.PresenceIndicatorComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias ValentineWeb.WorkspaceLive.Components.PresenceIndicatorComponent

  test "it renders no list if there is no presence" do
    html = render_component(&PresenceIndicatorComponent.render/1)
    refute html =~ "<li>"
  end

  test "renders a presence if active_module and workspace_id are nil" do
    presence = %{"some_user" => %{metas: [%{workspace_id: nil}]}}
    html = render_component(&PresenceIndicatorComponent.render/1, presence: presence)
    assert html =~ "some_user"
  end

  test "renders a presence if the workspace_id matches the workspace_id but module is nil" do
    presence = %{"some_user" => %{metas: [%{workspace_id: "some_workspace"}]}}

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        workspace_id: "some_workspace"
      )

    assert html =~ "some_user"
  end

  test "renders a presence if the active module is in a list of modules and the workspace matches" do
    presence = %{
      "some_user" => %{metas: [%{module: "some_module", workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        active_module: ["some_module", "some_other_module"],
        workspace_id: "some_workspace"
      )

    assert html =~ "some_user"
  end

  test "render a presence if the module and workspace match the active_module and workspace_id" do
    presence = %{
      "some_user" => %{metas: [%{module: "some_module", workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        active_module: "some_module",
        workspace_id: "some_workspace"
      )

    assert html =~ "some_user"
  end

  test "does not render a presence if module is nil and workplaces do not match" do
    presence = %{
      "some_user" => %{metas: [%{workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        workspace_id: "some_other_workspace"
      )

    refute html =~ "some_user"
  end

  test "does not render a presence if module is not in the active_module list" do
    presence = %{
      "some_user" => %{metas: [%{module: "some_module", workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        active_module: ["some_other_module"],
        workspace_id: "some_workspace"
      )

    refute html =~ "some_user"
  end

  test "does not render a presence if module does not match the active_module" do
    presence = %{
      "some_user" => %{metas: [%{module: "some_module", workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        active_module: "some_other_module",
        workspace_id: "some_workspace"
      )

    refute html =~ "some_user"
  end

  test "does not render a presence if the module is the same but the workspace does not match" do
    presence = %{
      "some_user" => %{metas: [%{module: "some_module", workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        active_module: "some_module",
        workspace_id: "some_other_workspace"
      )

    refute html =~ "some_user"
  end

  test "renders a presence with a border if the user_id matches the key" do
    presence = %{
      "some_user" => %{metas: [%{module: "some_module", workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        active_module: "some_module",
        workspace_id: "some_workspace",
        current_user: "some_user"
      )

    assert html =~ "border: 2px solid #fff;"
  end

  test "renders a presence with a counter color" do
    presence = %{
      "some_user" => %{metas: [%{module: "some_module", workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        active_module: "some_module",
        workspace_id: "some_workspace",
        current_user: "some_user"
      )

    assert html =~ "color: #D34AD3; background-color: #D34AD3;"
  end

  test "renders a presence with an anonymous username if it starts with ||" do
    presence = %{
      "||some_user" => %{metas: [%{module: "some_module", workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        active_module: "some_module",
        workspace_id: "some_workspace",
        current_user: "some_user"
      )

    assert html =~ "Adventurous Ant"
  end

  test "renders a presence with their username if it does not start with ||" do
    presence = %{
      "some_user" => %{metas: [%{module: "some_module", workspace_id: "some_workspace"}]}
    }

    html =
      render_component(&PresenceIndicatorComponent.render/1,
        presence: presence,
        active_module: "some_module",
        workspace_id: "some_workspace",
        current_user: "some_user"
      )

    assert html =~ "some_user"
  end
end
