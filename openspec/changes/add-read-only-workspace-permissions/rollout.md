# Read-permission rollout and rollback

Read enforcement and owner assignment are both active when this release is deployed.
Stored `read` entries resolve to read-only access, and unknown values resolve to no access.
There is no rollout environment variable or feature flag.

## Pre-deployment audit

Run this against the production database and review every returned value before rollout:

```sql
SELECT permission.value AS stored_permission, count(*) AS assignments
FROM workspaces
CROSS JOIN LATERAL jsonb_each_text(COALESCE(permissions, '{}'::jsonb)) AS permission(identity, value)
GROUP BY permission.value
ORDER BY permission.value;
```

Only `write` and `read` are supported stored values. Unsupported values are denied by the
application and should be removed or converted deliberately.

## Deployment

1. Run the audit query and resolve unexplained permission values.
2. Deploy this release, including Read assignment and enforcement, to the application.
3. Confirm the deployment is not retaining nodes that use the older permission semantics.
4. Verify that owners can assign Read and that a reader cannot perform a forged mutation.

No configuration change or second deployment phase is required.

## Rollback

Before rolling back to a release that does not enforce Read, remove or convert all stored
`read` entries. To revoke them:

```sql
UPDATE workspaces
SET permissions = COALESCE(
  (
    SELECT jsonb_object_agg(permission.identity, permission.value)
    FROM jsonb_each_text(COALESCE(workspaces.permissions, '{}'::jsonb)) AS permission(identity, value)
    WHERE permission.value <> 'read'
  ),
  '{}'::jsonb
)
WHERE EXISTS (
  SELECT 1
  FROM jsonb_each_text(COALESCE(workspaces.permissions, '{}'::jsonb)) AS permission(identity, value)
  WHERE permission.value = 'read'
);
```

Alternatively, deploy a compatibility patch that explicitly denies `read` before restoring
older application code. Re-run the audit query and confirm it returns no `read` values before
the rollback proceeds.
