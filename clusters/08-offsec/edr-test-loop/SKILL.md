# edr-test-loop

> **Status:** COMPLETE
> **Cluster:** 08-offsec

## Description
Structured hypothesis-driven loop for iterating payloads against EDR products.
Enforces test → identify signal → form hypothesis → modify → retest rather than
unstructured trial-and-error.

Invoke when: testing a payload against a live EDR in a lab environment, diagnosing
why a payload was flagged, or systematically reducing EDR detection surface across
a build iteration.

## Context needed
- EDR product and version (determines available telemetry and log locations)
- Detection type: static (file scan), dynamic (execution), or both
- Access to alert output or telemetry (Event Viewer, EDR console, Sysmon, Procmon)

## What to do

1. **Establish a clean baseline before starting.** A baseline run gives you the
   minimal alert set from a known-clean binary so you can isolate new detections.

   ```
   Baseline checklist:
   □ Snapshot the VM before every run (rollback to clean state each iteration)
   □ Disable Windows Defender if testing a third-party EDR (avoid double-detection noise)
   □ Run a known-clean binary first and confirm zero alerts
   □ Note the EDR version and definition date (detections change on signature updates)
   ```

2. **Run and capture the full detection event** before touching anything.

   For static detections (file scan on drop):
   - Note the exact file path flagged, the rule or signature name, and the
     detection category (e.g. "Trojan.Generic", "Exploit.Shellcode.X")
   - Copy the flagged file to a zip before the EDR quarantines it

   For dynamic detections (alert fires during execution):
   - Note the process name, PID, and the exact moment (before / after injection,
     at which API call)
   - Pull Sysmon event log: Event IDs 1 (process create), 8 (remote thread), 10
     (process access), 25 (image tampering), 3 (network)
   - Pull EDR console alert details — many list the triggering sequence of API calls
   - Run `strings` and entropy analysis on the payload file regardless of whether
     the detection was static or dynamic

3. **Form a single hypothesis before modifying anything.** Name what you think
   triggered the detection and what change should eliminate it.

   Hypothesis format:
   ```
   Signal:     CreateRemoteThread call on svchost.exe
   Hypothesis: EDR is hooking CreateRemoteThread and flagging cross-process thread creation
   Change:     Replace CreateRemoteThread with direct NtCreateThreadEx syscall
   Expected:   Alert does not fire; shellcode executes
   ```
   Do not make multiple changes at once — you won't know which change fixed (or broke) it.

4. **Apply the change, re-assemble / re-compile, and retest from a clean snapshot.**

   Common static detection fixes (apply one at a time):
   - High entropy section → add a junk data section or apply encryption only to
     the payload, not the loader
   - Known string match → scan with `strings` and YARA locally first
     (`yara -r rules/ payload.bin`), then rename/obfuscate matching strings
   - YARA signature match on code sequence → change the specific opcode sequence
     (reorder instructions, add NOPs, use equivalent instructions)

   Common dynamic detection fixes (apply one at a time):
   - Hooked API → switch to direct or indirect syscall
   - ETW event on API → patch `EtwEventWrite` in the target process (risky — is
     itself a detection signal on some EDRs) or use a technique that avoids the
     telemetered API
   - Unbacked executable memory → module stomping or reflective DLL with sleep mask
   - RWX allocation → allocate RW, write payload, then change to RX before execution
   - Suspicious API sequence → reorder or interleave with benign API calls

5. **Log every iteration.** Unlogged changes produce the same cycle of confusion
   across separate sessions.

   ```
   Run log format (append one entry per iteration):
   Date:       2026-05-24
   Payload:    implant_v3.bin (sha256: abc123...)
   EDR:        CrowdStrike Falcon 7.14.x, definitions 2026-05-23
   Detection:  Dynamic — CreateRemoteThread on svchost.exe (PID 1234)
   Hypothesis: Hook on CreateRemoteThread
   Change:     Replaced with NtCreateThreadEx direct syscall
   Result:     No alert. Shellcode executed successfully.
   Next:       Test sleep obfuscation to cover in-memory detection at rest
   ```

## Gotchas
- EDR definitions update automatically. A payload that passes today may fail
  tomorrow on the same EDR. Note the definition date in every log entry.
- Reversing a change to isolate the cause is as important as making a change.
  If two changes were batched and the detection disappeared, revert one to confirm
  which change was responsible.
- Sysmon event ID 25 (process tampering — image replaced) fires on module stomping
  and process hollowing. It is not an EDR alert but it feeds SIEM correlation.
- Some EDRs insert hooks in userland that patch the first few bytes of ntdll
  syscall stubs. "Direct syscall" that still routes through the hooked stub is
  not a direct syscall — verify with a debugger that execution reaches `syscall`
  without the hook wrapper.
- Memory scans at rest (sleeping beacon) are a separate detection surface from
  injection-time API-based detections. A payload that passes dynamic testing may
  still fail a post-injection memory scan. Address them as separate problems.
- Do not test against your primary engagement EDR environment. Use an isolated lab
  VM with the same EDR product to avoid burning operational infrastructure.

## Suggested scripts
- `run-log.sh` — appends a dated log entry to `edr-test-log.md` with fields for
  payload hash, EDR version, detection text, hypothesis, change, and result
- `static-audit.sh` — runs `strings`, entropy calculator, and YARA rules against
  a payload file and prints a pre-submission report
