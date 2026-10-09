---
name: tf-guardrails
description: "Prevents common Terraform failures: provider version conflicts when adding or upgrading modules, AWS provider block-versus-attribute syntax errors, and checkov skip comments placed where checkov ignores them. Use when writing or reviewing Terraform, when 'terraform init' or 'validate' fails on constraints, or when checkov skips are not taking effect."
---
# tf-guardrails

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** instructional

## Description
Prevents common Terraform failures: provider version conflicts when adding or upgrading modules, AWS provider block-versus-attribute syntax errors, and checkov skip comments placed where checkov ignores them. Use when writing or reviewing Terraform, when 'terraform init' or 'validate' fails on constraints, or when checkov skips are not taking effect.

Before adding or upgrading a Terraform module, check provider version compatibility
to prevent `terraform validate` or CI failures caused by conflicting version constraints.

Invoke when: adding a new Terraform module, upgrading an existing module version,
or when `terraform init` or `validate` fails with provider constraint errors.

Prevent common AWS provider Terraform syntax errors: block-vs-attribute confusion
and deprecated argument patterns that vary between provider versions.

Invoke when: writing or reviewing Terraform for AWS resources, particularly VPC,
EC2, Cognito, or VPN endpoint resources where these errors occur most frequently.

Ensure checkov:skip comments are placed correctly inside resource blocks. Comments
placed before a resource block are silently ignored by checkov.

Invoke when: writing Terraform with checkov in the CI pipeline. Applies throughout
any infrastructure session where checkov scan results are evaluated.

## 1. Provider version compatibility

### Context needed
- Existing `required_providers` version constraints in `versions.tf`
- The module source and version being added or upgraded
- Provider registry page for the module (to read its `required_providers`)

### What to do

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

### Gotchas
- Unpinned modules (`source = "registry/module"` without a `version =`) resolve to
  latest on `terraform init -upgrade`, which may break provider constraints silently.
  Always pin module versions.
- Helm v3 dropped the nested `kubernetes {}` block syntax inside the helm provider.
  If upgrading from helm v2, this is a breaking change that requires syntax changes.
- GKE and GKE auth modules have separate version lines and separate provider constraints.
  A compatible GKE version may be incompatible with the corresponding GKE auth version.
- The `.terraform.lock.hcl` file is environment-specific if not locked for multiple
  platforms. Lock for both `linux_amd64` (CI) and `darwin_amd64` (local dev).

### Suggested scripts
- `tf-guardrails/check-provider-compat.sh` — extracts `required_providers` from all modules in use
  and reports any overlapping constraint conflicts

## 2. AWS provider syntax

### Context needed
- AWS provider version pinned in the project's `versions.tf` or `required_providers`
- Which resource types are being authored (determines which gotchas apply)

### What to do

1. **Check the provider version before writing resource blocks.** The AWS provider
   has changed block-vs-attribute syntax between major versions. Always consult the
   correct provider version docs, not general Terraform examples which may be stale.

2. **Apply these known patterns for common resource types:**

   **`aws_ec2_client_vpn_endpoint`:**
   - `dns_servers` is a list attribute, not a block:
     ```hcl
     dns_servers = ["1.1.1.1", "8.8.8.8"]   # correct
     # dns_servers { ... }                   # wrong
     ```

   **`aws_spot_instance_request` / `aws_launch_template`:**
   - `spot_price` is an attribute, not a block:
     ```hcl
     spot_price = "0.05"   # correct
     # spot_price { ... }  # wrong
     ```

   **`aws_cognito_user_pool_client`:**
   - Token validity units are nested inside `token_validity_units {}` block:
     ```hcl
     token_validity_units {
       access_token  = "minutes"
       id_token      = "minutes"
       refresh_token = "days"
     }
     ```

3. **Run `terraform validate` after any resource block change** before planning or
   applying. Syntax errors are caught by validate, not by plan.

4. **When an error says "Blocks of type X are not expected here"**, the argument
   is an attribute, not a block. Remove the `{}` and set it as `= value`.
   When it says "An argument named X is not expected here" inside a block, the
   argument has moved to a sub-block in the current provider version.

### Gotchas
- AWS provider changes argument types between major versions. An argument that was
  a block in provider 4.x may be an attribute in 5.x. Always check the provider
  changelog when upgrading.
- `terraform validate` does not require AWS credentials. Run it locally before any
  plan to catch syntax errors without a cloud round-trip.
- HCL error messages for block-vs-attribute confusion are readable but can be misleading.
  "Blocks of type X are not expected here" means X should be an attribute (`= value`),
  not a nested block.

### Suggested scripts
- None — `terraform validate` is the primary tool; run it before every plan

## 3. Checkov skip placement

### Context needed
- Which checkov rule IDs are being skipped and why
- The HCL resource block structure of the file being edited

### What to do

1. **Place `#checkov:skip` annotations inside the resource block body, never before it.**

   **Wrong — silently ignored:**
   ```hcl
   #checkov:skip=CKV_AWS_18: access logging not required
   resource "aws_s3_bucket" "example" {
     bucket = "example"
   }
   ```

   **Correct:**
   ```hcl
   resource "aws_s3_bucket" "example" {
     #checkov:skip=CKV_AWS_18: access logging not required for internal-only bucket
     bucket = "example"
   }
   ```

2. **Always include a justification comment on the same line as the skip.**
   `#checkov:skip=CKV_AWS_18` alone is not enough — add a colon and a reason:
   `#checkov:skip=CKV_AWS_18: <reason>`. This documents why the skip was accepted.

3. **After adding or moving skip annotations, run checkov locally to verify they
   are recognised:**
   ```bash
   checkov -d . --compact --quiet
   ```
   If the check still appears in the output after adding the skip, the annotation
   is in the wrong position.

4. **When reviewing Terraform for misplaced skips**, use the grep check:
   ```bash
   grep -n "checkov:skip" *.tf | grep -v "^.*{" | head -20
   ```
   Lines where the skip appears but the resource `{` is not on the same preceding
   line are candidates for misplacement.

### Gotchas
- Pre-block comments (with or without indentation) are not recognised by checkov.
  The annotation must be inside the `{...}` body of the resource block.
- Multiple skips on the same resource require one `#checkov:skip` line per rule.
  You cannot comma-separate rule IDs on a single skip line.
- checkov skip annotations are case-sensitive. `#checkov:skip` must be lowercase.
- Some checkov versions accept `# checkov:skip` with a space; pin your checkov version
  to avoid format-dependent behaviour.

### Suggested scripts
- `tf-guardrails/validate-checkov-skip-placement.sh` — scans all `.tf` files for skip annotations
  that appear to be outside resource blocks and reports line numbers
