#!/usr/bin/env elixir

# Minimal validation script for the GitHub auth JSON
# This validates the JSON structure without requiring full application setup

defmodule JsonValidator do
  def validate_file(file_path) do
    IO.puts("Validating GitHub Auth JSON Structure")
    IO.puts("=====================================")
    
    case File.read(file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} ->
            validate_workspace_structure(data)
          {:error, error} ->
            IO.puts("❌ JSON parsing failed: #{inspect(error)}")
            System.halt(1)
        end
      {:error, error} ->
        IO.puts("❌ File read failed: #{inspect(error)}")
        System.halt(1)
    end
  end
  
  defp validate_workspace_structure(data) do
    IO.puts("✅ JSON parsed successfully")
    
    workspace = Map.get(data, "workspace")
    if workspace do
      IO.puts("✅ Contains workspace data")
      validate_required_fields(workspace)
      show_content_summary(workspace)
      validate_threat_structure(workspace)
      IO.puts("\n🎉 All validations passed! The JSON structure is compatible with Navigator.")
    else
      IO.puts("❌ No workspace data found")
      System.halt(1)
    end
  end
  
  defp validate_required_fields(workspace) do
    required_fields = [
      "application_information",
      "architecture", 
      "data_flow_diagram",
      "assumptions",
      "mitigations", 
      "threats"
    ]
    
    IO.puts("\nChecking required fields:")
    
    Enum.each(required_fields, fn field ->
      if Map.has_key?(workspace, field) do
        IO.puts("  ✅ #{field}")
      else
        IO.puts("  ❌ Missing: #{field}")
        System.halt(1)
      end
    end)
  end
  
  defp show_content_summary(workspace) do
    assumptions_count = length(Map.get(workspace, "assumptions", []))
    mitigations_count = length(Map.get(workspace, "mitigations", []))
    threats_count = length(Map.get(workspace, "threats", []))
    
    IO.puts("\nContent Summary:")
    IO.puts("  📋 Assumptions: #{assumptions_count}")
    IO.puts("  🛡️  Mitigations: #{mitigations_count}")
    IO.puts("  ⚠️  Threats: #{threats_count}")
    
    # Show workspace name
    name = Map.get(workspace, "name", "Unknown")
    IO.puts("  📝 Workspace Name: #{name}")
  end
  
  defp validate_threat_structure(workspace) do
    threats = Map.get(workspace, "threats", [])
    if length(threats) > 0 do
      IO.puts("\nSample Threat Analysis:")
      threat = List.first(threats)
      
      IO.puts("  📍 Threat Source: #{Map.get(threat, "threat_source", "N/A")}")
      IO.puts("  🎯 Threat Action: #{Map.get(threat, "threat_action", "N/A")}")
      IO.puts("  💥 Threat Impact: #{Map.get(threat, "threat_impact", "N/A")}")
      IO.puts("  🚨 Priority: #{Map.get(threat, "priority", "N/A")}")
      
      stride = Map.get(threat, "stride", [])
      if length(stride) > 0 do
        IO.puts("  🔍 STRIDE Categories: #{Enum.join(stride, ", ")}")
      end
    end
  end
end

# Check if Jason is available (for JSON parsing)
try do
  Code.ensure_loaded!(Jason)
rescue
  UndefinedFunctionError ->
    IO.puts("Installing Jason dependency for JSON parsing...")
    Mix.install([{:jason, "~> 1.4"}])
end

# Get the file path from command line args or use default
file_path = case System.argv() do
  [path] -> path
  [] -> "examples/github_auth.json"
  _ -> 
    IO.puts("Usage: elixir validate_json.exs [path_to_json]")
    System.halt(1)
end

JsonValidator.validate_file(file_path)