# pe-binary-analysis

> **Cluster:** 05-technical | **Status:** complete | **Added:** 2026-05-24

Enforces a strict convention for PE structure parsing: no WinAPI abstractions,
no library wrappers, direct struct access only. Applied during code review and
development for any Windows binary introspection work.

---

## What this skill does

Loads the convention set for PE parsing work and enforces it on all code written
or reviewed in the session:

- `ImageNtHeader()` → direct cast via `e_lfanew`
- `ImageRvaToVa()` → explicit arithmetic shown inline
- `ImageDirectoryEntryToData()` → direct `DataDirectory[]` indexing
- All RVA/file-offset arithmetic explicitly annotated
- x86 vs x64 header distinction always resolved via Magic field check
- Struct fields always referenced by fully qualified path in comments

---

## When to use it

- Writing PE parsing code in C or C++
- Reviewing PE parsing code for correctness or convention compliance
- Implementing syscall hook detection
- Analysing import tables, export tables, or relocation data
- Debugging PE structure offsets or section alignment issues
- Any session where PE binary introspection is the primary task

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/05-technical/pe-binary-analysis ~/.claude/skills/
```

No hook wiring required. Load at the start of any PE-related coding session.

---

## How to invoke it in a session

Simply load the skill and proceed:

```
/pe-binary-analysis
I'm writing a PE loader and need to walk the import table.
```

Or during a review:

```
/pe-binary-analysis
Review this PE parsing function for convention compliance: [paste code]
```

The conventions are applied for the rest of the session without needing to re-state them.

---

## Workflow

```
Skill loaded → conventions active for session
        ↓
Code written or pasted for review
        ↓
Check: any WinAPI PE helpers present?
  Yes → replace with direct struct access, show formula
  No  → proceed
        ↓
Check: RVA/file offset arithmetic explicitly annotated?
  No  → add inline comment showing formula
        ↓
Check: x86 vs x64 — Magic field consulted?
  No  → add check before struct access
        ↓
Output: convention-compliant code with inline documentation
```

---

## Convention reference

| Forbidden | Replacement |
|-----------|-------------|
| `ImageNtHeader(base)` | `(IMAGE_NT_HEADERS64*)(base + dos->e_lfanew)` |
| `ImageRvaToVa(nth, base, rva, ...)` | `(PVOID)((ULONG_PTR)base + rva)` with explicit comment |
| `ImageDirectoryEntryToData(...)` | `nth->OptionalHeader.DataDirectory[entry]` directly |
| `ImageEnumerateCertificates(...)` | Parse security directory entry manually |

---

## Common errors this prevents

| Error | How the skill prevents it |
|-------|--------------------------|
| RVA treated as file offset | Forces explicit annotation and conversion formula |
| x86/x64 struct mismatch | Requires Magic field check before any struct cast |
| On-disk vs in-memory confusion | Requires explicit target statement before analysis |
| Silent WinAPI dependency | Replaces all WinAPI helpers with direct access |

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Add syscall hook detection byte-pattern reference (clean stub patterns for common syscalls)
- [ ] Add worked example: full import table walk without WinAPI
- [ ] Add worked example: section table traversal with RVA/file-offset conversion
- [ ] Test on 2 real PE parsing sessions
- [x] Ship: copy to `~/.claude/skills/pe-binary-analysis/`
