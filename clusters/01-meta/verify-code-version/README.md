# verify-code-version

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-05-24

Prevents diagnosing or evaluating behaviour from stale code after a pull or branch
switch. Extracted after output was incorrectly evaluated against a pre-v1.10.0 version
of DNSResolver despite a pull having been done — the running interpreter had cached
the old modules.

---

## What this skill does

Enforces a version-check step after any `git pull`, `git checkout`, or branch switch.
The version check compares the running code against HEAD before any output is evaluated
or any debugging begins.

Also catches the `.pyc` cache trap: pulling updated source does not invalidate Python's
bytecode cache or a running interpreter's module cache.

---

## When to use it

Load this skill for sessions that involve:
- Pulling changes mid-session and then running the updated tool
- Switching between branches with meaningfully different behaviour
- Evaluating tool output where the version affects interpretation
- Debugging "unexpected" behaviour that might actually be correct behaviour from old code

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/verify-code-version ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#verify-code-version
```

### MCP client

This is an `action` type skill — it's available as a callable tool via the grimoire
MCP server after running `bash install-vscode.sh`. Invoked automatically when relevant.


---

## How to invoke it in a session

```
/verify-code-version
Version location: dns_resolver/__version__.py
Expected version after pull: v1.10.0
```

---

## Version check quick reference

```bash
# Python __version__ string
python3 -c "import dns_resolver; print(dns_resolver.__version__)"

# Script banner check
python3 tool.py --version

# Git vs pyproject.toml
git describe --tags && grep '^version' pyproject.toml

# Verify installed package matches source
pip show <package> | grep Version
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `verify_version.sh`
- [x] Add `.pyc` cache-clearing step to the post-pull checklist
- [ ] Test on DNSResolver and Slice-N-Dice sessions
- [x] Ship: copy to `~/.claude/skills/verify-code-version/`
