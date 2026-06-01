# github-release-workflow

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

The full issue-to-release flow in one skill: issue → branch → version bump → PR →
CI wait → merge → tag → GitHub release. Extracted after the same 7-step sequence was
repeated 8 times in a DNSResolver session.

---

## What this skill does

Provides the complete, ordered release procedure with the correct `gh` CLI commands
at each step. Includes the SSH/HTTPS fallback check for tag push, the CI-wait gate
before merge, and the post-merge pull before tagging.

---

## When to use it

Any session where you are cutting a versioned release. Works for Python, C#, and any
repo using GitHub releases and semver tags.

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/github-release-workflow ~/.claude/skills/
```

---

## Flow summary

```
gh issue create (optional)
        ↓
git checkout -b release/vX.Y.Z
        ↓
Bump version in pyproject.toml / __version__.py
        ↓
git commit + push
        ↓
gh pr create → gh pr checks --watch
        ↓
gh pr merge --squash --delete-branch
        ↓
git checkout main && git pull
        ↓
git tag vX.Y.Z && git push origin vX.Y.Z
        ↓
gh release create vX.Y.Z
```

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Write `release.sh` parameterised script
- [ ] Add CHANGELOG generation step
- [ ] Add variant for repos without a release branch (direct tag on main)
- [ ] Test on DNSResolver v2 release
- [x] Ship: copy to `~/.claude/skills/github-release-workflow/`
