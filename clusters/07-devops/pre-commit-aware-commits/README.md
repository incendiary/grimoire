# pre-commit-aware-commits

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Prevents the commit–fail–fix–recommit loop by running pre-commit before attempting
`git commit`. Enforces the correct re-stage and review step when hooks auto-modify files.
Extracted after black, isort, and flake8 hooks caused 4 failed commits in a single session.

---

## What this skill does

Establishes a fixed commit procedure for projects with pre-commit hooks:
1. `pre-commit run` (check before commit attempt)
2. If hooks modify files: `git diff` → `git add -u` → commit
3. Never `--no-verify` without explicit user request
4. Always review gitleaks findings before adding allowlist entries

---

## When to use it

Any project with a `.pre-commit-config.yaml`. Load at session start so the procedure
applies to every commit in the session.

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/pre-commit-aware-commits ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#pre-commit-aware-commits
```

### MCP client

Register the grimoire MCP server — this skill is exposed as tool `pre_commit_aware_commits`.

> **Note:** This is an `action` type skill — available as MCP tool, prompt file, and Claude Code.


---

## Commit procedure quick reference

```bash
pre-commit run              # check staged files first
# If hooks modify files:
git diff                    # review what changed
git add -u                  # re-stage
git status                  # verify staging
git commit -m "..."         # now commit
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `pre_commit_check.sh`
- [ ] Add gitleaks false-positive allowlist template
- [ ] Test on DNSResolver and Slice-N-Dice
- [x] Ship: copy to `~/.claude/skills/pre-commit-aware-commits/`
