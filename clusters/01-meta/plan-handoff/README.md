# plan-handoff

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-05

Packages the current session's state into a self-contained handoff document when
context pressure is high mid-task. The fresh session that picks it up needs no
knowledge of the current session's history.

---

## What this skill does

Reactive context management: when the current session is filling up, captures decisions
made, work accomplished, and the next discrete chunk into a single portable document.
The document lives on disk and survives `/compact`, so the parent session can reclaim
context without losing state.

---

## When to use it

- Context window is visibly large and the task isn't finished
- About to start a phase requiring many new file reads
- Natural pause point (PR merged, chunk complete)
- Switching between unrelated areas of the codebase

---

## Invocation

```
/plan-handoff
```

```
/plan-handoff
Next chunk: write the ios-signing scripts
Compact after: yes
```

---

## Output

```
.claude/tasks/handoff-YYYY-MM-DD-[slug].md
```

Load in a fresh session:
```
/plan-handoff load .claude/tasks/handoff-2026-06-05-ios-scripts.md
```

---

## Worked example

**Scenario:** Mid-session, halfway through adding worked examples to the 02-comms cluster.
write-exec is done; write-human and write-tone remain. Context window is at ~75%.

**Trigger:**
```
/plan-handoff
Next chunk: write-human + write-tone README worked examples
Compact after: yes
```

**Handoff document produced** (`.claude/tasks/handoff-2026-06-18-comms-examples.md`):

```markdown
# Handoff — comms-worked-examples (2026-06-18)

## State at handoff

Branch: feat/comms-worked-examples (on origin, not yet pushed for PR)
Last commit: none yet — changes staged but not committed

## Work completed this session

- clusters/02-comms/write-exec/README.md — "Worked examples" section added.
  3 examples: finding→CISO brief, incident→board summary, risk→C-suite ask.
  Roadmap items ticked: "Build 3 worked examples", "Add worked examples for different tiers".

## Decisions made

- Worked examples go in a new H2 section inserted before ## Roadmap in each file.
- Each example uses: **Audience**, **Ask**, raw input block, translated output blockquote,
  "Rules applied" annotation. Match this format in the remaining files.
- No SKILL.md changes in this batch.

## Work remaining

1. clusters/02-comms/write-human/README.md
   Add "## Style rules — before/after": one before/after pair for each of the 9 rules.
   Tick: "Build worked before/after examples for each style rule"

2. clusters/02-comms/write-tone/README.md
   Add "## Worked examples — PASS, FLAG, borderline per axis": one set per axis
   (blame, authority, vagueness, softness). Include annotation block output format.
   Tick: "Add worked examples of PASS vs FLAG vs borderline for each axis"

3. Bump VERSION to 1.6.7, update CHANGELOG.md, commit, push, open PR.

## Load prompt for fresh session

Load the grimoire repo at /Users/adz/Projects/grimoires/grimoire.
Branch feat/comms-worked-examples is checked out. write-exec README is done.
Continue with write-human and write-tone per the decisions above, then commit and PR.
```

**Fresh session load:**
```
/plan-handoff load .claude/tasks/handoff-2026-06-18-comms-examples.md
```

The fresh session reads the document, checks out the branch, confirms the
write-exec file is as described, then proceeds to write-human.
No re-reading of the original brief or the session history is needed.

---

## Roadmap

- [x] SKILL.md written: workflow, format template, load protocol, gotchas
- [x] README.md written
- [x] Ship: copy to `~/.claude/skills/plan-handoff/`
- [x] Add worked example: mid-session handoff from a real grimoire Cat 5 chunk
- [ ] Add `--auto` mode: triggered automatically when context exceeds a threshold
