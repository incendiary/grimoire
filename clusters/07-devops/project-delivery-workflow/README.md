# project-delivery-workflow

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-06-01

End-to-end GitHub project delivery: clone cold, read all nested READMEs to extract
the roadmap, work each item as a feature branch → PR → CI check → merge, keep
READMEs and versions in sync throughout, and close with a major version bump and
GitHub release.

---

## What this skill does

Encodes the full delivery loop for a structured project session. Prevents the common
failure modes: starting to code before reading all the READMEs, merging without
waiting for CI, forgetting to tick off roadmap items, version drift, and pushing
tags before the SSH key is confirmed.

---

## When to use it

- Handed a repo and asked to complete outstanding roadmap items
- Starting a structured delivery session on any GitHub project
- Picking up a project that was partially delivered in a previous session

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/project-delivery-workflow ~/.claude/skills/
```

---

## Invocation

```
/project-delivery-workflow
Repo: incendiary/StartingPoint
Version file: pyproject.toml
Branch strategy: feature branch per item, PR to main
```

Or implicitly — Claude recognises the "clone, review READMEs, complete roadmap"
pattern and applies the workflow.

---

## Workflow

```
gh repo clone → read all nested READMEs
        ↓
Extract outstanding roadmap items → propose delivery plan
        ↓
Confirm plan (one pause)
        ↓
For each item:
  git checkout -b feat/<name>
  → implement
  → gh pr create
  → gh pr checks --watch (wait for green)
  → gh pr merge --squash --delete-branch
  → git pull main
  → tick README, bump version, commit to main
        ↓
Final item complete:
  major version bump → git tag → gh release create
        ↓
gh release view — confirm release is correct
```

---

## Related skills

- `roadmap-sync` — for standalone README roadmap updates outside a full delivery session
- `github-release-workflow` — for the release/tag mechanics in detail
- `git-push-protocol-handler` — for SSH push failures mid-session

---

## What it won't do

- Open PRs without a delivery plan confirmed first — always proposes before executing
- Merge a PR with failing CI — blocks and diagnoses before proceeding
- Assume a `[ ]` item is outstanding — checks the code matches the README state

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Add variant for monorepo (multiple packages, separate version files)
- [ ] Add guidance for repos with required reviewers (can't self-merge)
- [ ] Add post-delivery checklist (branch cleanup, stale draft PR cleanup, tag verification)
