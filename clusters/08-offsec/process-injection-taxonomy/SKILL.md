# process-injection-taxonomy

> **Status:** COMPLETE
> **Type:** instructional
> **Cluster:** 08-offsec

## Description
Classify process injection techniques by EDR visibility, required privileges,
detection surface, and recommended use case. Guides technique selection for a
given target environment and EDR product.

Invoke when: choosing an injection technique for a payload, assessing the EDR
exposure of existing code, or explaining the tradeoff between stealth and
reliability to a peer.

## Context needed
- Target process characteristics (architecture, integrity level, whether it
  makes network connections, signed/PPL status)
- EDR product and capability level (user-mode hooks only, ETW, kernel callbacks,
  or unknown)
- Privilege level available at injection time (same-session user, admin, SYSTEM)

## What to do

1. **Select a technique category based on the threat model.** The primary axis is
   EDR detection surface, not complexity. Start with the lowest-visibility technique
   that is reliable for the target.

   | Technique | Visibility | Min privilege | Reliability | Notes |
   |-----------|-----------|---------------|-------------|-------|
   | Classic shellcode injection (VirtualAllocEx + WriteProcessMemory + CreateRemoteThread) | High — all three APIs are hooked by every EDR | Same session user | High | Baseline for testing; not for operational use |
   | APC injection (QueueUserAPC) | Medium — APC delivery is ETW-visible | Same session user | Medium — requires alertable thread | Target must call SleepEx/WaitForSingleObjectEx |
   | Early-Bird APC (suspended process) | Medium-low — one CRT allocation before hooks init | Same user | High — target is freshly spawned | Spawned process starts in suspended state; APC fires before TLS callbacks |
   | Thread hijacking (SuspendThread + SetThreadContext + ResumeThread) | Medium — SetThreadContext is hooked; suspicious on non-suspended threads | Same session user | Medium — unstable if thread holds locks | Prefer against threads in a wait state |
   | Process hollowing | High — image swap is detectable via PEB mismatch; NtUnmapViewOfSection hooked | Same user | High | Creates PEB mismatch detectable by EDR image-scan |
   | Module stomping | Medium — overwrites a loaded module's `.text`; avoids VirtualAllocEx | Same user | Medium — depends on finding a suitable stomping target | Avoids private RWX allocation; reduces MEM_IMAGE anomaly |
   | DLL injection (LoadLibrary) | High — CreateRemoteThread + LoadLibrary is a classic signature | Same session user | High | Trivially detected; useful for testing only |
   | Reflective DLL injection | Medium — no LoadLibrary call; self-mapping; but VirtualAllocEx RW→X transition is visible | Same user | High | Standard operational technique |
   | Process doppelgänging (TxF) | Low-medium — abuses NTFS transaction; no hooks on TxF path (EDR-version dependent) | Same user | Low — unstable on Windows 10 1903+ | Largely patched out of reliability |
   | Phantom DLL hollowing | Low — stomps a never-executed DLL; no private allocation | Same user | Medium | Requires finding a suitable never-executed module |
   | Thread pool (TpAllocWork) | Medium-low — NT thread pool API; no CreateRemoteThread; less hooked than classic paths | Same user | Medium | Executes callback via TpPostWork; avoids direct thread creation; pool thread origin blends into normal activity |
   | Kernel-mode (driver-based) | Lowest — operates below user-mode EDR hooks entirely | Kernel (driver loaded) | High — complex; HVCI/DSE blocking risk | DKOM, APC injection from kernel, direct EPROCESS manipulation; blocked by HVCI on Secured-Core PCs; requires signed driver or BYOVD |

2. **Apply target process selection criteria before choosing the technique:**

   - **Prefer long-lived processes** that are unlikely to be restarted and that
     match your beacon's expected network profile (e.g. inject C2 traffic into a
     process that legitimately makes outbound HTTP/S calls).
   - **Avoid injecting into processes with network logging** (Sysmon event 3 maps
     to process): browsers, Office, security agents — high scrutiny.
   - **Avoid PPL (Protected Process Light) targets.** User-mode injection into
     a PPL process will fail with `STATUS_ACCESS_DENIED` regardless of privilege.
   - **Prefer 64-bit targets for 64-bit payloads.** Cross-architecture injection
     (WoW64 → native or native → WoW64) requires extra handling.

3. **Map the EDR capability tier to expected detections:**

   - **User-mode hooks only:** All three APIs in classic injection are hooked.
     Syscall-based injection bypasses these hooks by invoking the kernel directly.
   - **ETW-only (no kernel callbacks):** `EtwEventWrite` calls from hooked APIs
     generate telemetry. Direct syscalls still produce ETW events at the kernel
     level unless ETW itself is patched.
   - **Kernel callbacks (PsSetCreateProcessNotifyRoutine, etc.):** Callback fires
     on process creation regardless of injection technique. Focus on blending
     in-process behaviour (no RWX regions, no private memory execution).
   - **Full stack (ELAM + kernel callbacks + user-mode hooks):** Technique
     selection alone is insufficient. Combine with sleep obfuscation, memory
     encryption at rest, and indirect syscalls.

4. **Choose the syscall strategy to match the EDR tier:**

   - **No syscall bypass needed:** EDR has no user-mode hooks (rare) or testing only.
   - **Direct syscalls (Hell's Gate / Halo's Gate):** Resolve SSN at runtime, avoid
     hooked stubs. Bypasses user-mode hooks. ETW and kernel callbacks still fire.
   - **Indirect syscalls:** Set up a trampoline that jumps into the `syscall` instruction
     inside `ntdll` rather than executing it from your own allocation. Fewer YARA
     matches on `0F 05` in private memory.

5. **Validate the chosen technique against the target EDR before engagement deployment.**
   Use `edr-test-loop` to iterate against a lab environment matching the target's EDR
   product and version. Do not skip lab validation for a technique you have not tested
   against the specific EDR version in scope.

   See: [`edr-test-loop`](../edr-test-loop/SKILL.md)

6. **Record the chosen technique and rationale before implementing.** One line:
   ```
   Technique: Early-Bird APC
   Target: svchost.exe (spawned fresh, suspended)
   Reason: avoids CreateRemoteThread; low-visibility allocation before hooks init;
           target makes no network connections
   EDR tier assumed: user-mode hooks + ETW
   Syscall strategy: direct syscalls for NtAllocateVirtualMemory + NtWriteVirtualMemory
   ```

## Cobalt Strike delivery decision matrix

When operating with a Cobalt Strike Beacon, choose the delivery vehicle before choosing
the injection technique. The delivery mechanism determines how the injection runs and
what EDR telemetry it generates.

| Delivery | How it runs | EDR surface | When to use |
|----------|------------|------------|-------------|
| **BOF (inline-execute)** | Runs in the Beacon thread. No fork. No new process. | Lowest — no process creation event; BOF is JIT-compiled C in the Beacon's own thread | Enumeration, credential access, token manipulation. Any task that is fast, memory-safe, and needs no persistent thread. |
| **Post-ex DLL (fork-and-run)** | Beacon spawns a sacrificial process (`spawnto`), injects the post-ex DLL into it, runs the task there, then kills the process. | Medium — one process creation event (the sacrificial process) + one DLL injection | Long-running tasks (screenshot, keylogger, port scan), tasks that may crash, or tasks producing large output. |
| **Reflective DLL / shellcode (manual injection)** | You choose the target process and injection technique. Beacon executes the injection using the technique selected from the taxonomy above. | Depends on technique chosen | Custom implants, lateral movement payloads, dropping a second-stage into a specific process. |

**Decision rules:**
- Use a **BOF** if the task can be expressed in safe, short-running C and does not require a persistent thread.
- Use **fork-and-run** if the task is long-running, third-party, or unstable — the sacrificial process absorbs the crash and keeps the Beacon alive.
- Use **manual injection** when you need to control exactly which process receives the payload (e.g. injecting into a process making legitimate outbound connections to blend C2 traffic).
- Set `spawnto` to a legitimate signed binary before any fork-and-run operation. The default `rundll32.exe` is a well-known indicator.

## Gotchas
- Early-Bird APC only fires before the main thread's TLS callbacks if the process
  was suspended at creation with `CREATE_SUSPENDED`. Queueing APC to an already-
  running process is standard APC injection (requires alertable thread).
- Thread hijacking against a thread that holds a critical section lock will
  deadlock the target process. Target threads in `WaitForSingleObject` or
  `SleepEx` states.
- Module stomping leaves the stomped module in a broken state — any code that
  tries to call into the original module will crash. Prefer modules that are
  loaded but never called (e.g. a UI component not used in the current session).
- Reflective DLL injection still creates a private RWX allocation during the
  mapping phase. Modern EDRs alert on `MEM_PRIVATE` + `PAGE_EXECUTE_READWRITE`
  transitions. Apply a sleep mask to encrypt and re-protect the region at rest.
- Process doppelgänging is largely unreliable on Windows 10 1903+ due to a patch
  in the kernel image-loading path. Do not rely on it for new tooling.

## Suggested scripts
- None — this skill is a decision guide, not an automation target
