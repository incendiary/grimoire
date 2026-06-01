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

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/terraform-aws-syntax ~/.claude/skills/
```

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

## Roadmap

- [x] SKILL.md written and validated
- [ ] Add resource type gotchas as they are encountered
- [ ] Add provider version matrix for known argument type changes
- [x] Ship: copy to `~/.claude/skills/terraform-aws-syntax/`
