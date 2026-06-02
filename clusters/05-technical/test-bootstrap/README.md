# test-bootstrap

> **Cluster:** 05-technical | **Status:** complete | **Added:** 2026-06-02

Adds a unit test layer to a project that has none, or fills coverage gaps in one that has
partial tests. Detects the language and existing framework, generates failing stubs first,
implements real assertions, and wires the runner into CI.

Covers: Python (pytest), C# (xUnit), TypeScript (Vitest), Go (stdlib testing), Bash (bats-core).

---

## What this skill does

Replaces "can you write some tests?" with a structured audit → install → stub → implement →
CI-wire workflow. Detects what's already present before recommending anything. Enforces
red-first (failing stub proves the harness works before assertions are written).

---

## When to use it

- A project has no tests at all
- A new module or class has been added with no coverage
- A PR touches logic and the diff shows no test changes
- Setting up a new project and wanting the test layer configured from the start

---

## Installation

```bash
cp -r ~/Claude/skills/grimoire/clusters/05-technical/test-bootstrap ~/.claude/skills/
```

---

## Invocation

```
/test-bootstrap
Language: Python
Target: src/mypackage/parser.py — the parse_config() function
Framework: none yet
```

```
/test-bootstrap
Language: C#
Project: Slice-N-Dice
Target: the SliceService class
Framework: xUnit already present
```

---

## Workflow

```
Audit (find existing tests / framework)
        ↓
Choose framework (or confirm existing)
        ↓
Install if missing (pyproject.toml / .csproj / package.json)
        ↓
Generate failing stubs
        ↓
Run → confirm red for the right reason
        ↓
Write real assertions (happy path + boundary + error)
        ↓
Run → confirm green
        ↓
Wire into CI
        ↓
Report coverage summary
```

---

## Roadmap

- [x] SKILL.md written: framework table, install snippets, stub templates for all 5 languages, case categories, CI wiring, gotchas
- [x] README.md written
- [x] Ship: copy to `~/.claude/skills/test-bootstrap/`
