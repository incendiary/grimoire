# terraform-version-compat

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** instructional

## Description
Before adding or upgrading a Terraform module, check provider version compatibility
to prevent `terraform validate` or CI failures caused by conflicting version constraints.

Invoke when: adding a new Terraform module, upgrading an existing module version,
or when `terraform init` or `validate` fails with provider constraint errors.

## Context needed
- Existing `required_providers` version constraints in `versions.tf`
- The module source and version being added or upgraded
- Provider registry page for the module (to read its `required_providers`)

## What to do

1. **Before adding or upgrading a module, read its `required_providers` block** in the
   Terraform registry. Every module declares which provider versions it supports.
   Compare this against the constraints already in your `versions.tf`.

2. **Check for constraint conflicts.** The project's pinned provider version must
   satisfy all module constraints simultaneously. Example failure pattern:
   ```
   module A: requires google >= 5.0, < 6.0
   module B: requires google >= 6.18
   → conflict: no version satisfies both constraints
   ```
   Resolve by finding a compatible version range or updating the older module.

3. **When upgrading a module, check for breaking syntax changes** between major
   versions. Helm v2→v3, GKE v25→v26, and similar upgrades often have breaking
   argument changes. Read the module changelog before upgrading.

4. **Lock provider versions after resolving conflicts:**
   ```bash
   terraform providers lock -platform=linux_amd64 -platform=darwin_amd64
   ```
   Commit the `.terraform.lock.hcl` file. This prevents different environments from
   resolving to different provider versions.

5. **Run `terraform init -upgrade` only when intentionally upgrading.** Running it
   routinely can pull in provider versions that break existing modules.

## Gotchas
- Unpinned modules (`source = "registry/module"` without a `version =`) resolve to
  latest on `terraform init -upgrade`, which may break provider constraints silently.
  Always pin module versions.
- Helm v3 dropped the nested `kubernetes {}` block syntax inside the helm provider.
  If upgrading from helm v2, this is a breaking change that requires syntax changes.
- GKE and GKE auth modules have separate version lines and separate provider constraints.
  A compatible GKE version may be incompatible with the corresponding GKE auth version.
- The `.terraform.lock.hcl` file is environment-specific if not locked for multiple
  platforms. Lock for both `linux_amd64` (CI) and `darwin_amd64` (local dev).

## Suggested scripts
- `check-provider-compat.sh` — extracts `required_providers` from all modules in use
  and reports any overlapping constraint conflicts
