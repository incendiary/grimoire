# terraform-aws-syntax

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Prevents block-vs-attribute syntax errors in AWS provider Terraform. Encodes the
known patterns for VPN endpoints, spot instances, and Cognito where the provider has
inconsistent or version-sensitive argument types. Extracted after the same class of
error occurred multiple times in a Terraform session.

---

## What this skill does

Pre-loads the known AWS provider syntax gotchas for commonly-used resource types.
Enforces `terraform validate` as the first check after any resource block change.

---

## When to use it

Any Terraform session touching AWS resources — particularly VPN endpoints, EC2/spot,
and Cognito resources.

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/terraform-aws-syntax ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#terraform-aws-syntax
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Block vs attribute quick reference

| Resource | Argument | Type | Correct form |
|----------|----------|------|-------------|
| `aws_ec2_client_vpn_endpoint` | `dns_servers` | attribute (list) | `dns_servers = [...]` |
| `aws_launch_template` | `spot_price` | attribute | `spot_price = "0.05"` |
| `aws_cognito_user_pool_client` | token validity | block | `token_validity_units { ... }` |

When Terraform says "Blocks of type X are not expected here" → X is an attribute.
When it says "An argument named X is not expected here" inside a block → X moved to a sub-block.

---

## Provider version matrix — known argument type changes

AWS provider breaking changes that cause argument-vs-block syntax errors. When a
`plan` or `apply` fails with "Blocks of type X are not expected" or "An argument
named X is not expected", check the provider version the project is locked to.

| Resource | Argument / block | Changed in | Old form (pre-change) | New form (post-change) |
|---|---|---|---|---|
| `aws_s3_bucket` | Lifecycle rules | `hashicorp/aws` v4.0 | Inline `lifecycle_rule {}` block | Separate `aws_s3_bucket_lifecycle_configuration` resource |
| `aws_s3_bucket` | Versioning | `hashicorp/aws` v4.0 | Inline `versioning {}` block | Separate `aws_s3_bucket_versioning` resource |
| `aws_s3_bucket` | Server-side encryption | `hashicorp/aws` v4.0 | Inline `server_side_encryption_configuration {}` | Separate `aws_s3_bucket_server_side_encryption_configuration` resource |
| `aws_s3_bucket` | ACL | `hashicorp/aws` v4.0 | Inline `acl = "private"` attribute | Separate `aws_s3_bucket_acl` resource |
| `aws_s3_bucket` | Logging | `hashicorp/aws` v4.0 | Inline `logging {}` block | Separate `aws_s3_bucket_logging` resource |
| `aws_security_group` | Ingress/egress rules | `hashicorp/aws` v4.0+ | Inline `ingress {}` / `egress {}` blocks | Still supported inline; prefer separate `aws_security_group_rule` to avoid plan-time conflicts |
| `aws_db_instance` | `password` | `hashicorp/aws` v5.0 | `password = var.db_pass` | `password` triggers replacement on every plan if tracked in state; use `manage_master_user_password = true` instead |
| `aws_ecs_task_definition` | `container_definitions` | All versions | JSON string | Still a JSON string; common error is nesting HCL block syntax inside the string |
| `aws_lambda_function` | `environment` | `hashicorp/aws` < v2 → v2+ | `environment { variables = {} }` | Same; still a block — no change, but must not be set to `null` if empty (use `{}` or omit entirely) |
| `aws_eks_cluster` | `kubernetes_network_config` | `hashicorp/aws` v3.28+ | Not present | Block added; `ip_family` argument inside it; do not specify as top-level attribute |
| `aws_cloudwatch_metric_alarm` | `metric_query` | `hashicorp/aws` v2.0+ | `metric_name` + `namespace` as top-level | Move to `metric_query { metric {} }` block for multi-source alarms |
| `aws_acm_certificate` | `options` | All versions | Inline block | Block, not attribute; `certificate_transparency_logging_preference` inside |

**Lock file tip:** if the team is on `hashicorp/aws` v3.x and you write v4-style
standalone bucket resources, `terraform init` will fail to plan unless the version
constraint in `required_providers` is updated to `>= 4.0`. Always check:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/registry.terraform.io/hashicorp/aws"
      version = "~> 5.0"   # check this matches the resources you're writing
    }
  }
}
```

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Add resource type gotchas as they are encountered
- [x] Add provider version matrix for known argument type changes
- [x] Ship: copy to `~/.claude/skills/terraform-aws-syntax/`
