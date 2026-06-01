# syscall-techniques

> **Cluster:** 09-odpc | **Status:** complete | **Added:** 2026-06-02

Direct syscall MASM stubs, indirect syscall via gadget jump, and HalosGate dynamic
SSN resolution for hooked ntdll functions.
Maps to ODPC Chapters 20, 21, 22.

## Roadmap

- [x] SKILL.md written: direct stubs (MASM), indirect pattern, HalosGate C implementation, SysWhispers3 tradeoffs, gotchas
- [x] Add complete MASM stub set for common Nt functions (NtAllocate, NtWrite, NtProtect, NtCreateThread)
- [x] Add SSN reference table for common Windows builds (10 21H2, 11 22H2, 11 23H2)
