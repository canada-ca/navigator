# Script to create a workspace with user management
# Arguments: workspace_name owner_email example_file_path

import Ecto.Query

[workspace_name, owner_email, example_file] = System.argv()

# First, ensure the user exists and get a proper owner ID
owner_id = case Valentine.Composer.get_user(owner_email) do
  nil ->
    IO.puts("Creating user: #{owner_email}")
    case Valentine.Composer.create_user(%{email: owner_email}) do
      {:ok, user} ->
        IO.puts("✓ User created: #{user.email}")
        # Generate a consistent user ID for workspace ownership
        :crypto.hash(:sha256, owner_email) |> Base.encode64() |> String.slice(0, 8) |> Kernel.<>("||=") |> String.reverse()
      {:error, reason} ->
        IO.puts("ERROR: Failed to create user: #{inspect(reason)}")
        System.halt(1)
    end
  user ->
    IO.puts("✓ User exists: #{user.email}")
    # Generate the same consistent user ID
    :crypto.hash(:sha256, owner_email) |> Base.encode64() |> String.slice(0, 8) |> Kernel.<>("||=") |> String.reverse()
end

# Read and parse the JSON file
{:ok, content} = File.read(example_file)
{:ok, data} = Jason.decode(content)

# Get the workspace data and update the name
workspace_data = data["workspace"]
updated_workspace_data = Map.put(workspace_data, "name", workspace_name)

# Import the workspace with the proper owner ID
case ValentineWeb.WorkspaceLive.Import.JsonImport.build_workspace(updated_workspace_data, owner_id) do
  {:ok, workspace} ->
    IO.puts("SUCCESS:#{workspace.id}")
    
    # Get counts of imported items
    assumptions_count = Valentine.Repo.aggregate(
      from(a in Valentine.Composer.Assumption, where: a.workspace_id == ^workspace.id),
      :count
    )
    
    mitigations_count = Valentine.Repo.aggregate(
      from(m in Valentine.Composer.Mitigation, where: m.workspace_id == ^workspace.id),
      :count
    )
    
    threats_count = Valentine.Repo.aggregate(
      from(t in Valentine.Composer.Threat, where: t.workspace_id == ^workspace.id),
      :count
    )
    
    IO.puts("STATS:#{assumptions_count}:#{mitigations_count}:#{threats_count}")
    IO.puts("OWNER_ID:#{owner_id}")
    
  {:error, reason} ->
    IO.puts("ERROR:#{inspect(reason)}")
    System.halt(1)
end