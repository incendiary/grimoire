# bof-dev-conventions

> **Cluster:** 08-offsec | **Status:** complete | **Added:** 2026-05-24

Beacon Object File development conventions: `beacon.h`-only API, no static globals,
`datap` argument parsing, handle/heap cleanup on all code paths, and clang-cl / MSVC
compilation flags that produce a loadable COFF without CRT dependencies.

---

## What this skill does

Pre-loads the full set of BOF constraints before writing any BOF code. Catches the
common crashes: CRT functions, static globals, missing `/GS-`, wrong argument
parsing, and handles that leak into Beacon's long-running process memory.

---

## When to use it

- Writing a new BOF for Cobalt Strike or a compatible C2 framework
- Reviewing a BOF for correctness before deployment
- Debugging a BOF that crashes Beacon on execution

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/08-offsec/bof-dev-conventions ~/.claude/skills/
```

---

## Invocation

```
/bof-dev-conventions
Framework: Cobalt Strike, inline execution
Goal: process enumeration BOF, args: target PID (int), output mode (short)
```

---

## Workflow

```
Include beacon.h only (no CRT)
        ↓
Declare void go(char* args, int len)
        ↓
BeaconDataParse → extract args in pack order
        ↓
DECLAREIMPORT for every WinAPI call
        ↓
Implement logic — all state on stack or heap (no globals)
        ↓
cleanup: label — CloseHandle + HeapFree on all paths
        ↓
BeaconPrintf(CALLBACK_OUTPUT, ...) for all output
        ↓
Compile: clang-cl /c /GS- /Os → .o COFF
        ↓
inline-execute in Beacon
```

---

## What it won't do

- Write the aggressor script — argument packing order is documented but not generated
- Cover managed (.NET) BOF-style assemblies (use `inline-execute-assembly`)
- Handle Havoc-specific demon module API differences (separate roadmap item)

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `bof-build.sh` (clang-cl wrapper with correct flags)
- [x] Write `bof-validate.sh` (static check for globals, missing cleanup)
- [ ] Add Havoc demon module API comparison
- [ ] Add fork-and-run vs inline guidance with OPSEC notes
- [ ] Add Makefile template
