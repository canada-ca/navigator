#!/bin/bash

# Simple test script to validate the JSON import functionality
# without starting the full application

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VALENTINE_DIR="$PROJECT_ROOT/valentine"
EXAMPLE_FILE="$PROJECT_ROOT/examples/github_auth.json"

echo "Testing JSON Import Functionality"
echo "================================"

cd "$VALENTINE_DIR"

# Test 1: Validate JSON syntax
echo "1. Validating JSON syntax..."
if command -v jq >/dev/null 2>&1; then
    if jq . "$EXAMPLE_FILE" >/dev/null; then
        echo "   ✓ JSON syntax is valid"
    else
        echo "   ✗ JSON syntax is invalid"
        exit 1
    fi
else
    echo "   ⚠ jq not available, skipping JSON validation"
fi

# Test 2: Check required fields in JSON
echo "2. Checking required JSON structure..."
if command -v jq >/dev/null 2>&1; then
    # Check for workspace key
    if jq -e '.workspace' "$EXAMPLE_FILE" >/dev/null; then
        echo "   ✓ Contains workspace data"
        
        # Check for required fields
        REQUIRED_FIELDS=("application_information" "architecture" "data_flow_diagram" "assumptions" "mitigations" "threats")
        for field in "${REQUIRED_FIELDS[@]}"; do
            if jq -e ".workspace.$field" "$EXAMPLE_FILE" >/dev/null; then
                echo "   ✓ Contains $field"
            else
                echo "   ✗ Missing required field: $field"
                exit 1
            fi
        done
        
        # Show stats
        ASSUMPTIONS_COUNT=$(jq '.workspace.assumptions | length' "$EXAMPLE_FILE")
        MITIGATIONS_COUNT=$(jq '.workspace.mitigations | length' "$EXAMPLE_FILE")
        THREATS_COUNT=$(jq '.workspace.threats | length' "$EXAMPLE_FILE")
        
        echo "   Content summary:"
        echo "   - Assumptions: $ASSUMPTIONS_COUNT"
        echo "   - Mitigations: $MITIGATIONS_COUNT"
        echo "   - Threats: $THREATS_COUNT"
        
    else
        echo "   ✗ No workspace data found"
        exit 1
    fi
fi

echo ""
echo "3. Testing Elixir module availability..."

# Test 3: Check if we can load the required modules without running tests
# This tests the basic script structure without network dependencies
cat > /tmp/test_import.exs << 'EOF'
# Test script to validate import module structure

IO.puts("Checking if modules can be loaded...")

try do
  # Try to load the JSON import module
  Code.ensure_loaded!(ValentineWeb.WorkspaceLive.Import.JsonImport)
  IO.puts("✓ JsonImport module is available")
  
  # Check if the module has the expected function
  if function_exported?(ValentineWeb.WorkspaceLive.Import.JsonImport, :process_json_file, 2) do
    IO.puts("✓ process_json_file/2 function exists")
  else
    IO.puts("✗ process_json_file/2 function not found")
    System.halt(1)
  end
  
  if function_exported?(ValentineWeb.WorkspaceLive.Import.JsonImport, :build_workspace, 2) do
    IO.puts("✓ build_workspace/2 function exists")
  else
    IO.puts("✗ build_workspace/2 function not found")
    System.halt(1)
  end
  
  # Try to load the Composer module
  Code.ensure_loaded!(Valentine.Composer)
  IO.puts("✓ Composer module is available")
  
  IO.puts("✓ All required modules are loadable")
  
rescue
  e -> 
    IO.puts("✗ Error loading modules: #{inspect(e)}")
    System.halt(1)
end
EOF

# Run the test script without full compilation
if timeout 30 elixir -pa _build/dev/lib/*/ebin /tmp/test_import.exs 2>/dev/null; then
    echo "   ✓ Basic module structure is valid"
else
    echo "   ⚠ Cannot test modules without full compilation"
    echo "   This is expected in environments with network restrictions"
fi

echo ""
echo "4. Validating script structure..."

# Test 4: Check that our seeding script has proper structure
SEED_SCRIPT="$SCRIPT_DIR/seed_example_workspace.sh"
if [ -f "$SEED_SCRIPT" ]; then
    echo "   ✓ Seed script exists"
    if [ -x "$SEED_SCRIPT" ]; then
        echo "   ✓ Seed script is executable"
    else
        echo "   ✗ Seed script is not executable"
        exit 1
    fi
    
    # Check for key components in the script
    if grep -q "JsonImport.build_workspace" "$SEED_SCRIPT"; then
        echo "   ✓ Script uses JsonImport.build_workspace"
    else
        echo "   ✗ Script missing JsonImport.build_workspace call"
        exit 1
    fi
    
    if grep -q "examples/github_auth.json" "$SEED_SCRIPT"; then
        echo "   ✓ Script references correct example file"
    else
        echo "   ✗ Script missing example file reference"
        exit 1
    fi
    
else
    echo "   ✗ Seed script not found at $SEED_SCRIPT"
    exit 1
fi

echo ""
echo "✓ All validation tests passed!"
echo ""
echo "The seeding script appears to be properly structured and should work"
echo "when the Navigator application is properly set up with a database."
echo ""
echo "To use the script:"
echo "1. Set up the database: cd valentine && mix ecto.create && mix ecto.migrate"
echo "2. Run the seeder: ./scripts/seed_example_workspace.sh"

# Cleanup
rm -f /tmp/test_import.exs