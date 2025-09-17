#!/bin/bash

# Script to seed an example workspace from examples/github_auth.json
# 
# This script creates a workspace based on the GitHub authentication threat model
# using the existing JSON import functionality. It's designed for Copilot development
# environments to provide realistic example data for testing and demonstration.
#
# Prerequisites:
# - The valentine application must be set up with a development database
# - Run `mix ecto.create && mix ecto.migrate` in the valentine directory first
#
# Usage: ./seed_example_workspace.sh [workspace_name] [owner]
# 
# Arguments:
#   workspace_name: Optional. Name for the workspace (default: "GitHub Authentication Threat Model")
#   owner:          Optional. Owner identifier (default: "copilot-dev")
#
# Examples:
#   ./seed_example_workspace.sh
#   ./seed_example_workspace.sh "My GitHub Security Model" "developer@example.com"
#
# The script will:
# - Import the GitHub authentication threat model from examples/github_auth.json
# - Create a complete workspace with threats, mitigations, assumptions, and data flow diagram
# - Output the workspace UUID for easy access
# - Provide URLs to view the workspace overview and details
#
# After running, the workspace can be viewed at:
# http://localhost:4000/workspaces/{workspace_id}

set -e

# Default values
DEFAULT_WORKSPACE_NAME="GitHub Authentication Threat Model"
DEFAULT_OWNER="copilot-dev"

WORKSPACE_NAME="${1:-$DEFAULT_WORKSPACE_NAME}"
OWNER="${2:-$DEFAULT_OWNER}"

# Get script directory and navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VALENTINE_DIR="$PROJECT_ROOT/valentine"
EXAMPLE_FILE="$PROJECT_ROOT/examples/github_auth.json"

echo "Navigator Example Workspace Seeder"
echo "=================================="
echo "Workspace Name: $WORKSPACE_NAME"
echo "Owner: $OWNER"
echo "Example File: $EXAMPLE_FILE"
echo ""

# Validate that required files exist
if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "Error: Example file not found at $EXAMPLE_FILE"
    exit 1
fi

if [ ! -d "$VALENTINE_DIR" ]; then
    echo "Error: Valentine directory not found at $VALENTINE_DIR"
    exit 1
fi

# Navigate to the valentine directory
cd "$VALENTINE_DIR"

# Check if the Valentine application is properly set up
if [ ! -f "mix.exs" ]; then
    echo "Error: Not in a valid Elixir project directory"
    exit 1
fi

echo "Validating example JSON file..."

# Validate the JSON file first
MIX_ENV=dev mix run -e "
case File.read(\"$EXAMPLE_FILE\") do
  {:ok, content} ->
    case Jason.decode(content) do
      {:ok, data} ->
        IO.puts(\"✓ JSON file is valid\")
        workspace_data = Map.get(data, \"workspace\")
        if workspace_data do
          IO.puts(\"✓ Contains workspace data\")
          name = Map.get(workspace_data, \"name\", \"Unknown\")
          IO.puts(\"  Original name: #{name}\")
        else
          IO.puts(\"✗ No workspace data found in JSON\")
          System.halt(1)
        end
      {:error, reason} ->
        IO.puts(\"✗ Invalid JSON: #{inspect(reason)}\")
        System.halt(1)
    end
  {:error, reason} ->
    IO.puts(\"✗ Cannot read file: #{inspect(reason)}\")
    System.halt(1)
end
"

if [ $? -ne 0 ]; then
    echo "JSON validation failed"
    exit 1
fi

echo ""
echo "Creating workspace from example data..."

# Create the workspace using the JSON import functionality
RESULT=$(MIX_ENV=dev mix run -e "
# Read and parse the JSON file
{:ok, content} = File.read(\"$EXAMPLE_FILE\")
{:ok, data} = Jason.decode(content)

# Get the workspace data and update the name
workspace_data = data[\"workspace\"]
updated_workspace_data = Map.put(workspace_data, \"name\", \"$WORKSPACE_NAME\")

# Import the workspace
case ValentineWeb.WorkspaceLive.Import.JsonImport.build_workspace(updated_workspace_data, \"$OWNER\") do
  {:ok, workspace} ->
    IO.puts(\"SUCCESS:#{workspace.id}\")
    
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
    
    IO.puts(\"STATS:#{assumptions_count}:#{mitigations_count}:#{threats_count}\")
    
  {:error, reason} ->
    IO.puts(\"ERROR:#{inspect(reason)}\")
    System.halt(1)
end
" 2>&1)

# Parse the result
if echo "$RESULT" | grep -q "^SUCCESS:"; then
    WORKSPACE_ID=$(echo "$RESULT" | grep "^SUCCESS:" | cut -d: -f2)
    STATS_LINE=$(echo "$RESULT" | grep "^STATS:")
    
    if [ -n "$STATS_LINE" ]; then
        ASSUMPTIONS_COUNT=$(echo "$STATS_LINE" | cut -d: -f2)
        MITIGATIONS_COUNT=$(echo "$STATS_LINE" | cut -d: -f3)
        THREATS_COUNT=$(echo "$STATS_LINE" | cut -d: -f4)
    else
        ASSUMPTIONS_COUNT="?"
        MITIGATIONS_COUNT="?"
        THREATS_COUNT="?"
    fi
    
    echo ""
    echo "✓ Workspace created successfully!"
    echo ""
    echo "Workspace Details:"
    echo "=================="
    echo "ID: $WORKSPACE_ID"
    echo "Name: $WORKSPACE_NAME"
    echo "Owner: $OWNER"
    echo ""
    echo "Imported Content:"
    echo "=================="
    echo "Assumptions: $ASSUMPTIONS_COUNT"
    echo "Mitigations: $MITIGATIONS_COUNT"
    echo "Threats: $THREATS_COUNT"
    echo ""
    echo "Access URLs:"
    echo "============"
    echo "Workspaces Overview: http://localhost:4000/workspaces"
    echo "Workspace Details:   http://localhost:4000/workspaces/$WORKSPACE_ID"
    echo ""
    echo "For screenshots, navigate to:"
    echo "1. http://localhost:4000/workspaces (overview page)"
    echo "2. http://localhost:4000/workspaces/$WORKSPACE_ID (detail page)"
    echo ""
    echo "Workspace ID for future reference: $WORKSPACE_ID"
    
else
    echo ""
    echo "✗ Failed to create workspace"
    echo "Error details:"
    echo "$RESULT"
    exit 1
fi