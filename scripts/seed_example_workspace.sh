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
# Usage: ./seed_example_workspace.sh [workspace_name] [owner_email]
# 
# Arguments:
#   workspace_name: Optional. Name for the workspace (default: "GitHub Authentication Threat Model")
#   owner_email:    Optional. Email address for the workspace owner (default: "copilot-dev@example.com")
#
# Examples:
#   ./seed_example_workspace.sh
#   ./seed_example_workspace.sh "My GitHub Security Model" "developer@example.com"
#
# The script will:
# - Check if a user with the specified email exists, create one if not
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
DEFAULT_OWNER="copilot-dev@example.com"

WORKSPACE_NAME="${1:-$DEFAULT_WORKSPACE_NAME}"
OWNER_EMAIL="${2:-$DEFAULT_OWNER}"

# Get script directory and navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VALENTINE_DIR="$PROJECT_ROOT/valentine"
EXAMPLE_FILE="$PROJECT_ROOT/examples/github_auth.json"

echo "Navigator Example Workspace Seeder"
echo "=================================="
echo "Workspace Name: $WORKSPACE_NAME"
echo "Owner Email: $OWNER_EMAIL"
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

# Create the workspace using the separate Elixir script
RESULT=$(cd "$VALENTINE_DIR" && MIX_ENV=dev mix run "$SCRIPT_DIR/create_workspace.exs" "$WORKSPACE_NAME" "$OWNER_EMAIL" "$EXAMPLE_FILE" 2>&1)

# Parse the result
if echo "$RESULT" | grep -q "^SUCCESS:"; then
    WORKSPACE_ID=$(echo "$RESULT" | grep "^SUCCESS:" | cut -d: -f2)
    STATS_LINE=$(echo "$RESULT" | grep "^STATS:")
    OWNER_ID_LINE=$(echo "$RESULT" | grep "^OWNER_ID:")
    
    if [ -n "$STATS_LINE" ]; then
        ASSUMPTIONS_COUNT=$(echo "$STATS_LINE" | cut -d: -f2)
        MITIGATIONS_COUNT=$(echo "$STATS_LINE" | cut -d: -f3)
        THREATS_COUNT=$(echo "$STATS_LINE" | cut -d: -f4)
    else
        ASSUMPTIONS_COUNT="?"
        MITIGATIONS_COUNT="?"
        THREATS_COUNT="?"
    fi
    
    if [ -n "$OWNER_ID_LINE" ]; then
        OWNER_ID=$(echo "$OWNER_ID_LINE" | cut -d: -f2)
    else
        OWNER_ID="unknown"
    fi
    
    echo ""
    echo "✓ Workspace created successfully!"
    echo ""
    echo "Workspace Details:"
    echo "=================="
    echo "ID: $WORKSPACE_ID"
    echo "Name: $WORKSPACE_NAME"
    echo "Owner Email: $OWNER_EMAIL"
    echo "Owner ID: $OWNER_ID"
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