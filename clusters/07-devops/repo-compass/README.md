# repo-compass

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-06-01

Session-start orientation for any GitHub project. Combines platform state (PRs,
issues, CI, releases) with README roadmap state and calls out discrepancies between
the two — specifically the common failure mode of a clean GitHub dashboard masking
unchecked README roadmap items.

---

## What this skill does

Runs a structured checklist of `gh` CLI commands, reads all nested READMEs, and
cross-checks each unchecked item against the actual codebase and commit history.
Produces a "true state" summary that distinguishes:

- **README lag** — item is actually done, README wasn't updated
- **Confirmed outstanding** — genuinely unimplemented
- **Ambiguous** — partial implementation, needs human decision

Prevents the failure mode of reporting a project as "all tidy" when the README
roadmap disagrees.

---

## When to use it

Load at the start of any session where you need to know what's actually outstanding:
- "What's left on this repo?"
- "Pick up where we left off"
- "Review the roadmap"
- "Is this project tidy?"
- Before starting a delivery session (pairs with `project-delivery-workflow`)

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/repo-compass ~/.claude/skills/
```

No hook wiring required.

---

## How to invoke it in a session

```
/repo-compass
Repo: incendiary/my-project
```

Or implicitly:

```
What's still outstanding on this repo? Give me the full picture.
```

---

## Example output

```
=== repo-compass: my-project ===

GitHub platform state:
  Open PRs:       0
  Open issues:    0
  CI:             all green (last run: 2h ago)
  Latest release: v0.3.0 — Latest: yes
  Stale branches: none

README roadmap state:
  Unchecked items found: 3 (clusters/07-devops/repo-pub-prep/README.md)

Cross-check findings:
  [ ] Add audit_history.sh — confirmed outstanding (no commit, no PR found)
  [ ] Test end-to-end on one new repo — confirmed outstanding
  [ ] Document new gotchas from real usage — deferred (needs real usage)

True state:
  Outstanding work:    2 confirmed items (1 deferred)
  README sync needed:  0
  Discrepancies:       0

Recommendation: 2 items to action. Proceed with project-delivery-workflow.
```

---

## Relationship to other skills

```
repo-compass             (where are we?)
        ↓
project-delivery-workflow  (execute outstanding items)
        ↓
roadmap-sync             (keep READMEs ticked after each merge)
        ↓
github-release-workflow  (tag and release when done)
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Add `repo-compass.sh` — runs all `gh` commands in sequence and outputs the summary
- [ ] Test on 3 repos with varying states (tidy, lagged, genuinely outstanding)
- [x] Ship: copy to `~/.claude/skills/repo-compass/`
