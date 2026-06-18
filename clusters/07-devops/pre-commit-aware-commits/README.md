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

## Gitleaks false-positive allowlist template

When gitleaks flags a value that is not a secret (test data, example strings, public
keys in documentation), add an allow-rule to `.gitleaks.toml` rather than suppressing
the entire hook or using `--no-verify`.

**Create or extend `.gitleaks.toml` in the repo root:**

```toml
# .gitleaks.toml
# Allow specific false positives by regex or by commit SHA.
# See: https://github.com/gitleaks/gitleaks#configuration

title = "gitleaks config"

[extend]
# Optionally extend the default ruleset:
# useDefault = true

[[rules]]
# Custom rule example — flag AWS key pattern (supplement to defaults)
id = "aws-access-key-custom"
description = "AWS Access Key"
regex = '''AKIA[0-9A-Z]{16}'''
tags = ["aws", "credentials"]

[[allowlist]]
# Allow a specific commit by SHA (use for historical commits you cannot rewrite)
# commits = ["abc1234def5678..."]

[[allowlist]]
# Allow a specific file from all rule scanning
# This is for files that legitimately contain example/test key-shaped values
description = "Allow test fixture files that contain example key patterns"
paths = [
  '''tests/fixtures/.*''',
  '''docs/examples/.*''',
]

[[allowlist]]
# Allow a specific regex pattern globally
# Use sparingly — prefer path-scoped allows over global pattern allows
description = "Allow example key pattern used in documentation"
regexes = [
  '''EXAMPLE_KEY_[A-Z0-9]{16}''',
  '''sk_test_[a-zA-Z0-9]{24}''',     # Stripe test key prefix — not a live secret  # pragma: allowlist secret
]

[[allowlist]]
# Allow a specific line by stopword
# Any line containing this exact string is skipped
description = "Allow placeholder values in config templates"
stopwords = [
  "YOUR_API_KEY_HERE",
  "REPLACE_WITH_YOUR_KEY",
  "<YOUR_TOKEN>",
]
```

**When to use each allow type:**

| Situation | Allow type |
|-----------|------------|
| Test fixture file with fake key patterns | `paths` allow |
| A specific published commit you cannot rewrite | `commits` allow |
| A consistent placeholder string used across the codebase | `stopwords` allow |
| A structured fake key format used in documentation | `regexes` allow |

**Inline suppression (single line, last resort):**
```python
api_key = "EXAMPLE_ONLY_NOT_REAL"  # gitleaks:allow  # pragma: allowlist secret
```
Add `# gitleaks:allow` at the end of the line. Use only when the above `.gitleaks.toml`
approaches do not apply cleanly.

**Never use `--no-verify` to bypass gitleaks.** If gitleaks fires on a legitimate false
positive, the correct fix is an allow rule — not skipping the hook. A skipped hook
produces no protection for the rest of the commit.

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `pre_commit_check.sh`
- [x] Add gitleaks false-positive allowlist template
- [ ] Test on DNSResolver and Slice-N-Dice
- [x] Ship: copy to `~/.claude/skills/pre-commit-aware-commits/`
