# terraform-version-compat

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Prevents provider version constraint conflicts when adding or upgrading Terraform
modules. Encodes the check sequence for reading module `required_providers`, spotting
incompatible version ranges, and locking the lock file for multiple platforms.
Extracted after recurring CI failures caused by constraint drift on module upgrades.

---

## What this skill does

Pre-flight check before any module addition or upgrade: reads the incoming module's
provider constraints, compares against the project's pinned versions, identifies
conflicts before they reach `terraform validate` or CI, and enforces `.terraform.lock.hcl`
platform coverage.

---

## When to use it

- Adding a new Terraform module to an existing project
- Upgrading an existing module to a newer version
- When `terraform init` or `terraform validate` fails with provider constraint errors
- When `.terraform.lock.hcl` is missing or only covers one platform

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/terraform-version-compat ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#terraform-version-compat
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

This skill activates implicitly during any Terraform session where a module is being
added or upgraded. It can also be invoked explicitly:

```
/terraform-version-compat
```

Claude will prompt for the module source/version and check it against the existing
`versions.tf` constraints.

---

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

---

## What it won't do

- Run `terraform init -upgrade` automatically — this can silently break constraints
- Resolve conflicts automatically — surfacing them for human decision is the goal
- Pin unpinned upstream modules — it flags them as a risk

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `check-provider-compat.sh` — extracts `required_providers` from all modules
      and reports constraint conflicts
- [ ] Add known-good version matrix for frequently used module combinations
