# Workspace LiveView mutation inventory

All LiveView and LiveComponent events under `workspace_live` pass through
`WorkspaceAuthorizationHelper`. The hook uses a deny-by-default classification:
events not explicitly identified as local/read interactions require current
database-backed Write access.

## Local/read interactions

- Navigation and presentation: `change_locale`, `update_chatbot`, `toggle_drawer`,
  `set_tab`, `change_page`, `show_context`, `toggle_goals`, `view_control_modal`,
  and `close_control_modal`.
- Filtering and inspection: `filter`, `clear_filter`, `clear_filters`, `search`,
  and `select_evidence_filter`.
- Diagram inspection: `select`, `unselect`, `fit_view`, `zoom_in`, and `zoom_out`.
- Private assistant use: `chat_submit`.
- Incoming collaboration/status messages and ordinary component refresh messages
  continue without mutation authorization because they do not originate a local
  workspace mutation.

## Owner/manage operations

- Collaboration: `update_permission`.
- API-key LiveView: every event, including generation, deletion, validation, and
  one-time-secret flushing.
- Workspace settings LiveView: every event for an existing workspace.
- Repository-analysis lifecycle: `cancel_repo_analysis` and
  `retry_repo_analysis`.

Workspace creation and imports do not mutate an existing workspace and remain
outside the workspace-scoped hook. Existing-workspace update and deletion have
explicit owner checks at their context boundary.

## Content-write operations

Every remaining workspace event requires current Write access. This includes:

- Assumption, mitigation, threat, evidence, and threat-agent form saves,
  deletions, inline field updates, tags, comments, categorization, labels, and
  relationship linker events.
- Quill change/save events and shared assistant insertion messages.
- Data-flow save, raw-image export, graph commands, history commands, Mermaid
  import, metadata updates, threat generation, and threat linking.
- Brainstorm creation, update, deletion, restore, status, ordering, movement,
  clustering, and threat-builder actions.
- Reference-pack deletion, import, selection, and add-to-workspace actions.
- Threat-model quality-review start and lifecycle events (with the narrower
  owner/initiator policy additionally enforced by the service).

The mutation-producing messages `:execute_skill`, `:quill_change`,
`:quill_save`, `:update_metadata`, `"update_field"`, and relationship
`:selected_item` messages are also re-authorized before the parent LiveView can
handle them. Form `:saved` and generated-item refresh messages can only follow
an event already checked by the hook; PubSub messages from another authorized
session are incoming updates and remain readable.
