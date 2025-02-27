defmodule ValentineWeb.WorkspaceLive.Threat.ShowTest do
  use ValentineWeb.ConnCase
  alias Valentine.Composer
  alias Valentine.Repo
  import Mock

  import Valentine.ComposerFixtures

  setup do
    workspace = workspace_fixture()
    threat = threat_fixture(%{workspace_id: workspace.id})

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        active_field: nil,
        changes: nil,
        live_action: nil,
        flash: %{},
        current_user: workspace.owner,
        threat: nil,
        toggle_goals: false,
        workspace_id: nil
      }
    }

    {:ok, %{workspace: workspace, threat: threat, socket: socket}}
  end

  describe "mount/3" do
    test "assigns workspace_id and initializes view", %{socket: socket, workspace: workspace} do
      {:ok, socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.mount(
          %{"workspace_id" => workspace.id},
          %{},
          socket
        )

      assert socket.assigns.active_type == nil
      assert socket.assigns.errors == nil
      assert socket.assigns.toggle_goals == false
      assert socket.assigns.workspace_id == workspace.id
    end
  end

  describe "handle_params/3" do
    test "sets page title for new action", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.live_action, :new)
      socket = put_in(socket.assigns.workspace_id, workspace.id)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_params(
          %{"workspace_id" => workspace.id},
          "",
          socket
        )

      assert updated_socket.assigns.page_title == "Create new threat statement"
      assert updated_socket.assigns.threat == %Composer.Threat{}
      assert updated_socket.assigns.changes == %{workspace_id: workspace.id}
    end

    test "sets page title for edit action", %{
      socket: socket,
      threat: threat,
      workspace: workspace
    } do
      socket = put_in(socket.assigns.live_action, :edit)
      socket = put_in(socket.assigns.workspace_id, workspace.id)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_params(
          %{"id" => threat.id, "workspace_id" => workspace.id},
          "",
          socket
        )

      threat = Repo.preload(threat, [:assumptions, :mitigations])

      assert updated_socket.assigns.page_title == "Edit threat statement"
      assert updated_socket.assigns.threat == threat
      assert updated_socket.assigns.changes == Map.from_struct(threat)
    end
  end

  describe "handle_event save" do
    test "creates new threat successfully", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.threat, %Composer.Threat{workspace_id: workspace.id})

      with_mock Composer,
        create_threat: fn _params -> {:ok, %{workspace_id: workspace.id, id: "abcd"}} end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
            "save",
            %{"threat" => %{"title" => "New Threat"}},
            socket
          )

        assert updated_socket.assigns.flash["info"] =~ "created successfully"
      end
    end

    test "creates new  threat unsuccessfully", %{socket: socket, workspace: workspace} do
      socket = put_in(socket.assigns.threat, %Composer.Threat{workspace_id: workspace.id})

      with_mock Composer,
        create_threat: fn _params -> {:error, %Ecto.Changeset{}} end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
            "save",
            %{"threat" => %{"title" => "New Threat"}},
            socket
          )

        assert updated_socket.assigns.errors == %Ecto.Changeset{}.errors
      end
    end

    test "updates existing threat successfully", %{socket: socket, threat: threat} do
      socket = put_in(socket.assigns.threat, threat)

      with_mock Composer,
        update_threat: fn _threat, _params -> {:ok, threat} end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
            "save",
            %{"threat" => %{"title" => "Updated Threat"}},
            socket
          )

        assert updated_socket.assigns.flash["info"] =~ "updated successfully"
      end
    end

    test "updates existing threat unsuccessfully", %{socket: socket, threat: threat} do
      socket = put_in(socket.assigns.threat, threat)

      with_mock Composer,
        update_threat: fn _threat, _params -> {:error, %Ecto.Changeset{}} end do
        {:noreply, updated_socket} =
          ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
            "save",
            %{"threat" => %{"title" => "Updated Threat"}},
            socket
          )

        assert updated_socket.assigns.errors == %Ecto.Changeset{}.errors
      end
    end
  end

  describe "handle_event show_context" do
    test "assigns active field and context", %{socket: socket} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
          "show_context",
          %{"field" => "threat_source", "type" => "text"},
          socket
        )

      assert updated_socket.assigns.active_field == :threat_source
      assert updated_socket.assigns.active_type == "text"
      assert Map.has_key?(updated_socket.assigns, :context)
    end
  end

  describe "handle_event toggle_goals" do
    test "toggles goals", %{socket: socket} do
      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event("toggle_goals", %{}, socket)

      assert updated_socket.assigns.toggle_goals == true
    end
  end

  describe "handle_event update_field" do
    test "updates field value in changeset", %{socket: socket} do
      socket = put_in(socket.assigns.active_field, :threat_source)
      socket = put_in(socket.assigns.changes, %{})

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
          "update_field",
          %{"value" => "New Threat"},
          socket
        )

      assert updated_socket.assigns.changes[:threat_source] == "New Threat"
    end

    test "updates field value in changeset if coming from a form and is a list", %{socket: socket} do
      socket = put_in(socket.assigns.changes, %{})

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
          "update_field",
          %{"_target" => ["field"], "field" => ["threat"]},
          socket
        )

      assert updated_socket.assigns.changes[:field] == [:threat]
    end

    test "updates field value in changeset if coming from a form and is a list and filters false values",
         %{socket: socket} do
      socket = put_in(socket.assigns.changes, %{})

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
          "update_field",
          %{"_target" => ["field"], "field" => ["threat", "false"]},
          socket
        )

      assert updated_socket.assigns.changes[:field] == [:threat]
    end

    test "updates field value in changeset if coming from a form and is a binary", %{
      socket: socket
    } do
      socket = put_in(socket.assigns.changes, %{})

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
          "update_field",
          %{"_target" => ["field"], "field" => "Threat"},
          socket
        )

      assert updated_socket.assigns.changes[:field] == "threat"
    end

    test "updates field value in changeset if coming from a form and is a comments field", %{
      socket: socket
    } do
      socket = put_in(socket.assigns.changes, %{})

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
          "update_field",
          %{"_target" => ["comments"], "comments" => "Comments"},
          socket
        )

      assert updated_socket.assigns.changes[:comments] == "Comments"
    end

    test "updates field value in changeset to nil if there are no matches", %{
      socket: socket
    } do
      socket = put_in(socket.assigns.changes, %{})

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
          "update_field",
          %{"_target" => ["foo"], "bar" => 2},
          socket
        )

      assert updated_socket.assigns.changes[:foo] == nil
    end
  end

  describe "handle_event removes an assumption" do
    test "removes an assumption", %{socket: socket, threat: threat} do
      assumption = assumption_fixture()

      Composer.add_assumption_to_threat(threat, assumption)

      socket = put_in(socket.assigns.threat, threat)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
          "remove_assumption",
          %{"id" => assumption.id},
          socket
        )

      assert updated_socket.assigns.threat.assumptions == []
    end
  end

  describe "handle_event removes a mitigation" do
    test "removes a mitigation", %{socket: socket, threat: threat} do
      mitigation = mitigation_fixture()

      Composer.add_mitigation_to_threat(threat, mitigation)

      socket = put_in(socket.assigns.threat, threat)

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_event(
          "remove_mitigation",
          %{"id" => mitigation.id},
          socket
        )

      assert updated_socket.assigns.threat.mitigations == []
    end
  end

  describe "handle_info/2 to update field values" do
    test "updates field value in changeset", %{socket: socket} do
      socket = put_in(socket.assigns.active_field, :threat_source)
      socket = put_in(socket.assigns.changes, %{})

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_info(
          {"update_field", %{"value" => "New Threat"}},
          socket
        )

      assert updated_socket.assigns.changes[:threat_source] == "New Threat"
    end
  end

  describe "hande_info/2 to add a newely created assumption to a threat" do
    test "adds a newly created assumption to a threat", %{socket: socket, threat: threat} do
      socket = put_in(socket.assigns.threat, threat)

      assumption = assumption_fixture()

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_info(
          {"assumptions", {:saved, assumption}},
          socket
        )

      assert updated_socket.assigns.threat.assumptions == [assumption]
    end
  end

  describe "hande_info/2 to add a newely created mitigation to a threat" do
    test "adds a newly created mitigation to a threat", %{socket: socket, threat: threat} do
      socket = put_in(socket.assigns.threat, threat)

      mitigation = mitigation_fixture()

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_info(
          {"mitigations", {:saved, mitigation}},
          socket
        )

      assert updated_socket.assigns.threat.mitigations == [mitigation]
    end
  end

  describe "handle_info/2 to add an assumption to a threat" do
    test "adds an assumption to a threat", %{socket: socket, threat: threat} do
      socket = put_in(socket.assigns.threat, threat)

      assumption = assumption_fixture()

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_info(
          {"assumptions", :selected_item, assumption},
          socket
        )

      assert updated_socket.assigns.threat.assumptions == [assumption]
    end
  end

  describe "handle_info/2 to add a mitigation to a threat" do
    test "adds an mitigation to a threat", %{socket: socket, threat: threat} do
      socket = put_in(socket.assigns.threat, threat)

      mitigation = mitigation_fixture()

      {:noreply, updated_socket} =
        ValentineWeb.WorkspaceLive.Threat.Show.handle_info(
          {"mitigations", :selected_item, mitigation},
          socket
        )

      assert updated_socket.assigns.threat.mitigations == [mitigation]
    end
  end

  describe "get_dfd_data/2" do
    alias Valentine.Composer.DataFlowDiagram

    test "gets actors for the threat sources field", %{workspace: workspace} do
      DataFlowDiagram.new(workspace.id)
      DataFlowDiagram.add_node(workspace.id, %{"type" => "actor"})
      DataFlowDiagram.add_node(workspace.id, %{"type" => "data_store"})

      assert ValentineWeb.WorkspaceLive.Threat.Show.get_dfd_data(workspace.id, :threat_source) ==
               ["Actor"]
    end

    test "gets data stores and processes for the impacted assets field", %{workspace: workspace} do
      DataFlowDiagram.new(workspace.id)
      DataFlowDiagram.add_node(workspace.id, %{"type" => "actor"})
      DataFlowDiagram.add_node(workspace.id, %{"type" => "datastore"})
      DataFlowDiagram.add_node(workspace.id, %{"type" => "process"})

      assert ValentineWeb.WorkspaceLive.Threat.Show.get_dfd_data(workspace.id, :impacted_assets) ==
               ["Datastore", "Process"]
    end

    test "returns an empty list if not a valid field", %{workspace: workspace} do
      assert ValentineWeb.WorkspaceLive.Threat.Show.get_dfd_data(workspace.id, :foo) == []
    end
  end
end
