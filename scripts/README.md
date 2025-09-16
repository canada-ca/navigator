# Navigator Scripts

This directory contains utility scripts for the Navigator application.

## Evidence Generation Script

### `generate_evidence.sh`

A utility script for generating random evidence items for testing the Evidence Overview page functionality.

**Purpose:** Creates realistic test evidence data to populate workspaces for development and testing purposes.

**Prerequisites:**
- Development database must be set up (`mix ecto.create && mix ecto.migrate`)
- Must be run from the project root directory

**Usage:**
```bash
./scripts/generate_evidence.sh <workspace_id> [count]
```

**Parameters:**
- `workspace_id`: The UUID of the target workspace
- `count`: Optional. Number of evidence items to create (default: 10)

**Examples:**
```bash
# Generate 10 evidence items (default)
./scripts/generate_evidence.sh 550e8400-e29b-41d4-a716-446655440000

# Generate 25 evidence items  
./scripts/generate_evidence.sh 550e8400-e29b-41d4-a716-446655440000 25
```

**Generated Evidence Features:**
- **Mixed Types**: Both JSON data evidence and blob store link evidence
- **NIST Controls**: Random assignment of 1-3 NIST controls per item
- **Tags**: Random security/compliance tags (1-4 per item)
- **Realistic Content**: Security assessment scenarios with appropriate names and descriptions
- **Sequential IDs**: Automatic numeric ID assignment for easy identification
- **Orphaned Status**: Evidence is not linked to any threats, assumptions, or mitigations

**Evidence Categories Generated:**
- Security Audits
- Compliance Reports  
- Vulnerability Assessments
- Access Control Reviews
- Network Scans
- Configuration Audits
- Incident Reports
- Risk Assessments
- Penetration Tests
- Code Reviews

**Viewing Results:**
After running the script, view the generated evidence at:
`http://localhost:4000/workspaces/{workspace_id}/evidence`

**Technical Details:**
- Runs in development environment (`MIX_ENV=dev`)
- Creates evidence through the Valentine.Composer API
- Includes realistic JSON content for different assessment types
- Generates valid blob store URLs for file-based evidence
- Uses random selection from predefined NIST controls and tags
- Includes 100ms delay between creations to avoid database overload