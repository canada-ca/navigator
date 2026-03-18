---
name: update-deps
description: Update outdated Elixir dependencies
---

# Update Elixir Dependencies

Update all outdated dependencies in this Elixir project, handling both safe updates and breaking changes.

## Workflow

### 1. Identify Outdated Dependencies

Run `mix hex.outdated` to get a list of all outdated dependencies. Parse the output to identify:
- **Safe updates**: Dependencies where only the patch or minor version has changed (no major version bump)
- **Breaking updates**: Dependencies with a major version change (e.g., 1.x.x → 2.x.x)

### 2. Apply Safe Updates

Run `mix deps.update --all` to update all dependencies. This will apply updates within the version constraints specified in `mix.exs`.

### 3. Handle Breaking Changes

For each dependency with a breaking major version change:

1. **Update the version constraint** in `mix.exs` to allow the new major version

2. **Find the changelog or upgrade guide** using this approach:
   - First, try `https://hexdocs.pm/{package_name}/changelog.html`
   - If not found, go to the project root at `https://hexdocs.pm/{package_name}` and look for:
     - Links to "Changelog", "CHANGELOG", "Upgrade Guide", or "Migration Guide" in the sidebar navigation
     - Any "Upgrading" or "Breaking Changes" sections in the documentation
   - Extract the relevant breaking changes between your current version and the target version

3. **Review breaking changes** and apply necessary code modifications

4. **Run verification** after each breaking change update before moving to the next

### 4. Verification

After updates, run these commands and fix any issues:

```bash
# Compile with warnings as errors
mix compile --warnings-as-errors

# Check formatting
mix format --check-formatted

# Run tests
mix test
```

If any verification step fails:
- For compile warnings: Fix the warning in the code
- For format issues: Run `mix format` to auto-fix
- For test failures: Debug and fix the failing tests

### 5. Final Steps

Once all verifications pass:
1. Run `mix hex.outdated` again to confirm all dependencies are up to date
2. Summarize what was updated, including any breaking changes that required code modifications
