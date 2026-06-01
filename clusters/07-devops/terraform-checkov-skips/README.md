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

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/terraform-checkov-skips ~/.claude/skills/
```

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

## Roadmap

- [x] SKILL.md written and validated
- [ ] Write `validate-checkov-skip-placement.sh`
- [ ] Add common skip patterns and their justifications
- [x] Ship: copy to `~/.claude/skills/terraform-checkov-skips/`
