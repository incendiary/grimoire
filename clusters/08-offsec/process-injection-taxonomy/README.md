# process-injection-taxonomy

> **Cluster:** 08-offsec | **Status:** complete | **Added:** 2026-05-24

Decision guide for process injection technique selection. Indexed by EDR detection
surface, required privileges, reliability, and target process selection criteria.
Includes syscall strategy mapping and a one-line rationale template.

---

## What this skill does

Prevents unstructured technique selection ("try classic injection, it didn't work,
try hollowing...") by providing a structured decision path: target characteristics
→ EDR tier → technique → syscall strategy → rationale recorded before implementation.

---

## When to use it

- Choosing a technique for a new payload
- Reviewing existing injection code to assess EDR exposure
- Explaining the stealth/reliability tradeoff to a peer or in a report
- Diagnosing why a technique was detected (map detection back to the visibility column)

---

## Installation

### Claude Code

```bash
cp -r clusters/08-offsec/process-injection-taxonomy ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#process-injection-taxonomy
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

```
/process-injection-taxonomy
Target: svchost.exe, same-session user, EDR: CrowdStrike Falcon (full stack)
Goal: execute x64 shellcode, avoid CreateRemoteThread
```

---

## Workflow

```
Characterise target (arch, integrity, network profile, PPL status)
        ↓
Assess EDR tier (user-mode hooks / ETW / kernel callbacks / full stack)
        ↓
Consult technique table → select lowest-visibility reliable match
        ↓
Choose syscall strategy (none / direct / indirect)
        ↓
Record one-line rationale before implementing
        ↓
Implement → edr-test-loop to validate assumption
```

---

## What it won't do

- Implement any technique — it selects and documents, not codes
- Cover Linux or macOS injection (Windows-specific)
- Account for ELAM or hypervisor-based security products beyond general guidance

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Add Cobalt Strike-specific guidance (BOF vs post-ex DLL vs fork-and-run)
- [ ] Add table row for thread pool injection (TpAllocWork)
- [ ] Add table row for kernel-mode techniques (driver-based)
- [ ] Link edr-test-loop workflow for validation phase
