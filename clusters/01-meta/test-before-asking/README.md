# test-before-asking

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-05-24

Enforces a bias toward action and evidence over consultation. When Claude faces a choice
between two approaches, it should try the most likely one and report back — not present
a menu and wait. Extracted after the same consultation pattern appeared twice in a session
where the user had to say "just try it and tell me what happened."

---

## What this skill does

Establishes a standing rule for the session: if a question has a testable answer, test it.
Present decisions with evidence, not as binary choices with no information to guide them.

**Before this skill:**
> "Would you like me to use the existing virtual environment or create a new one?"

**After this skill:**
> "The existing venv was missing scipy. I've installed it and continued."

Carve-outs exist: destructive actions, expensive operations, and genuine preference
questions where there is no objectively better answer still require explicit confirmation.

---

## When to use it

Load this skill for any session where you expect Claude to be making repeated small
decisions — file operations, configuration choices, tool selection, dependency resolution.

It is most valuable in longer sessions where consultation overhead adds up. Not needed
for short one-shot sessions.

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/test-before-asking ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#test-before-asking
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## How to invoke it in a session

```
/test-before-asking
```

Or just mention it at session start:

```
Load test-before-asking. Try things before asking me to decide.
```

---

## Decision threshold

| Situation | Correct behaviour |
|-----------|------------------|
| "Should I use X or Y?" and both are testable | Test X, report, proceed or narrow |
| Destructive action (rm -rf, force push, wipe) | Always ask first |
| Expensive operation (long CI, API call) | Ask first |
| Genuine preference (naming, style) | Ask — no test resolves this |
| "I'm not sure if this will work" | Try it, report what happened |

---

## Concrete ask vs test examples — by session type

### Python / dependency sessions

| Situation | Without this skill (asks) | With this skill (tests) |
|-----------|--------------------------|------------------------|
| venv missing a package | "Should I use the existing venv or create a new one?" | Checks with `pip show scipy`; installs if missing; continues |
| Two compatible libraries exist | "Would you like requests or httpx?" | Uses `requests` (already installed); reports choice |
| Test fails with ImportError | "Do you want me to install the missing package?" | Installs it; re-runs the test; reports pass/fail |

### Shell / file operation sessions

| Situation | Without this skill (asks) | With this skill (tests) |
|-----------|--------------------------|------------------------|
| Output file already exists | "The file exists — should I overwrite it?" | Checks if the content is already correct; overwrites only if different |
| Multiple Python versions on PATH | "Which Python should I use?" | Runs `python --version` and `python3 --version`; picks the higher one |
| `.env` file absent | "Should I create the .env from the example?" | Copies `.env.example` → `.env`; notes it and continues |

### Refactor / code editing sessions

| Situation | Without this skill (asks) | With this skill (tests) |
|-----------|--------------------------|------------------------|
| Function name ambiguity | "Did you mean `process_data` or `process_raw_data`?" | Greps both; picks the one that matches context; reports |
| Two code locations for the same fix | "Should I fix it in `utils.py` or `helpers.py`?" | Reads both; applies fix to the one with the actual usage |
| Test suite is slow | "Do you want me to run all tests or just the affected module?" | Runs the affected module first; runs full suite if it passes |

### Decisions that still require asking (not testable):

- Commit message wording when content is ambiguous
- Whether to squash-merge vs merge commit (team convention, not a test)
- Naming a new function when no existing convention is clear
- Whether to delete a file with no callers (might be intentionally unused)

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Add concrete examples of ask vs test for common session types
- [ ] Test across 5 sessions to confirm the rule lands correctly
- [x] Ship: copy to `~/.claude/skills/test-before-asking/`
