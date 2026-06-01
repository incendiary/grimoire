# odpc-lab-setup

> **Status:** COMPLETE
> **Cluster:** 09-odpc
> **Maps to:** All chapters (lab environment reference)

## Description
Environment reference for the White Knight Labs ODPC AWS lab. Covers the lab topology,
Visual Studio project configuration for each technique type, x64dbg workflows for
analysing hooks and verifying stubs, and the EDR configuration profile for each
defensive product present in the lab.

Invoke when: starting an ODPC lab session, setting up a new VS project for a chapter,
or debugging why a payload is being caught.

## Lab topology

```
AWS Lab (isolated VPC)
├── Windows Dev Box
│   ├── Visual Studio 2022
│   ├── x64dbg / x32dbg
│   ├── Process Hacker / Process Monitor
│   ├── WinDbg (kernel debugging)
│   └── Python 3.x (shellcode tooling)
├── Cobalt Strike Team Server (Linux)
├── Havoc C2 (Linux)
└── Target Machines (Windows)
    ├── Machine A — CrowdStrike Falcon
    ├── Machine B — Sophos Intercept X
    ├── Machine C — Bitdefender GravityZone
    ├── Machine D — Elastic Security
    ├── Machine E — Palo Alto Cortex XDR
    └── Machine F — Microsoft Defender for Endpoint (MDE)
```

## Visual Studio project templates

### Shellcode loader (C/C++)
- Project type: Windows Desktop Application (empty)
- Configuration: Release / x64
- Runtime library: `/MT` (static, no DLL dependency)
- Disable: SDL checks, security cookies (`/GS-`), ASLR (for debugging)
- Assembler: MASM (for syscall stubs) — enable via Build → Custom Build Tool or `.asm` files with `/FAs`
- Key pragmas: `#pragma comment(lib, "ntdll.lib")`

### BOF (C, clang-cl)
- See `bof-dev-conventions` skill for full configuration
- clang-cl: `clang-cl /c /GS- /MT /Ox /DWIN32_LEAN_AND_MEAN bof.c`
- No entry point; exported function named per Cobalt Strike convention (`go`)

### C# implant (.NET)
- Project type: Class Library (.NET Framework 4.x) or Console App
- For D/Invoke: add CsWhispers NuGet or inline generated stubs
- Platform: x64
- Disable: "Prefer 32-bit" option

## x64dbg workflows

### Inspecting ntdll hooks
```
1. Attach to a process (or launch with x64dbg)
2. Go to Symbols → ntdll.dll → find target function (e.g., NtAllocateVirtualMemory)
3. CPU view — inspect first bytes:
   - CLEAN:  4C 8B D1 B8 <SSN> 0F 05 C3  (mov r10,rcx; mov eax,<ssn>; syscall; ret)
   - HOOKED: E9 XX XX XX XX               (jmp to EDR hook trampoline)
4. For hooked functions: jump destination will be in a non-ntdll module range
```

### Verifying syscall stubs
```
1. Set breakpoint on your stub's syscall instruction
2. Check eax = expected SSN (compare with clean ntdll or known SSN list)
3. Verify r10 = rcx (calling convention — should be set before syscall)
4. Step through: syscall should transition to kernel (instruction pointer jumps to KiSystemCall64)
```

### Finding SSN from a hooked function (HalosGate)
```
1. Locate the hooked function in ntdll memory
2. Scan forward and backward for adjacent unhooked stubs
3. Unhooked stub at offset +N has SSN = target_SSN ± N
4. Confirm by checking the `mov eax, <value>` at offset +4 of clean stubs
```

## EDR profiles: what each product watches

| Product | Primary detection vectors | Syscall response | Weakest against |
|---------|--------------------------|-----------------|-----------------|
| CrowdStrike Falcon | Kernel callbacks, memory scanning, ML model | Inline hooks removed; kernel-side telemetry | Indirect syscalls + ETW patch |
| Sophos Intercept X | User-land hooks, CryptoGuard, AMSI | Deep user-land hooks in ntdll | Direct syscalls bypass hooks |
| Bitdefender | User-land hooks, network IOCs, behaviour rules | Aggressive ntdll hooking | Indirect syscalls |
| Elastic Security | YARA rules, ML, Auditbeat | Limited hooking; signature-heavy | Novel encodings, uncommon callbacks |
| Palo Alto Cortex XDR | Kernel callbacks, ML scoring, WMI | Kernel-side telemetry + some hooks | Stack spoofing, sleep masking |
| MDE | AMSI, ETW, kernel callbacks, cloud analysis | ETW-heavy; correlates across events | ETW patching, cloud analysis latency |

## Gotchas

- **`/MT` vs `/MD`:** Static runtime (`/MT`) avoids MSVCRT dependency on target. Always use for loaders.
- **Debug vs Release builds:** Debug builds contain symbol info, assert guards, and unoptimised code that triggers more heuristics. Always test Release builds.
- **ASLR in dev:** Disable ASLR (`/DYNAMICBASE:NO`) on dev box only to get reproducible addresses in x64dbg. Re-enable for final payload.
- **EDR update cadence:** CrowdStrike and MDE receive sensor updates frequently. A bypass working Monday may be patched by Friday. Re-test after lab restarts.
- **Lab connectivity:** CS and Havoc listeners must be reachable from target machines. Check security groups if callbacks fail.
