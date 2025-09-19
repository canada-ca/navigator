defmodule Valentine.Composer.DataFlowDiagram do
  use Ecto.Schema
  import Ecto.Changeset

  alias Valentine.Cache
  alias Valentine.Composer

  @history_limit 50

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type :binary_id

  schema "data_flow_diagrams" do
    belongs_to :workspace, Valentine.Composer.Workspace

    field :edges, :map, default: %{}
    field :nodes, :map, default: %{}
    field :raw_image, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(data_flow_diagram, attrs) do
    data_flow_diagram
    |> cast(attrs, [:edges, :nodes, :raw_image, :workspace_id])
    |> validate_required([:edges, :nodes, :workspace_id])
  end

  def new(workspace_id) do
    case Composer.get_data_flow_diagram_by_workspace_id(workspace_id) do
      nil ->
        {:ok, dfd} =
          %{
            workspace_id: workspace_id,
            nodes: %{},
            edges: %{}
          }
          |> Composer.create_data_flow_diagram()

        dfd

      dfd ->
        dfd
    end
  end

  def add_node(
        workspace_id,
        %{
          "type" => type
        } = params
      ) do
    dfd = get(workspace_id)

    id = "node-" <> Integer.to_string(System.unique_integer([:positive]))

    node =
      %{
        "data" => %{
          "id" => id,
          "data_tags" => [],
          "description" => nil,
          "label" => Phoenix.Naming.humanize(type),
          "linked_threats" => [],
          "out_of_scope" => "false",
          "parent" => nil,
          "security_tags" => [],
          "technology_tags" => [],
          "type" => type
        },
        "grabbable" => "true",
        "position" => %{
          "x" => :rand.uniform(400),
          "y" => :rand.uniform(400)
        }
      }

    # Check if one node is selected and if that node is a trust boundary
    node =
      if Map.has_key?(params, "selected_elements") &&
           Kernel.map_size(params["selected_elements"]["nodes"]) == 1 &&
           dfd.nodes[Map.keys(params["selected_elements"]["nodes"]) |> List.first()]["data"][
             "type"
           ] == "trust_boundary" do
        Map.put(
          node,
          "data",
          Map.put(
            node["data"],
            "parent",
            Map.keys(params["selected_elements"]["nodes"]) |> List.first()
          )
        )
      else
        node
      end

    dfd
    |> Map.update!(:nodes, &Map.put(&1, id, node))
    |> put_with_history()

    node
  end

  def clear_dfd(workspace_id, _params) do
    get(workspace_id)
    |> Map.put(:nodes, %{})
    |> Map.put(:edges, %{})
    |> put_with_history()

    nil
  end

  def ehcomplete(workspace_id, %{"edge" => edge}) do
    dfd = get(workspace_id)

    new_edge =
      %{
        "data" => %{
          "id" => edge["id"],
          "data_tags" => [],
          "description" => nil,
          "label" => "Data flow",
          "linked_threats" => [],
          "out_of_scope" => "false",
          "security_tags" => [],
          "source" => edge["source"],
          "target" => edge["target"],
          "technology_tags" => [],
          "type" => "edge"
        }
      }

    dfd
    |> Map.update!(:edges, &Map.put(&1, edge["id"], new_edge))
    |> put_with_history()

    new_edge
  end

  def fit_view(_workspace_id, _params), do: nil

  def free(workspace_id, %{"node" => node}) do
    dfd = get(workspace_id)

    new_node =
      %{
        dfd.nodes[node["id"]]
        | "grabbable" => "true"
      }

    dfd
    |> Map.update!(:nodes, &Map.put(&1, node["id"], new_node))
    |> put()

    new_node
  end

  def get(workspace_id, from_cache \\ true) do
    if from_cache do
      case Cache.get({__MODULE__, :dfd, workspace_id}) do
        nil -> new(workspace_id) |> put()
        dfd -> dfd
      end
    else
      new(workspace_id) |> put()
    end
  end

  def grab(workspace_id, %{"node" => node}) do
    dfd = get(workspace_id)

    new_node =
      %{
        dfd.nodes[node["id"]]
        | "grabbable" => "false"
      }

    dfd
    |> Map.update!(:nodes, &Map.put(&1, node["id"], new_node))
    |> put_with_history()

    new_node
  end

  def group_nodes(_worskspace_id, %{"selected_elements" => %{"nodes" => nodes}})
      when nodes == %{} do
    %{node: %{}, children: []}
  end

  def group_nodes(workspace_id, %{"selected_elements" => selected_elements}) do
    dfd = get(workspace_id)
    parent_node = add_node(workspace_id, %{"type" => "trust_boundary"})

    dfd
    |> Map.update!(:nodes, fn nodes ->
      Enum.reduce(selected_elements["nodes"], nodes, fn {id, _}, acc ->
        if Map.has_key?(acc, id) do
          # Put parent id in node.data
          Map.put(acc, id, %{
            acc[id]
            | "data" => %{
                acc[id]["data"]
                | "parent" => parent_node["data"]["id"]
              }
          })
        else
          acc
        end
      end)
    end)
    |> Map.update!(:nodes, &Map.put(&1, parent_node["data"]["id"], parent_node))
    |> put_with_history()

    %{node: parent_node, children: Map.keys(selected_elements["nodes"])}
  end

  def merge_group(workspace_id, %{"selected_elements" => %{"nodes" => nodes}}) do
    dfd = get(workspace_id)
    # Check if any of the selected nodes is a trust boundary if not return an error
    if Enum.any?(nodes, fn {id, _} -> dfd.nodes[id]["data"]["type"] == "trust_boundary" end) do
      # Get all nodes that are trust boundaries
      [
        {trust_boundary_id, _}
        | other_boundaries
      ] =
        Enum.filter(nodes, fn {id, _} -> dfd.nodes[id]["data"]["type"] == "trust_boundary" end)

      trust_boundary = dfd.nodes[trust_boundary_id]

      # Get all the selected elements that do not belong to that trust boundary
      to_merge =
        Enum.filter(nodes, fn {id, _} ->
          dfd.nodes[id]["data"]["type"] != "trust_boundary" and
            dfd.nodes[id]["data"]["parent"] != trust_boundary["data"]["id"]
        end)

      # Get all the children that belong to the other trust boundaries
      children =
        Enum.reduce(other_boundaries, [], fn {id, _}, acc ->
          acc ++
            find_children(dfd.nodes, id)
        end)

      # Update the to_merge and children to have the parent of the trust boundary
      dfd =
        (to_merge ++ children)
        |> Enum.reduce(dfd, fn {id, _}, acc ->
          acc
          |> Map.update!(
            :nodes,
            &Map.put(&1, id, %{
              acc.nodes[id]
              | "data" => %{
                  acc.nodes[id]["data"]
                  | "parent" => trust_boundary["data"]["id"]
                }
            })
          )
        end)

      # Remove the other trust boundaries
      other_boundaries
      |> Enum.reduce(dfd, fn {id, _}, acc ->
        acc
        |> Map.update!(:nodes, &Map.delete(&1, id))
      end)
      |> put_with_history()

      %{
        node: trust_boundary["data"]["id"],
        children: Map.keys(Map.new(to_merge ++ children)),
        purge: Map.keys(Map.new(other_boundaries))
      }
    else
      {:error, "Only trust boundaries can be merged"}
    end
  end

  def position(workspace_id, %{"node" => node}) do
    dfd = get(workspace_id)

    new_node =
      %{
        dfd.nodes[node["id"]]
        | "position" => %{
            "x" => node["position"]["x"],
            "y" => node["position"]["y"]
          }
      }

    dfd
    |> Map.update!(:nodes, &Map.put(&1, node["id"], new_node))
    |> put()

    new_node
  end

  def put(dfd) do
    # Change DFD into struct if it is not a struct
    dfd =
      if not is_struct(dfd) do
        struct(__MODULE__, dfd)
      else
        dfd
      end

    Cache.put({__MODULE__, :dfd, dfd.workspace_id}, dfd)
    dfd
  end

  def put_with_history(dfd) do
    # Save current state to history before making changes
    current_dfd = get(dfd.workspace_id)
    push_to_history_with_dfd(current_dfd)
    put(dfd)
  end

  def remove_elements(workspace_id, %{"selected_elements" => selected_elements}) do
    dfd = get(workspace_id)

    dfd =
      selected_elements["nodes"]
      |> Enum.reduce(dfd, &remove_node_and_associated_edges/2)
      |> put_with_history()

    selected_elements["edges"]
    |> Enum.reduce(dfd, fn {id, _}, acc ->
      acc
      |> Map.update!(:edges, &Map.delete(&1, id))
    end)
    |> put()

    selected_elements
  end

  def remove_group(_workspace_id, %{
        "selected_elements" => %{"nodes" => nodes}
      })
      when map_size(nodes) != 1 do
    {:error, "Only one trust boundaries can be removed at a time"}
  end

  def remove_group(workspace_id, %{"selected_elements" => %{"nodes" => nodes}}) do
    dfd = get(workspace_id)
    node = dfd.nodes[Map.keys(nodes) |> List.first()]

    if node["data"]["type"] == "trust_boundary" do
      dfd.nodes
      |> Enum.filter(fn {_, n} -> n["data"]["parent"] == node["data"]["id"] end)
      |> Enum.reduce(dfd, fn {id, n}, acc ->
        acc
        |> Map.update!(
          :nodes,
          &Map.put(&1, id, %{
            n
            | "data" => %{
                n["data"]
                | "parent" => nil
              }
          })
        )
      end)
      |> Map.update!(:nodes, &Map.delete(&1, node["data"]["id"]))
      |> put_with_history()

      node
    else
      {:error, "Only trust boundaries can be removed"}
    end
  end

  def remove_linked_threats(workspace_id, threat_id) do
    dfd = get(workspace_id)

    # Loop through all nodes and remove the threat from the linked_threats list
    dfd =
      dfd.nodes
      |> Enum.reduce(dfd, fn {id, node}, acc ->
        acc
        |> Map.update!(
          :nodes,
          &Map.put(&1, id, %{
            node
            | "data" => %{
                node["data"]
                | "linked_threats" =>
                    Enum.reject(node["data"]["linked_threats"], fn threat ->
                      threat == threat_id
                    end)
              }
          })
        )
      end)
      |> put()

    # Loop through all edges and remove the threat from the linked_threats list
    dfd.edges
    |> Enum.reduce(dfd, fn {id, edge}, acc ->
      acc
      |> Map.update!(
        :edges,
        &Map.put(&1, id, %{
          edge
          | "data" => %{
              edge["data"]
              | "linked_threats" =>
                  Enum.reject(edge["data"]["linked_threats"], fn threat -> threat == threat_id end)
            }
        })
      )
    end)
    |> put()

    save(workspace_id)
  end

  def save(workspace_id) do
    dfd =
      get(workspace_id)

    Composer.get_data_flow_diagram!(dfd.id)
    |> Composer.update_data_flow_diagram(Map.from_struct(dfd))
  end

  def to_json(workspace_id) do
    dfd = get(workspace_id)

    %{nodes: dfd.nodes, edges: dfd.edges}
    |> Jason.encode!()
  end

  # Catch for check box values
  def update_metadata(workspace_id, %{"id" => id, "field" => field, "checked" => value}) do
    update_metadata(workspace_id, %{"id" => id, "field" => field, "value" => [value]})
  end

  def update_metadata(workspace_id, %{"id" => id, "field" => field, "value" => value}) do
    dfd = get(workspace_id)

    cond do
      String.starts_with?(id, "node") ->
        dfd
        |> Map.update!(:nodes, fn nodes ->
          Map.update!(nodes, id, &update_data(&1, field, value))
        end)
        |> put_with_history()

        %{"id" => id, "field" => field, "value" => value}

      String.starts_with?(id, "edge") ->
        dfd
        |> Map.update!(:edges, fn edges ->
          Map.update!(edges, id, &update_data(&1, field, value))
        end)
        |> put_with_history()

        %{"id" => id, "field" => field, "value" => value}

      true ->
        {:error, "Invalid element id"}
    end
  end

  # Catch function if value is undefined (ex. checkboxes)
  def update_metadata(workspace_id, %{"id" => id, "field" => field}) do
    update_metadata(workspace_id, %{"id" => id, "field" => field, "value" => "false"})
  end

  def zoom_in(_workspace_id, _params), do: nil
  def zoom_out(_workspace_id, _params), do: nil

  # History management functions
  def undo(workspace_id, _params) do
    {history_stack, future_stack} = get_history_stacks(workspace_id)

    case history_stack do
      [] ->
        {:error, "No states to undo"}

      [current_state | remaining_history] ->
        # Get current state and push to future stack
        current_dfd = get(workspace_id)
        updated_future_stack = [current_dfd | future_stack]

        # Apply the previous state
        current_state
        |> Map.put(:workspace_id, workspace_id)
        |> put()

        # Update history stacks
        put_history_stacks(workspace_id, remaining_history, updated_future_stack)

        # Return the restored state for UI updates
        current_state
    end
  end

  def redo(workspace_id, _params) do
    {history_stack, future_stack} = get_history_stacks(workspace_id)

    case future_stack do
      [] ->
        {:error, "No states to redo"}

      [next_state | remaining_future] ->
        # Get current state and push to history stack
        current_dfd = get(workspace_id)
        updated_history_stack = [current_dfd | history_stack]

        # Apply the next state
        next_state
        |> Map.put(:workspace_id, workspace_id)
        |> put()

        # Update history stacks
        put_history_stacks(workspace_id, updated_history_stack, remaining_future)

        # Return the restored state for UI updates
        next_state
    end
  end

  def get_history_stacks(workspace_id) do
    history_key = {__MODULE__, :history, workspace_id}
    future_key = {__MODULE__, :future, workspace_id}

    history_stack = Cache.get(history_key) || []
    future_stack = Cache.get(future_key) || []

    {history_stack, future_stack}
  end

  def put_history_stacks(workspace_id, history_stack, future_stack) do
    history_key = {__MODULE__, :history, workspace_id}
    future_key = {__MODULE__, :future, workspace_id}

    Cache.put(history_key, history_stack)
    Cache.put(future_key, future_stack)
  end

  def push_to_history(workspace_id) do
    current_dfd = get(workspace_id)
    push_to_history_with_dfd(current_dfd)
  end

  defp push_to_history_with_dfd(current_dfd) do
    workspace_id = current_dfd.workspace_id
    {history_stack, _future_stack} = get_history_stacks(workspace_id)

    # Create a clean state for history (remove workspace_id to avoid conflicts)
    history_state = %{
      nodes: current_dfd.nodes,
      edges: current_dfd.edges,
      id: current_dfd.id
    }

    # Add current state to history and limit the stack size
    updated_history_stack =
      [history_state | history_stack]
      |> Enum.take(@history_limit)

    # Clear future stack since we're making a new change
    put_history_stacks(workspace_id, updated_history_stack, [])
  end

  def can_undo?(workspace_id) do
    {history_stack, _} = get_history_stacks(workspace_id)
    length(history_stack) > 0
  end

  def can_redo?(workspace_id) do
    {_, future_stack} = get_history_stacks(workspace_id)
    length(future_stack) > 0
  end

  defp find_children(nodes, parent_id) do
    nodes
    |> Enum.filter(fn {_, node} -> node["data"]["parent"] == parent_id end)
  end

  defp find_descendents(nodes, parent_id) do
    nodes
    |> Enum.reduce([parent_id], fn {node_id, node}, acc ->
      case node["data"] do
        %{"parent" => ^parent_id} ->
          [node_id | acc ++ find_descendents(nodes, node_id)]

        _ ->
          acc
      end
    end)
    |> Enum.uniq()
  end

  defp remove_node_and_associated_edges({id, _}, dfd) do
    find_descendents(dfd.nodes, id)
    |> Enum.reduce(dfd, fn node_id, acc ->
      acc
      |> Map.update!(:nodes, &Map.delete(&1, node_id))
      |> Map.update!(:edges, fn edges ->
        Enum.filter(edges, fn {_, edge} ->
          edge["data"]["source"] != node_id and edge["data"]["target"] != node_id
        end)
        |> Map.new()
      end)
    end)
  end

  defp update_data(element, field, value) when is_list(value) do
    value = hd(value)

    if value in element["data"][field] do
      put_in(element, ["data", field], Enum.reject(element["data"][field], &(&1 == value)))
    else
      put_in(element, ["data", field], [value | element["data"][field]])
    end
  end

  defp update_data(element, field, value) do
    put_in(element, ["data", field], value)
  end
end
