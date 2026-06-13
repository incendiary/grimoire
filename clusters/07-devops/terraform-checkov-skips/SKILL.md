# terraform-checkov-skips

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** instructional

## Description
Ensure checkov:skip comments are placed correctly inside resource blocks. Comments
placed before a resource block are silently ignored by checkov.

Invoke when: writing Terraform with checkov in the CI pipeline. Applies throughout
any infrastructure session where checkov scan results are evaluated.

## Context needed
- Which checkov rule IDs are being skipped and why
- The HCL resource block structure of the file being edited

## What to do

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

## Gotchas
- Pre-block comments (with or without indentation) are not recognised by checkov.
  The annotation must be inside the `{...}` body of the resource block.
- Multiple skips on the same resource require one `#checkov:skip` line per rule.
  You cannot comma-separate rule IDs on a single skip line.
- checkov skip annotations are case-sensitive. `#checkov:skip` must be lowercase.
- Some checkov versions accept `# checkov:skip` with a space; pin your checkov version
  to avoid format-dependent behaviour.

## Suggested scripts
- `validate-checkov-skip-placement.sh` — scans all `.tf` files for skip annotations
  that appear to be outside resource blocks and reports line numbers
