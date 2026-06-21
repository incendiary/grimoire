# task-decomposer

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-05

Decomposes a large multi-session task into discrete, self-contained chunk files before
context pressure builds. Each chunk contains everything a fresh Claude Code session
needs to execute it cold.

---

## What this skill does

Prevents context-window collisions by planning the handoff structure **up front**,
rather than scrambling when the context window is already full. Writes a set of
numbered task files (`.claude/tasks/`) and a run-book, so work can be paused and
resumed cleanly across sessions.

---

## When to use it

- Starting any task that will clearly span more than one Claude Code session
- Before delegating chunks to sub-agents
- When a plan file or delivery roadmap exists and needs to be sliced into executable pieces

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/task-decomposer ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#task-decomposer
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

```
/task-decomposer
Task: [paste plan, description, or bullet list of work]
```

---

## Output

```
.claude/tasks/[task-name]/
├── 00-runbook.md       ← execution order + shared context
├── 01-first-chunk.md
├── 02-second-chunk.md
└── ...
```

---

## How to execute the chunks with agents

Once the task package exists, treat each chunk as a separate sub-agent assignment.

### Pattern to follow

1. Read `00-runbook.md` first to understand ordering, shared context, and the overall done criteria.
2. Give one chunk file to one agent or one fresh Claude session.
3. Tell the agent to read only the chunk file plus the context files listed inside it.
4. Instruct the agent to stay inside the chunk boundary:
   - do not expand scope
   - do not re-plan the whole task
   - do not edit files outside the chunk’s file list unless the chunk explicitly says so
5. Ask the agent to return the exact return signal from the chunk file when done.
6. Mark the run-book chunk complete, then move to the next chunk.
7. If a chunk grows unexpectedly, stop and re-run `task-decomposer` on the remaining work.

### Prompt template for a sub-agent

```text
You are working chunk 02 of 08 for [task name].
Read `00-runbook.md` and `02-<chunk-name>.md` first.
Follow the chunk file exactly.
Only edit the files listed there.
Do not broaden scope or redesign the task.
Return the exact commit message and return signal when done.
```

### When to use `task-handoff` instead

If you are already midway through a chunk and the context window is getting tight,
use `task-handoff` to package the current session state. Use `task-decomposer`
up front, and `task-handoff` reactively.

---

## Worked example

**Task:** Add worked examples to all three 02-comms skills (executive-translate,
human-rewrite, tone-check) — a multi-file documentation task spanning one or two sessions.

**Input to task-decomposer:**
```
Task: Add worked examples to 02-comms cluster
Files: clusters/02-comms/executive-translate/README.md
       clusters/02-comms/human-rewrite/README.md
       clusters/02-comms/tone-check/README.md
Scope: No SKILL.md changes. README-only additions. One PR, one release.
```

**Output — run-book:**
```
.claude/tasks/comms-worked-examples/
├── 00-runbook.md
├── 01-executive-translate.md
├── 02-human-rewrite.md
└── 03-tone-check.md
```

**00-runbook.md:**
```markdown
# comms-worked-examples — run-book

Branch: feat/comms-worked-examples
PR target: main
VERSION bump: 1.6.7 (patch)

Execution order:
  1. 01-executive-translate.md — write 3 worked examples
  2. 02-human-rewrite.md       — write before/after for 9 rules
  3. 03-tone-check.md          — write PASS/FLAG/borderline for 4 axes

Shared context:
  - Match existing README section formatting (H2 headers, code blocks)
  - Roadmap items to tick are listed in each chunk file
  - Do not edit SKILL.md

Done criteria: CI green, PR merged, v1.6.7 tagged.
```

**01-executive-translate.md (chunk file):**
```markdown
# Chunk 1 — executive-translate worked examples

File: clusters/02-comms/executive-translate/README.md
Insert before: ## Roadmap

Add a "## Worked examples" section with 3 subsections:
  1. Finding → CISO brief (auth bypass, audience: CISO, ask: approve emergency patch)
  2. Incident → board summary (ransomware near-miss, audience: board, no ask)
  3. Risk → C-suite ask (MFA rollout, audience: CEO+CFO, ask: approve £180k)

Each subsection: raw technical input block → translated output block → "Rules applied" note.

Tick in roadmap:
  - [x] Build 3 worked examples (finding → CISO brief, incident → board summary, risk → C-suite ask)
  - [x] Add worked examples for different audience tiers (CISO, C-suite, board)

Done: section renders correctly, two roadmap items ticked.
```

**Why this decomposition works:**
- Each chunk is independently executable — a fresh session can pick up chunk 2 without
  reading chunk 1's output
- The run-book carries the shared context (branch name, PR target, VERSION) so each session
  does not need to re-derive it
- Done criteria per chunk are verifiable, not vague ("section renders correctly" not "looks good")
- Chunk files are small enough that a single session completes one without context pressure

---

## Roadmap

- [x] SKILL.md written: decomposition principles, chunk format, run-book format, gotchas
- [x] README.md written
- [x] Ship: copy to `~/.claude/skills/task-decomposer/`
- [x] Add example: grimoire Cat 5 decomposed into 6 chunks (worked example)
- [ ] Add example: subagent execution guide for running chunks one-by-one
- [ ] Add `--resume` mode: reads existing run-book, skips completed chunks
