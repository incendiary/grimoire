# terraform-aws-syntax

> **Status:** COMPLETE
> **Cluster:** 07-devops

## Description
Prevent common AWS provider Terraform syntax errors: block-vs-attribute confusion
and deprecated argument patterns that vary between provider versions.

Invoke when: writing or reviewing Terraform for AWS resources, particularly VPC,
EC2, Cognito, or VPN endpoint resources where these errors occur most frequently.

## Context needed
- AWS provider version pinned in the project's `versions.tf` or `required_providers`
- Which resource types are being authored (determines which gotchas apply)

## What to do

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

## Gotchas
- AWS provider changes argument types between major versions. An argument that was
  a block in provider 4.x may be an attribute in 5.x. Always check the provider
  changelog when upgrading.
- `terraform validate` does not require AWS credentials. Run it locally before any
  plan to catch syntax errors without a cloud round-trip.
- HCL error messages for block-vs-attribute confusion are readable but can be misleading.
  "Blocks of type X are not expected here" means X should be an attribute (`= value`),
  not a nested block.

## Suggested scripts
- None — `terraform validate` is the primary tool; run it before every plan
