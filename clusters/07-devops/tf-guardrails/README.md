# tf-guardrails

Terraform guardrails: provider version compatibility, AWS provider syntax, and checkov skip placement.

Prevents provider version constraint conflicts when adding or upgrading Terraform
modules. Encodes the check sequence for reading module `required_providers`, spotting
incompatible version ranges, and locking the lock file for multiple platforms.
Extracted after recurring CI failures caused by constraint drift on module upgrades.

Prevents block-vs-attribute syntax errors in AWS provider Terraform. Encodes the
known patterns for VPN endpoints, spot instances, and Cognito where the provider has
inconsistent or version-sensitive argument types. Extracted after the same class of
error occurred multiple times in a Terraform session.

Prevents the silent-ignore bug where checkov skip annotations placed before a resource
block have no effect. Extracted after skip comments were misplaced multiple times in a
Terraform session, causing checkov to continue flagging resources that appeared skipped.

## What this skill does

### Provider version compatibility

Pre-flight check before any module addition or upgrade: reads the incoming module's
provider constraints, compares against the project's pinned versions, identifies
conflicts before they reach `terraform validate` or CI, and enforces `.terraform.lock.hcl`
platform coverage.

### AWS provider syntax

Pre-loads the known AWS provider syntax gotchas for commonly-used resource types.
Enforces `terraform validate` as the first check after any resource block change.

### Checkov skip placement

Enforces the correct placement of `#checkov:skip` annotations — inside the resource
block body, never before it. Provides a local validation command to confirm skips are
recognised before pushing.

## When to use it

### Provider version compatibility

- Adding a new Terraform module to an existing project
- Upgrading an existing module to a newer version
- When `terraform init` or `terraform validate` fails with provider constraint errors
- When `.terraform.lock.hcl` is missing or only covers one platform

### AWS provider syntax

Any Terraform session touching AWS resources — particularly VPN endpoints, EC2/spot,
and Cognito resources.

### Checkov skip placement

Any Terraform session where checkov is part of the CI pipeline.

## Invocation

This skill activates implicitly during any Terraform session where a module is being
added or upgraded. It can also be invoked explicitly:

```
/tf-guardrails
```

Claude will prompt for the module source/version and check it against the existing
`versions.tf` constraints.

## Workflow

```
Read module required_providers (registry page)
        ↓
Compare against versions.tf pinned constraints
        ↓
Conflict? → resolve by tightening version range or upgrading older module
No conflict? → continue
        ↓
Check changelog for breaking argument changes (major version bumps)
        ↓
terraform providers lock -platform=linux_amd64 -platform=darwin_amd64
        ↓
Commit .terraform.lock.hcl
```

## What it won't do

- Run `terraform init -upgrade` automatically — this can silently break constraints
- Resolve conflicts automatically — surfacing them for human decision is the goal
- Pin unpinned upstream modules — it flags them as a risk

## Block vs attribute quick reference

| Resource | Argument | Type | Correct form |
|----------|----------|------|-------------|
| `aws_ec2_client_vpn_endpoint` | `dns_servers` | attribute (list) | `dns_servers = [...]` |
| `aws_launch_template` | `spot_price` | attribute | `spot_price = "0.05"` |
| `aws_cognito_user_pool_client` | token validity | block | `token_validity_units { ... }` |

When Terraform says "Blocks of type X are not expected here" → X is an attribute.
When it says "An argument named X is not expected here" inside a block → X moved to a sub-block.

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

## Skip placement rule

```hcl
# WRONG — outside the block, silently ignored
#checkov:skip=CKV_AWS_18: reason
resource "aws_s3_bucket" "x" { ... }

# CORRECT — inside the block body
resource "aws_s3_bucket" "x" {
  #checkov:skip=CKV_AWS_18: reason
  bucket = "x"
}
```

## Common skip patterns and justifications

Use these as templates. Replace the justification text with the specific reason that
applies to your infrastructure. A skip without a reason is a skip that will confuse
the next reader.

### S3

```hcl
resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_18: Access logging disabled — this bucket IS the access log target; logging to itself is circular
  #checkov:skip=CKV_AWS_144: Cross-region replication not required — single-region log archive, recovery RTO acceptable
  #checkov:skip=CKV2_AWS_61: Lifecycle configuration managed externally via S3 Intelligent-Tiering policy
  bucket = "my-access-logs"
}

resource "aws_s3_bucket" "public_assets" {
  #checkov:skip=CKV_AWS_20: Public read is intentional — this bucket serves static website assets
  #checkov:skip=CKV2_AWS_6: Public access block disabled intentionally — see above
  bucket = "my-public-cdn-assets"
}
```

### EC2 / Launch Template

```hcl
resource "aws_instance" "bastion" {
  #checkov:skip=CKV_AWS_8: Detailed monitoring not enabled — bastion host; CloudWatch agent provides sufficient coverage
  #checkov:skip=CKV_AWS_126: Detailed monitoring: cost decision accepted by engineering lead
  ami           = var.ami_id
  instance_type = "t3.micro"
}

resource "aws_launch_template" "workers" {
  #checkov:skip=CKV_AWS_79: IMDSv2 not enforced — legacy application does not support IMDSv2 token flow; tracked in backlog
  name_prefix = "worker-"
}
```

### IAM

```hcl
resource "aws_iam_role_policy" "deploy" {
  #checkov:skip=CKV_AWS_290: Write permissions required — this role deploys Lambda functions; narrowest viable scope
  #checkov:skip=CKV_AWS_355: Resource wildcard required for Lambda:* on dynamic function names at deploy time
  name = "deploy-policy"
  role = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
```

### Security Groups

```hcl
resource "aws_security_group_rule" "internal_ssh" {
  #checkov:skip=CKV_AWS_25: SSH open to internal CIDR only (10.0.0.0/8) — not to 0.0.0.0/0; checkov does not distinguish
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
  security_group_id = aws_security_group.bastion.id
}
```

### RDS

```hcl
resource "aws_db_instance" "dev" {
  #checkov:skip=CKV_AWS_17: Publicly accessible — dev database, isolated VPC, no production data
  #checkov:skip=CKV_AWS_133: Backup retention 1 day — dev environment, not subject to RPO requirements
  #checkov:skip=CKV_AWS_157: Multi-AZ disabled — dev environment; cost control
  identifier = "dev-db"
}
```

### Lambda

```hcl
resource "aws_lambda_function" "processor" {
  #checkov:skip=CKV_AWS_116: Dead letter queue not required — idempotent processor; failures are retried by SQS
  #checkov:skip=CKV_AWS_272: Code signing not enforced — deployment is CI/CD pipeline gated; code signing out of scope
  function_name = "event-processor"
}
```

### CloudTrail / Logging

```hcl
resource "aws_cloudtrail" "management" {
  #checkov:skip=CKV_AWS_252: SNS notification not configured — alerts handled via CloudWatch Alarm → PagerDuty integration
  name = "management-trail"
}
```

## Roadmap

- [x] **Version compat:** SKILL.md written and validated
- [x] **Version compat:** README.md written
- [x] **Version compat:** Write `check-provider-compat.sh` — extracts `required_providers` from all modules
      and reports constraint conflicts
- [ ] **Version compat:** Add known-good version matrix for frequently used module combinations

- [x] **AWS syntax:** SKILL.md written and validated
- [x] **AWS syntax:** Add provider version matrix for known argument type changes
- [x] **AWS syntax:** Ship: copy to `~/.claude/skills/tf-guardrails/`

- [x] **Checkov skips:** SKILL.md written and validated
- [x] **Checkov skips:** Write `validate-checkov-skip-placement.sh`
- [x] **Checkov skips:** Add common skip patterns and their justifications
- [x] **Checkov skips:** Ship: copy to `~/.claude/skills/tf-guardrails/`
