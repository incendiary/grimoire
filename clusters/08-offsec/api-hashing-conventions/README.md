# api-hashing-conventions

> **Cluster:** 08-offsec | **Status:** complete | **Added:** 2026-05-24

Standardised hash-based API resolution: algorithm selection table (ROR13 / DJB2 /
FNV-1a), compile-time hash macros and constexprs, PEB/EAT walk with forwarded export
handling, and collision verification before shipping.

---

## What this skill does

Pre-loads the full resolution pipeline before writing any shellcode or BOF that
must call Windows APIs without importing name strings. Catches the common mistakes:
mixing algorithms across a project, incorrect `AddressOfNameOrdinals` indexing,
missed forwarded exports, and hash collisions in the target function set.

---

## When to use it

- Writing API resolution in shellcode (PIC — no imports table)
- Writing a BOF that needs APIs not available via `DECLAREIMPORT`
- Reviewing existing hash-resolution code for correctness
- Choosing an algorithm for a new project

---

## Installation

### Claude Code

```bash
cp -r clusters/08-offsec/api-hashing-conventions ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#api-hashing-conventions
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

```
/api-hashing-conventions
Algorithm: DJB2, target arch: x64
APIs needed: LoadLibraryA, VirtualAlloc, VirtualProtect, CreateThread
```

---

## Workflow

```
Choose algorithm (document it)
        ↓
Implement compile-time hash macro / constexpr
        ↓
PEB walk → module base (ntdll @ index 1, kernel32 @ index 2)
        ↓
EAT walk → names[] hash match → ordinals[i] → funcs[ordinals[i]]
        ↓
Forwarded export check (RVA within export directory → resolve forward)
        ↓
Collision check against full DLL export list
```

---

## What it won't do

- Implement the PEB walk inline — see `shellcode-dev-conventions` for the full
  x86/x64 PEB structure and offsets
- Handle ordinal-only exports — those require a separate ordinal lookup path

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `hash-api.py` (multi-algorithm hash printer)
- [x] Write `collision-check.py` (validates target function set against DLL export list)
- [x] Add x86 variant with `fs:[0x30]` PEB offset
- [ ] Add worked end-to-end example pairing with `shellcode-dev-conventions`
