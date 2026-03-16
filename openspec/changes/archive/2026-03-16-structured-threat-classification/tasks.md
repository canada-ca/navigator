## 1. Database Migration

- [x] 1.1 Generate Ecto migration to add `max_threat_level :string` (nullable) to `workspaces`
- [x] 1.2 Add `stride_category :string`, `mitre_tactic :string`, `kill_chain_phase :string`, `threat_level :string` (all nullable) to `threats` in the same or a separate migration
- [x] 1.3 Create `threat_agents` table with columns: `id`, `workspace_id` (FK → workspaces, ON DELETE CASCADE), `name :string` (required), `agent_class :string`, `capability :string`, `motivation :string`, `td_level :string`, `timestamps`
- [x] 1.4 Run `mix ecto.migrate` and verify the schema changes are applied cleanly

## 2. Deliberate Threat Level Taxonomy Module

- [x] 2.1 Create `Valentine.Composer.DeliberateThreatLevel` (or equivalent module constant location) defining the ordered list of Td values and their human-readable labels (Td1–Td7)
- [x] 2.2 Export a helper function (e.g., `values/0` returning `[{:td1, "Td1 — Script Kiddie"}, ...]`) for use by form dropdowns and validation
- [x] 2.3 Write unit tests for the taxonomy module (correct count, correct ordering, labels present)

## 3. Workspace Schema and Context Updates

- [x] 3.1 Add `max_threat_level` field to `Valentine.Composer.Workspace` schema
- [x] 3.2 Update `Workspace.changeset/2` to cast and validate `max_threat_level` against the Td taxonomy values (allow nil)
- [x] 3.3 Update existing `Workspace` DataCase tests to cover `max_threat_level` cast/validation scenarios

## 4. Threat Schema and Context Updates

- [x] 4.1 Add `stride_category`, `mitre_tactic`, `kill_chain_phase`, `threat_level` fields to `Valentine.Composer.Threat` schema
- [x] 4.2 Update `Threat.changeset/2` to cast all four new fields; validate `stride_category` against the STRIDE enum, `kill_chain_phase` against the kill chain enum, and `threat_level` against Td values (all nullable)
- [x] 4.3 Define the STRIDE category enum (`spoofing`, `tampering`, `repudiation`, `information_disclosure`, `denial_of_service`, `elevation_of_privilege`) and kill chain phase enum in appropriate module constants
- [x] 4.4 Update existing `Threat` DataCase tests to cover the new fields

## 5. ThreatAgent Schema and Context

- [x] 5.1 Create `valentine/lib/valentine/composer/threat_agent.ex` with the `ThreatAgent` Ecto schema (fields: `name`, `agent_class`, `capability`, `motivation`, `td_level`, `workspace_id`)
- [x] 5.2 Add `changeset/2` to `ThreatAgent` that requires `name` and validates `td_level` against the Td taxonomy (allow nil)
- [x] 5.3 Add `list_threat_agents/1`, `get_threat_agent!/1`, `create_threat_agent/1`, `update_threat_agent/2`, `delete_threat_agent/1` functions to `Valentine.Composer`
- [x] 5.4 Update `Valentine.Composer.Workspace` to declare `has_many :threat_agents, ThreatAgent` association
- [x] 5.5 Write DataCase tests for all ThreatAgent CRUD functions

## 6. Workspace Form UI (max Td level dropdown)

- [x] 6.1 Update `valentine/lib/valentine_web/live/workspace_live/form_component.ex` to add the `max_threat_level` dropdown field using the Td taxonomy labels
- [x] 6.2 Ensure the dropdown includes an unset / "No Td scope" option and pre-populates from the loaded workspace
- [x] 6.3 Update the workspace form HEEx template to render the new dropdown in an appropriate position

## 7. Threat Form UI (classification fields)

- [x] 7.1 Update `valentine/lib/valentine_web/live/workspace_live/threat_live/form_component.ex` to add the four classification fields (STRIDE category dropdown, MITRE tactic text input, kill chain phase dropdown, assigned Td level dropdown)
- [x] 7.2 Ensure the new fields are optional and pre-populate from the loaded threat on edit
- [x] 7.3 Update the threat form HEEx template to render the classification fields in a logical grouping (e.g., a "Classification" section below the main threat statement fields)

## 8. Threat Index Filtering

- [x] 8.1 Extend the threat filter struct / changeset in `Valentine.Composer` to include `stride_category`, `threat_level` filter fields
- [x] 8.2 Update the Threat query function(s) to apply the new classification filters when set
- [x] 8.3 Update `WorkspaceLive.ThreatLive.Index` to expose the new filter UI (dropdowns for STRIDE category and Td level)
- [x] 8.4 Write or update LiveView tests for the updated filter behavior

## 9. Threat Detail View (classification display)

- [x] 9.1 Update the threat show/detail HEEx template to display all four classification fields with their human-readable labels
- [x] 9.2 Display "Not set" for any unclassified field rather than leaving it blank or hidden

## 10. ThreatAgent LiveViews

- [x] 10.1 Create `valentine/lib/valentine_web/live/workspace_live/threat_agent_live/index.ex` for listing workspace threat agents
- [x] 10.2 Create `valentine/lib/valentine_web/live/workspace_live/threat_agent_live/form_component.ex` for create/edit flows
- [x] 10.3 Add router entries under the workspace scope for `/threat_agents` (index, new, edit)
- [x] 10.4 Add a navigation entry for "Threat Agents" in the workspace sidebar component
- [x] 10.5 Write LiveView tests (ConnCase/LiveView) for the ThreatAgent index and form flows (list, create, edit, delete)

## 11. Verification

- [x] 11.1 Run `make fmt` and resolve any formatting issues
- [x] 11.2 Run `make test` and ensure all tests pass with no regressions
- [x] 11.3 Manually verify workspace create/edit form shows the max Td level dropdown with correct labels
- [x] 11.4 Manually verify threat create/edit form shows STRIDE, MITRE, kill chain, and Td fields
- [x] 11.5 Manually verify the Threat Agents listing, create, edit, and delete flows work end-to-end
- [x] 11.6 Manually verify threat index filtering by STRIDE category and Td level returns the expected results
- [x] 11.7 Verify that deleting a workspace also removes its associated Threat Agents (cascade check)
