# collaboration-and-access Specification

## Purpose
This specification defines the current baseline behavior for collaboration, access control, workspace permissions, and workspace API key management in Navigator. It covers how shared workspaces are protected and how access-related controls are administered.
## Requirements
### Requirement: Permission-aware workspace route protection
Navigator SHALL enforce capability-aware workspace access checks for controller and LiveView entry points.

#### Scenario: Authorizing a readable controller request for a workspace
- **WHEN** a controller request includes a workspace identifier for a read-authorized session identity
- **THEN** Navigator serves the protected read or export route

#### Scenario: Rejecting an unauthorized controller request for a workspace
- **WHEN** a controller request includes a workspace identifier for an identity without a valid readable role
- **THEN** Navigator redirects the user to the workspace index instead of serving the protected route

#### Scenario: Authorizing a readable LiveView mount for a workspace
- **WHEN** a LiveView mounts with a workspace identifier for a user with `owner`, `write`, or `read` access
- **THEN** Navigator continues the mount
- **AND** assigns the effective workspace role and presentation capabilities

#### Scenario: Rejecting an unauthorized LiveView mount
- **WHEN** a LiveView mounts with a workspace identifier for a user without a valid readable role
- **THEN** Navigator halts the mount with a redirect to the workspace index

#### Scenario: Reader opens a write-only route
- **WHEN** a reader directly opens a workspace create, relationship-management, categorization, import, generation, settings, or other write-only route
- **THEN** Navigator redirects the reader to the nearest readable workspace route
- **AND** does not mount the write workflow or load privileged records

### Requirement: Workspace permission resolution
Navigator SHALL resolve workspace permissions by deriving `owner` from workspace ownership and accepting only `read` or `write` as stored collaborator roles.

#### Scenario: Resolving owner access
- **WHEN** the current identity matches the workspace owner
- **THEN** Navigator resolves the effective workspace role as `owner`

#### Scenario: Resolving reader access
- **WHEN** the current identity is not the owner and maps to `read` in the workspace permissions map
- **THEN** Navigator resolves the effective workspace role as `read`

#### Scenario: Resolving writer access
- **WHEN** the current identity is not the owner and maps to `write` in the workspace permissions map
- **THEN** Navigator resolves the effective workspace role as `write`

#### Scenario: Resolving invalid collaborator access
- **WHEN** the current identity maps to an unsupported permission value
- **THEN** Navigator resolves workspace permission as absent
- **AND** denies protected workspace access

#### Scenario: Resolving missing access
- **WHEN** the current identity is neither the owner nor present with a valid role in the workspace permissions map
- **THEN** Navigator resolves workspace permission as absent
- **AND** denies protected workspace access

### Requirement: Workspace collaboration surface
Navigator SHALL provide an owner-managed collaboration view for reviewing users and assigning `Read`, `Write`, or `None` collaborator access.

#### Scenario: Opening the collaboration view as the owner
- **WHEN** the workspace owner opens the collaboration route
- **THEN** Navigator assigns the page title "Collaboration"
- **AND** loads the workspace, current user, resolved role, and available users
- **AND** offers `Read`, `Write`, and `None` permission choices for other users

#### Scenario: Opening the collaboration view as a collaborator
- **WHEN** a reader or writer opens the collaboration route
- **THEN** Navigator shows the workspace owner and the collaborator's current role
- **AND** does not show permission-management controls or the available-users administration list

#### Scenario: Assigning read permission as the owner
- **WHEN** the workspace owner assigns `Read` to a collaborator
- **THEN** Navigator stores `read` for that identity
- **AND** reflects the updated permission in the collaboration state
- **AND** publishes the permission change to connected sessions

#### Scenario: Assigning write permission as the owner
- **WHEN** the workspace owner assigns `Write` to a collaborator
- **THEN** Navigator stores `write` for that identity
- **AND** reflects the updated permission in the collaboration state
- **AND** publishes the permission change to connected sessions

#### Scenario: Rejecting collaborator permission changes by non-owners
- **WHEN** a user who is not the current workspace owner attempts to update a collaborator permission
- **THEN** Navigator rejects the operation
- **AND** leaves the workspace permissions unchanged

#### Scenario: Rejecting an unsupported permission value
- **WHEN** the owner or a forged request attempts to store a permission other than `read`, `write`, or the removal command `none`
- **THEN** Navigator returns a validation error
- **AND** leaves the workspace permissions unchanged

#### Scenario: Removing collaborator access
- **WHEN** the owner sets a collaborator permission to `none`
- **THEN** Navigator removes that collaborator entry from the workspace permissions map
- **AND** publishes the access removal to connected sessions

### Requirement: Workspace API key management
Navigator SHALL restrict workspace API key listing, generation, deletion, and one-time key revelation to the current workspace owner.

#### Scenario: Opening the API key index as the owner
- **WHEN** the workspace owner opens the API key route
- **THEN** Navigator assigns the page title "API Keys"
- **AND** loads only that workspace's API keys
- **AND** initializes the recent API key state as empty

#### Scenario: Rejecting the API key index for a non-owner
- **WHEN** a reader or writer opens the API key route
- **THEN** Navigator redirects the user to a readable workspace route
- **AND** does not load or render workspace API key records

#### Scenario: Opening the generate API key route as the owner
- **WHEN** the workspace owner opens the API key generation route
- **THEN** Navigator assigns the page title "Generate API Key"
- **AND** renders the generation workflow

#### Scenario: Rejecting API key generation by a non-owner
- **WHEN** a reader or writer opens or submits the API key generation workflow
- **THEN** Navigator rejects the operation
- **AND** does not create or reveal a key

#### Scenario: Refreshing API keys after generation
- **WHEN** the owner API key view receives a saved API key message
- **THEN** Navigator reloads the workspace API key list
- **AND** stores the newly created API key as the recent API key for one-time display

#### Scenario: Flushing a recently displayed API key
- **WHEN** the owner dismisses the recent API key display
- **THEN** Navigator clears the recent API key from the view state

#### Scenario: Deleting an API key as the owner
- **WHEN** the current workspace owner deletes an existing API key from the workspace API key view
- **THEN** Navigator removes the key
- **AND** refreshes the workspace API key list
- **AND** clears the recent API key display
- **AND** shows a success flash

#### Scenario: Rejecting API key deletion by a non-owner
- **WHEN** a reader or writer submits a deletion event for a workspace API key
- **THEN** Navigator rejects the operation
- **AND** leaves the key active and unchanged

#### Scenario: Handling failed API key deletion
- **WHEN** the API key does not exist or owner-authorized deletion fails
- **THEN** Navigator keeps the current API key list intact
- **AND** shows an error flash

### Requirement: API authentication behavior
Navigator SHALL protect API requests with bearer-token authentication backed by workspace API keys.

#### Scenario: Rejecting missing or invalid API credentials
- **WHEN** an API request has no authorization header, an invalid token, an expired token, a tampered token, or an inactive API key
- **THEN** Navigator returns HTTP 401 Unauthorized
- **AND** halts the request instead of assigning an API key context

#### Scenario: Accepting a valid API key
- **WHEN** an API request supplies a valid active API key bearer token
- **THEN** Navigator assigns the decoded API key to the request context
- **AND** updates the API key's `last_used` timestamp

### Requirement: Workspace roles grant explicit capabilities
Navigator SHALL grant workspace capabilities only through the effective `owner`, `write`, and `read` roles. Owners SHALL have read, write, and manage capabilities; writers SHALL have read and write capabilities; readers SHALL have read capability only; and unknown or absent roles SHALL have no capability.

#### Scenario: Reader views workspace content and exports
- **WHEN** a collaborator with `read` permission opens a readable workspace page, report, print view, or export endpoint
- **THEN** Navigator serves the requested workspace content
- **AND** keeps the request scoped to that workspace

#### Scenario: Writer changes threat-model content
- **WHEN** a collaborator with current `write` permission performs a supported workspace content mutation
- **THEN** Navigator authorizes the mutation
- **AND** applies the same persistence and collaboration behavior available to the workspace owner for that content

#### Scenario: Reader cannot manage workspace content or settings
- **WHEN** a collaborator with current `read` permission attempts to change workspace content, relationships, shared drafts, diagrams, imports, jobs, permissions, or credentials
- **THEN** Navigator rejects the operation
- **AND** leaves persistent records, shared caches, and collaborative state unchanged

#### Scenario: Unknown stored permission grants no capability
- **WHEN** an identity is present in the workspace permissions map with a value other than `read` or `write`
- **THEN** Navigator treats the identity as unauthorized
- **AND** does not list or serve the workspace to that identity

### Requirement: Interactive workspace mutations use current authorization
Navigator SHALL evaluate the acting identity's current workspace capability at the server-side mutation boundary and SHALL NOT authorize a mutation solely from controls rendered in the browser or a permission assigned when a LiveView mounted.

#### Scenario: Forged reader event is rejected
- **WHEN** a reader submits a validly shaped create, update, delete, link, import, editor, diagram, job, or settings event that was not offered by the read-only interface
- **THEN** Navigator rejects the event before changing persistent or shared state

#### Scenario: Downgraded writer cannot use an existing socket to write
- **WHEN** a collaborator's permission changes from `write` to `read` while their workspace LiveView remains connected
- **AND** that collaborator attempts another mutation from the existing socket
- **THEN** Navigator evaluates the current `read` permission
- **AND** rejects the mutation without changing workspace state

#### Scenario: Reader cannot alter a shared draft before save
- **WHEN** a reader attempts to submit a rich-text operation, graph operation, brainstorm operation, or other workspace-scoped draft event
- **THEN** Navigator does not append the operation to a workspace cache
- **AND** does not broadcast the operation to collaborators

#### Scenario: Read-only view has no persistence side effect
- **WHEN** a reader opens a readable workspace surface whose backing record does not yet exist
- **THEN** Navigator renders an empty read-only representation
- **AND** does not create the missing record merely because it was viewed

### Requirement: Read-only workspace presentation preserves inspection and collaboration
Navigator SHALL clearly indicate read-only access and SHALL remove or disable mutation affordances while preserving non-mutating inspection and incoming real-time collaboration.

#### Scenario: Opening a workspace as a reader
- **WHEN** a collaborator with `read` permission opens a workspace
- **THEN** Navigator displays a read-only indication
- **AND** omits or disables create, edit, delete, save, import, generation, categorization, linking, job-lifecycle, collaboration-management, and credential-management actions

#### Scenario: Reader filters and inspects workspace content
- **WHEN** a reader searches, filters, changes local pagination, selects an item for inspection, or opens a readable detail view
- **THEN** Navigator updates only local presentation state
- **AND** does not reject the interaction as a workspace mutation

#### Scenario: Reader receives collaborator updates
- **WHEN** another authorized user changes workspace content while a reader is connected
- **THEN** Navigator delivers the existing workspace-scoped real-time update to the reader
- **AND** refreshes the read-only representation without enabling local editing

#### Scenario: Reader opens a detail route implemented as an edit action
- **WHEN** a readable entity detail page shares its LiveView action with the entity's edit workflow
- **THEN** Navigator allows the reader to inspect the entity
- **AND** renders its fields and relationships without writable controls

### Requirement: Permission changes update connected sessions
Navigator SHALL publish workspace permission changes and re-resolve the affected identity's role in connected workspace sessions.

#### Scenario: Connected writer is downgraded to reader
- **WHEN** the owner changes a connected collaborator from `write` to `read`
- **THEN** Navigator updates that collaborator's connected workspace views to read-only presentation
- **AND** subsequent mutations are rejected using the current role

#### Scenario: Connected reader is upgraded to writer
- **WHEN** the owner changes a connected collaborator from `read` to `write`
- **THEN** Navigator updates that collaborator's connected workspace views to writer presentation without requiring a new login

#### Scenario: Connected collaborator loses access
- **WHEN** the owner changes a connected collaborator's permission to `none`
- **THEN** Navigator removes the permission entry
- **AND** redirects or disconnects that collaborator from protected workspace routes
