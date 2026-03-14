# collaboration-and-access Specification

## Purpose
This specification defines the current baseline behavior for collaboration, access control, workspace permissions, and workspace API key management in Navigator. It covers how shared workspaces are protected and how access-related controls are administered.

## Requirements

### Requirement: Permission-aware workspace route protection
Navigator SHALL enforce workspace access checks for both controller and LiveView entry points.

#### Scenario: Authorizing a controller request for a workspace
- **WHEN** a controller request includes a workspace identifier
- **THEN** Navigator checks the current session identity against that workspace's permission model
- **AND** redirects unauthorized users to the workspace index instead of serving the protected route

#### Scenario: Authorizing a LiveView mount for a workspace
- **WHEN** a LiveView mounts with a workspace identifier
- **THEN** Navigator checks the current user against the workspace permission model
- **AND** halts unauthorized mounts with a redirect to the workspace index
- **AND** assigns the resolved workspace permission for authorized users

### Requirement: Workspace permission resolution
Navigator SHALL resolve workspace permissions by treating the owner as `owner` and reading non-owner access from the workspace permissions map.

#### Scenario: Resolving owner access
- **WHEN** the current identity matches the workspace owner
- **THEN** Navigator resolves the workspace permission as `owner`

#### Scenario: Resolving collaborator access
- **WHEN** the current identity is not the owner but appears in the workspace permissions map
- **THEN** Navigator resolves the workspace permission to the mapped permission value

#### Scenario: Resolving missing access
- **WHEN** the current identity is neither the owner nor present in the workspace permissions map
- **THEN** Navigator resolves the workspace permission as absent and denies protected workspace access

### Requirement: Workspace collaboration surface
Navigator SHALL provide a collaboration view for reviewing users and updating workspace collaborator permissions.

#### Scenario: Opening the collaboration view
- **WHEN** a user opens the collaboration route for a workspace
- **THEN** Navigator assigns the page title "Collaboration"
- **AND** loads the workspace, the current user, the resolved workspace permission, and the available users list

#### Scenario: Updating collaborator permissions as the owner
- **WHEN** the workspace owner updates a collaborator's permission from the collaboration view
- **THEN** Navigator updates the workspace permissions map
- **AND** reflects the updated workspace permissions in the collaboration state

#### Scenario: Rejecting collaborator permission changes by non-owners
- **WHEN** a user who is not the workspace owner attempts to update a collaborator permission
- **THEN** Navigator leaves the workspace permissions unchanged

#### Scenario: Removing collaborator access
- **WHEN** the owner sets a collaborator permission to `none`
- **THEN** Navigator removes that collaborator entry from the workspace permissions map

### Requirement: Workspace API key management
Navigator SHALL provide a workspace-scoped API key surface for listing, generating, deleting, and temporarily revealing newly created API keys.

#### Scenario: Opening the API key index
- **WHEN** a user opens the API key route for a workspace
- **THEN** Navigator assigns the page title "API Keys"
- **AND** loads the workspace API keys for that workspace
- **AND** initializes the recent API key state as empty

#### Scenario: Opening the generate API key route
- **WHEN** a user opens the API key generation route for a workspace
- **THEN** Navigator assigns the page title "Generate API Key"

#### Scenario: Refreshing API keys after generation
- **WHEN** the API key view receives a saved API key message
- **THEN** Navigator reloads the workspace API key list
- **AND** stores the newly created API key as the recent API key for one-time display

#### Scenario: Flushing a recently displayed API key
- **WHEN** the user dismisses the recent API key display
- **THEN** Navigator clears the recent API key from the view state

#### Scenario: Deleting an API key
- **WHEN** a user deletes an existing API key from the workspace API key view
- **THEN** Navigator removes the key
- **AND** refreshes the workspace API key list
- **AND** clears the recent API key display
- **AND** shows a success flash

#### Scenario: Handling failed API key deletion
- **WHEN** the API key does not exist or deletion fails
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