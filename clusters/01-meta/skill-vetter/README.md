# skill-vetter

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-05-24

Third-party Claude Code skills can include scripts that run at session end (via Stop hooks),
access environment variables, or contain prompt-injection in their SKILL.md descriptions.
This skill provides a structured vetting process before any external skill is installed.

---

## What this skill does

Guides Claude through a four-step security review of a proposed skill:
1. Repository health check (stars, contributors, recency)
2. Script analysis (network calls, env var access, dynamic execution)
3. SKILL.md prompt-injection check (override attempts, permission claims)
4. Verdict: PASS, FLAG, or REJECT with explicit reasoning

The output is a structured finding you can save as a record of the decision.

---

## When to use it

Load `skill-vetter` whenever you are about to install a skill from:
- A GitHub URL someone shared
- The Claude Code skill registry
- A blog post or tutorial
- A colleague's repo you have not reviewed before

You do not need it for skills from **this** (`grimoire`) repo — those go through a separate
review process before they are committed here.

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/skill-vetter ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#skill-vetter
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


No hook wiring required. This is a context-load skill only.

---

## How to invoke it in a session

Open a new Claude Code session and say:

```
/skill-vetter
Vet this skill before I install it: https://github.com/example/some-skill
```

Or paste the SKILL.md contents directly and say:

```
/skill-vetter
Here is the skill I want to install: [paste SKILL.md]
```

Claude will run the four-step review and output a PASS / FLAG / REJECT verdict.

---

## Workflow

```
User pastes skill URL or content
       ↓
Claude reads the repo / files
       ↓
Repo health check → flag if low trust signals
       ↓
Script analysis → flag network calls, env vars, eval
       ↓
SKILL.md analysis → flag prompt injection patterns
       ↓
Verdict: PASS / FLAG (with conditions) / REJECT (with reason)
       ↓
User decides whether to install
```

---

## What it will NOT do

- It will not automatically install the skill. The verdict is advisory; you decide.
- It will not run scripts from the skill being vetted during the review.
- It will not flag skills from the `grimoire` repo (those are already reviewed).

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `vetting-checklist.md` as a printable record template
- [x] Add PyPI package reputation check step
- [x] Add integration note for `session-skill-extractor` (auto-flag proposed stubs for vetting)
- [ ] Test on 3 real third-party skills (requires real sessions)
- [x] Ship: copy to `~/.claude/skills/skill-vetter/`
