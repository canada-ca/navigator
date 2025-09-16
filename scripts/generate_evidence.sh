#!/bin/bash

# Script to generate random evidence for testing purposes
# 
# This script creates orphaned evidence items (not linked to any entities) with realistic
# test data including random NIST controls, tags, and content. Evidence items will be
# created with sequential numeric IDs within the workspace.
#
# Prerequisites:
# - The valentine application must be set up with a development database
# - Run `mix ecto.create && mix ecto.migrate` in the valentine directory first
#
# Usage: ./generate_evidence.sh <workspace_id> [count]
# 
# Arguments:
#   workspace_id: The UUID of the workspace to add evidence to
#   count:        Optional. Number of evidence items to create (default: 10)
#
# Examples:
#   ./generate_evidence.sh 550e8400-e29b-41d4-a716-446655440000 10
#   ./generate_evidence.sh abc123-def456-ghi789 25
#
# Generated evidence includes:
# - Mix of JSON data evidence and blob store link evidence
# - Random NIST control assignments (1-3 controls per item)
# - Random tags from security/compliance categories (1-4 tags per item)
# - Realistic names and descriptions for security assessment scenarios
# - Sequential numeric IDs for easy identification
#
# After running, evidence can be viewed at:
# http://localhost:4000/workspaces/{workspace_id}/evidence

set -e

# Check if workspace_id is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <workspace_id> [count]"
    echo "Example: $0 550e8400-e29b-41d4-a716-446655440000 10"
    exit 1
fi

WORKSPACE_ID="$1"
COUNT="${2:-10}"  # Default to 10 if not specified

# Navigate to the valentine directory
cd "$(dirname "$0")/../valentine"

# Arrays for generating random evidence data
EVIDENCE_TYPES=("json_data" "blob_store_link")
NIST_CONTROLS=("AC-1" "AC-2" "AC-3" "AU-12" "AU-6" "CA-2" "CA-7" "CM-2" "CM-6" "CP-1" "IA-2" "IA-5" "IR-4" "PE-2" "PL-1" "RA-5" "SA-4" "SC-7" "SI-2" "SI-4")
TAGS=("security" "compliance" "audit" "monitoring" "access-control" "data-protection" "incident-response" "vulnerability" "assessment" "documentation" "configuration" "backup" "encryption" "network" "identity" "risk" "development" "testing" "production" "critical")

# Evidence name prefixes and types
NAME_PREFIXES=("Security Audit" "Compliance Report" "Vulnerability Assessment" "Access Control Review" "Network Scan" "Configuration Audit" "Incident Report" "Risk Assessment" "Penetration Test" "Code Review")
DESCRIPTIONS=("Detailed security assessment findings" "Compliance verification documentation" "Vulnerability scan results and remediation" "Access control policy review and validation" "Network security configuration analysis" "System configuration compliance check" "Security incident investigation report" "Risk analysis and mitigation strategies" "Penetration testing results and recommendations" "Source code security review findings")

# JSON content templates for different evidence types
JSON_CONTENTS=(
    '{"document_type":"OSCAL","version":"1.0","findings":["Control implemented","Compliance verified"],"status":"completed"}'
    '{"assessment_type":"vulnerability_scan","severity":"medium","findings_count":5,"remediation_status":"in_progress"}'
    '{"audit_type":"access_control","users_reviewed":25,"violations_found":2,"corrective_actions":["Update permissions","Revoke unused accounts"]}'
    '{"scan_type":"network","hosts_scanned":50,"vulnerabilities":{"high":1,"medium":3,"low":8},"scan_date":"2024-09-16"}'
    '{"review_type":"configuration","systems_reviewed":15,"compliance_score":85,"non_compliant_items":["Weak passwords","Unpatched systems"]}'
    '{"incident_type":"security_breach","severity":"high","status":"resolved","duration_hours":4,"impact":"limited"}'
    '{"test_type":"penetration","scope":"external","findings":["SQL injection","XSS vulnerability"],"risk_level":"medium"}'
    '{"assessment_type":"risk","assets_evaluated":100,"high_risk_items":3,"mitigation_timeline":"30_days"}'
)

# Blob store URLs for file evidence
BLOB_URLS=(
    "https://evidence-store.example.com/security-audit-2024-09.pdf"
    "https://docs.example.com/compliance/iso27001-audit-report.pdf"
    "https://scans.example.com/vulnerability-assessment-q3-2024.xlsx"
    "https://reports.example.com/access-control-review-september.docx"
    "https://evidence.example.com/network-security-scan-results.pdf"
    "https://audit-docs.example.com/configuration-compliance-report.pdf"
    "https://incident-reports.example.com/security-breach-analysis.pdf"
    "https://risk-assessments.example.com/enterprise-risk-report-2024.xlsx"
    "https://pentest-results.example.com/external-penetration-test.pdf"
    "https://code-reviews.example.com/application-security-review.pdf"
)

echo "Generating $COUNT random evidence items for workspace $WORKSPACE_ID..."

# Generate the evidence items
for i in $(seq 1 $COUNT); do
    # Randomly select evidence type
    EVIDENCE_TYPE=${EVIDENCE_TYPES[$RANDOM % ${#EVIDENCE_TYPES[@]}]}
    
    # Generate random name
    NAME_PREFIX=${NAME_PREFIXES[$RANDOM % ${#NAME_PREFIXES[@]}]}
    EVIDENCE_NAME="$NAME_PREFIX #$(printf "%03d" $i)"
    
    # Generate random description
    DESCRIPTION=${DESCRIPTIONS[$RANDOM % ${#DESCRIPTIONS[@]}]}
    
    # Generate 1-3 random NIST controls
    NIST_COUNT=$((1 + RANDOM % 3))
    SELECTED_NIST=""
    for j in $(seq 1 $NIST_COUNT); do
        CONTROL=${NIST_CONTROLS[$RANDOM % ${#NIST_CONTROLS[@]}]}
        if [ -z "$SELECTED_NIST" ]; then
            SELECTED_NIST="\"$CONTROL\""
        else
            SELECTED_NIST="$SELECTED_NIST,\"$CONTROL\""
        fi
    done
    
    # Generate 1-4 random tags
    TAG_COUNT=$((1 + RANDOM % 4))
    SELECTED_TAGS=""
    for j in $(seq 1 $TAG_COUNT); do
        TAG=${TAGS[$RANDOM % ${#TAGS[@]}]}
        if [ -z "$SELECTED_TAGS" ]; then
            SELECTED_TAGS="\"$TAG\""
        else
            SELECTED_TAGS="$SELECTED_TAGS,\"$TAG\""
        fi
    done
    
    # Create the evidence based on type
    if [ "$EVIDENCE_TYPE" = "json_data" ]; then
        JSON_CONTENT=${JSON_CONTENTS[$RANDOM % ${#JSON_CONTENTS[@]}]}
        # Escape the JSON content for the Elixir string
        ESCAPED_JSON=$(echo "$JSON_CONTENT" | sed 's/"/\\"/g')
        
        MIX_ENV=dev mix run -e "
        {:ok, evidence} = Valentine.Composer.create_evidence(%{
          workspace_id: \"$WORKSPACE_ID\",
          name: \"$EVIDENCE_NAME\",
          description: \"$DESCRIPTION\",
          evidence_type: :json_data,
          content: Jason.decode!(\"$ESCAPED_JSON\"),
          nist_controls: [$SELECTED_NIST],
          tags: [$SELECTED_TAGS]
        })
        IO.puts(\"Created JSON evidence: #{evidence.name} (ID: #{evidence.id})\")
        "
    else
        BLOB_URL=${BLOB_URLS[$RANDOM % ${#BLOB_URLS[@]}]}
        
        MIX_ENV=dev mix run -e "
        {:ok, evidence} = Valentine.Composer.create_evidence(%{
          workspace_id: \"$WORKSPACE_ID\",
          name: \"$EVIDENCE_NAME\",
          description: \"$DESCRIPTION\",
          evidence_type: :blob_store_link,
          blob_store_url: \"$BLOB_URL\",
          nist_controls: [$SELECTED_NIST],
          tags: [$SELECTED_TAGS]
        })
        IO.puts(\"Created blob evidence: #{evidence.name} (ID: #{evidence.id})\")
        "
    fi
    
    # Add a small delay to avoid overwhelming the database
    sleep 0.1
done

echo "Successfully generated $COUNT evidence items for workspace $WORKSPACE_ID"
echo "You can view them in the Evidence Overview page at: /workspaces/$WORKSPACE_ID/evidence"