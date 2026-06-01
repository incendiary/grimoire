# shellcode-dev-conventions

> **Cluster:** 08-offsec | **Status:** complete | **Added:** 2026-05-24

Enforces position-independent code conventions for raw shellcode and reflective
stubs: no globals, no absolute addresses, delta-offset self-location, PEB walk for
module resolution, hash-based API lookup, null-byte audit, and size discipline.

---

## What this skill does

Pre-loads the full set of PIC constraints before writing any shellcode or reflective
DLL entry stub. Catches the common mistakes (global variables, string literals in
`.rdata`, CRT linkage, null bytes from `mov eax, 0`) before they produce silent
crashes at injection time.

---

## When to use it

- Writing raw shellcode (staged or stageless)
- Writing a reflective DLL entry stub
- Writing a ROP-delivered payload
- Reviewing existing shellcode for PIC correctness

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/08-offsec/shellcode-dev-conventions ~/.claude/skills/
```

---

## Invocation

Load explicitly at the start of a shellcode session:

```
/shellcode-dev-conventions
Target: x64, injected thread context, no size constraint, no bad-char restrictions
```

Or implicitly — Claude recognises when shellcode or reflective DLL code is being
written and applies the conventions.

---

## Workflow

```
Declare target arch + execution context + size/bad-char constraints
        ↓
Verify no globals, no .rdata strings, no CRT linkage
        ↓
Implement delta-offset or PEB-walk for self-location
        ↓
Implement PEB module walk (index 1 = ntdll, index 2 = kernel32)
        ↓
Implement hash-based EAT walk (see api-hashing-conventions)
        ↓
Assemble and audit for null bytes / bad characters
        ↓
Measure size against delivery constraint
```

---

## What it won't do

- Generate shellcode from scratch — it enforces conventions while you write
- Handle encoding/encryption — those are separate concerns applied post-assembly
- Replace architecture-specific documentation for exotic targets (ARM, RISC-V)

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Write `null-byte-audit.sh`
- [ ] Write `size-report.sh`
- [ ] Add x86 `fs:[0x30]` PEB walk variant with concrete offsets
- [ ] Add worked example: minimal `MessageBoxA` shellcode (x64) end-to-end
