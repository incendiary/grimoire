# terraform-checkov-skips

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Prevents the silent-ignore bug where checkov skip annotations placed before a resource
block have no effect. Extracted after skip comments were misplaced multiple times in a
Terraform session, causing checkov to continue flagging resources that appeared skipped.

---

## What this skill does

Enforces the correct placement of `#checkov:skip` annotations — inside the resource
block body, never before it. Provides a local validation command to confirm skips are
recognised before pushing.

---

## When to use it

Any Terraform session where checkov is part of the CI pipeline.

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/terraform-checkov-skips ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#terraform-checkov-skips
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

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

---

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

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `validate-checkov-skip-placement.sh`
- [x] Add common skip patterns and their justifications
- [x] Ship: copy to `~/.claude/skills/terraform-checkov-skips/`
