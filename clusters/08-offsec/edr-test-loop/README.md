# edr-test-loop

> **Cluster:** 08-offsec | **Status:** complete | **Added:** 2026-05-24

Structured 5-step loop for iterating payloads against EDR: baseline → detect →
identify signal → form single hypothesis → change → retest. Enforces iteration
logging to prevent repeated cycles of confusion across sessions.

---

## What this skill does

Replaces unstructured "change things until it stops alerting" with a hypothesis-driven
loop. Each iteration records the detection signal, the hypothesis, the single change
made, and the result. Static and dynamic detections have separate fix checklists.

---

## When to use it

- Testing a new payload against a lab EDR
- Diagnosing a detection that fired during an engagement (post-mortem)
- Iterating on sleep obfuscation or syscall strategy
- Preparing a payload for a specific EDR product prior to deployment

---

## Installation

### Claude Code

```bash
cp -r clusters/08-offsec/edr-test-loop ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#edr-test-loop
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

```
/edr-test-loop
EDR: CrowdStrike Falcon 7.14, user-mode hooks + ETW
Detection: CreateRemoteThread alert on svchost.exe injection
```

---

## Workflow

```
Clean VM snapshot
        ↓
Run payload → capture full detection event
        ↓
Identify signal (static string / YARA / API hook / ETW / memory scan)
        ↓
Form one hypothesis → name the change
        ↓
Apply single change → rebuild
        ↓
Revert to snapshot → retest
        ↓
Append to run log
        ↓
Repeat until no detection → test sleep/memory-at-rest separately
```

---

## AMSI bypass sub-loop

AMSI (Antimalware Scan Interface) is relevant when the payload is delivered via
a host that invokes the AMSI scan path: PowerShell, .NET CLR, WScript, CScript,
or any application that calls `AmsiScanBuffer` / `AmsiScanString`.

**Note:** AMSI bypass techniques require lab validation against the specific EDR and
Windows version in scope. The patterns below are documented for reference — test each
against your target configuration before engagement use.

```
AMSI bypass sub-loop:

Step 1 — Confirm AMSI is the detection surface
□ Detection fires on script execution or .NET assembly load, not on file drop
□ Confirmed by: disabling AMSI with a known bypass in the lab → payload runs cleanly
□ If detection persists after AMSI disable → different signal (move to main loop)

Step 2 — Identify which bypass fits the delivery method
| Delivery             | Bypass category                          |
|----------------------|------------------------------------------|
| PowerShell           | Patch AmsiScanBuffer in amsi.dll (in-process) |
| .NET (Assembly.Load) | Patch AmsiScanBuffer in the CLR process  |
| WScript / CScript    | COM-based scan path — in-memory obfuscation |

Step 3 — AmsiScanBuffer patch (in-process, PowerShell / .NET)
□ Locate amsi.dll base in the target process (GetModuleHandle or PEB walk)
□ Resolve AmsiScanBuffer export via EAT walk
□ Change page protection to PAGE_READWRITE (VirtualProtect)
□ Write patch bytes at function start:
    x64: B8 57 00 07 80 C3  ; mov eax, AMSI_RESULT_CLEAN; ret
    x86: B8 57 00 07 80 C2 18 00  ; mov eax, AMSI_RESULT_CLEAN; ret 0x18
□ Restore original page protection
□ Verify: re-run payload → confirm AMSI_RESULT_CLEAN (0x80070057) returned
□ Log iteration entry (run-log.sh)

Step 4 — Validate that the EDR does not detect the patch itself
□ Some EDRs monitor writes to amsi.dll image pages (kernel callback on VirtualProtect)
□ If the patch is detected: consider patching AmsiOpenSession to return error instead
  (less-monitored code path) or deliver via a different method that bypasses AMSI
  without patching (e.g. reflective load without touching the CLR scan path)

Step 5 — Log the result and move to main edr-test-loop
□ If AMSI bypassed and no EDR alert → continue to runtime/injection testing
□ If EDR catches the patch → treat the patch attempt itself as a detection signal
  and enter a new hypothesis iteration
```

---

## ETW patching — considerations and risk notes

ETW (Event Tracing for Windows) generates telemetry consumed by EDRs via the
`EtwEventWrite` call in `ntdll.dll`. Patching it is a technique but is itself
a detectable action on several EDRs.

**Note:** ETW patch techniques require lab validation. Patch detection varies by EDR
product, version, and whether kernel callbacks are monitoring ntdll write operations.

```
ETW surface map:
┌──────────────────────────────────────────┐
│ User-mode API call (e.g. NtCreateThread) │
│           ↓                              │
│ EDR hook in ntdll → EtwEventWrite called │
│           ↓                              │
│ Kernel: ETW provider session receives    │
│         the event → SIEM / EDR console  │
└──────────────────────────────────────────┘

Patch approach — EtwEventWrite in ntdll (in-process):
□ Locate ntdll base (PEB walk, index 1)
□ Resolve EtwEventWrite via EAT walk
□ VirtualProtect to PAGE_READWRITE
□ Write return stub at function start:
    x64: C3       ; ret (returns STATUS_SUCCESS = 0 by default)
    x86: C2 14 00 ; ret 0x14 (clean up 5 DWORD args on stack)
□ VirtualProtect back to PAGE_EXECUTE_READ
□ Verify: run a known ETW-telemetered API call → confirm event does not appear
  in the EDR console or Sysmon

Risk notes (before using this technique):
□ Patching ntdll IMAGE pages is visible to EDRs via kernel PatchGuard callbacks
  (on some EDR products, a write to a code page in a system DLL fires immediately)
□ The patch affects all ETW events from the process — including events that
  legitimate software in the same process uses. Do not patch in a target process
  running third-party code that depends on ETW health.
□ Some EDRs monitor EtwEventWrite at the kernel level (not user-mode hook) — the
  patch affects user-mode emission only; kernel ETW events still fire.
□ Consider technique alternatives before patching ETW:
  - Indirect syscall that avoids the hooked stub emitting the ETW event
  - Delivering via a method that does not trigger the specific ETW provider
  - Module stomping to avoid the private-memory ETW signal without patching ntdll

Detection signal — what an EDR sees when ETW is patched:
- VirtualProtect on ntdll code pages → Sysmon ID 13 (registry/memory write variants)
  or EDR proprietary memory integrity event
- RET stub at EtwEventWrite detected by integrity scan of known functions
- Absence of expected ETW events from a process that should emit them (anomaly model)
```

---

## Memory-at-rest (sleep mask) test sub-loop

A payload that passes runtime/injection testing may still be detected when sleeping
in memory. Memory scanners run on a schedule or on-demand — this is a separate
detection surface from injection-time API hooks.

**Note:** Sleep mask behaviour is implementation-specific. Test your specific mask
against your target EDR version in the lab before concluding this sub-loop.

```
Sleep mask test sub-loop:

Step 1 — Confirm the detection is at-rest, not at injection time
□ Payload injected cleanly, no alert during injection
□ Alert fires N seconds/minutes after injection, not at injection time
□ Confirm by: run the payload, wait 30–60 seconds → alert fires
  vs run the payload and kill it after 5 seconds → no alert
□ If confirmed at-rest: proceed to sleep mask sub-loop

Step 2 — Identify what the scanner is matching
□ Run a memory scanner (e.g. Moneta, PE-sieve) against the Beacon/payload PID
  while it is sleeping to see what it reports:
  moneta64.exe -p <PID>      → look for: private executable memory, unbacked PE
  pe-sieve64.exe /pid <PID>  → look for: implanted module, modified PE
□ The signal category determines the fix:

| Scanner finding              | Fix direction                                      |
|------------------------------|----------------------------------------------------|
| Private RWX region           | Apply sleep mask: RWX → RW during sleep → RX on wake |
| Private RX (no W, no mask)   | Encrypt payload + change to RW during sleep        |
| Unbacked PE header           | Erase PE header at entry point (DonutPE header wipe) |
| YARA match on payload bytes  | Encrypt the payload region at rest (sleep mask)    |
| Heap allocation with shellcode | Encode/encrypt heap allocations, not just .text   |

Step 3 — Apply and test a sleep mask
□ Integrate a sleep mask (EKKO, Foliage, or custom):
  - Encrypt the .text region (and heap allocations) before sleep
  - Change page protection to PAGE_READWRITE (or PAGE_NOACCESS) during sleep
  - Restore PAGE_EXECUTE_READ and decrypt on wake
□ Set beacon sleep to a value that allows the scanner to run between sleep intervals
  (sleep 30–60 seconds is typical; scanner runs every N minutes on most products)
□ Rerun test: inject → wait 120 seconds → check for alerts
□ Run Moneta/PE-sieve again against the sleeping beacon: confirm no private RWX,
  no YARA match, no unbacked PE
□ Log the result (run-log.sh)

Step 4 — Validate jitter
□ Predictable sleep intervals are a detection signal (beacon callback regularity)
□ Confirm: set jitter to ≥25% and observe that scanner cannot predict wakeup time
□ Some EDRs correlate time-regular process network connections against a beacon model
  — jitter must apply to both sleep and callback intervals

Step 5 — Confirm that mask does not crash the beacon on wake
□ Run 10+ full sleep cycles without crashing
□ Execute a post-ex task immediately after each wake to verify execution state is restored
□ Test with a clean snapshot reset between each test run (snapshot before inject → revert → repeat)
```

---

## What it won't do

- Automate the EDR detection — human analysis of the alert is required
- Cover Linux/macOS EDR products
- Replace a proper red team methodology — this is a development-phase tool

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `run-log.sh` (appends dated entry to `edr-test-log.md`)
- [x] Write `static-audit.sh` (strings + entropy + YARA pre-flight)
- [x] Add AMSI bypass sub-loop
- [x] Add ETW patching considerations and risk notes
- [x] Add memory-at-rest (sleep mask) test sub-loop
