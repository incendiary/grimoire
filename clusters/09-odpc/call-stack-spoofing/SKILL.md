# call-stack-spoofing

> **Status:** COMPLETE
> **Cluster:** 09-odpc
> **Maps to:** Chapter 29 (Return Address Patching), Chapter 30 (Stack Spoofing with Synthetic Frames)

## Description
Techniques for making injected shellcode threads appear to have legitimate call stacks.
Covers return address patching (patch before sleep, restore after), synthetic frame
construction using VEH and RtlCaptureContext, and what a spoofed call chain must look
like to survive EDR stack unwinding.

Invoke when: implementing sleep masking, debugging why call stack inspection is catching
a payload, or building a thread that must survive call stack auditing.

## Why call stacks matter

EDRs scan thread call stacks to detect unbacked memory allocations — regions with `RX`
permissions that are not backed by a legitimate DLL on disk. If a thread's return address
points into a VirtualAlloc'd region (rather than a module), it is flagged.

Two complementary approaches:
1. **Return address patching** — overwrite the return address on the stack before sleeping,
   restore it before resuming. The EDR scans during sleep and sees a clean stack.
2. **Synthetic frames** — construct a fake call chain that looks like the thread woke up
   inside a legitimate Windows DLL (e.g. `ntdll!TpCallbackIndirection`).

## Return address patching

The simplest approach: before calling `Sleep`, find the shellcode return address on the
stack and overwrite it with the address of a legitimate function. Restore after sleep.

```c
// Concept — simplified; real implementation uses SEH or VEH to locate exact frame
PVOID pShellcodeRetAddr  = /* address of return instruction inside your shellcode */;
PVOID pLegitimateAddr    = (PVOID)Sleep;  // or any ntdll/kernel32 export

// Patch: overwrite the return address on the stack
PVOID* pRetSlot = /* find the stack slot containing pShellcodeRetAddr */;
*pRetSlot = pLegitimateAddr;

// Sleep — EDR scans; sees stack pointing to Sleep (legitimate)
Sleep(jitter);

// Restore before execution resumes
*pRetSlot = pShellcodeRetAddr;
```

**Finding the return address slot:**
Use `RtlCaptureContext` to get a `CONTEXT` struct with `Rsp`, then walk the stack frames.
The return address for the current function is at `[Rsp]`; for the caller at `[Rsp + 8]`, etc.

## Synthetic frame construction

A more robust approach: instead of patching a real return address, build a completely
synthetic call chain so the stack looks like it came from legitimate Windows code.

High-level flow:
1. Use `VEH` (Vectored Exception Handler) to intercept a hardware breakpoint
2. Manipulate `CONTEXT.Rsp` and `CONTEXT.Rip` to set up a fake frame sequence
3. The fake sequence mimics: `ntdll!TpCallbackIndirection` → `ntdll!TpProcessWork` → your function
4. Call `NtWaitForSingleObject` (or Sleep) — the stack now shows the fake chain

### Canonical fake call chain (ntdll thread pool pattern)

EDRs recognise this as a legitimate thread originating from the Windows thread pool:

```
ntdll!TpCallbackIndirection     ← top of stack (most recent call)
ntdll!TpProcessWork
ntdll!TppWorkerThread
kernel32!BaseThreadInitThunk
ntdll!RtlUserThreadStart
```

Resolve these addresses at runtime:
```c
PVOID pTpCallbackIndirection = /* scan ntdll for symbol or use offset from known build */;
PVOID pTpProcessWork         = /* same */;
PVOID pTppWorkerThread       = /* same */;
PVOID pBaseThreadInitThunk   = GetProcAddress(GetModuleHandleA("kernel32.dll"), "BaseThreadInitThunk");
PVOID pRtlUserThreadStart    = GetProcAddress(GetModuleHandleA("ntdll.dll"), "RtlUserThreadStart");
```

### Frame layout on the stack (x64)

Each frame on the x64 stack requires:
- A return address (8 bytes) — the address the `ret` instruction would return to
- A stack frame pointer (`rbp`) — 8 bytes, aligned
- Optionally: shadow space (32 bytes) for functions following Windows calling convention

```c
// Build synthetic stack: write return addresses from bottom to top
ULONG_PTR* pStack = (ULONG_PTR*)pSyntheticStack;
// Arrange so that walking from Rsp produces the desired chain
*pStack++ = (ULONG_PTR)pRtlUserThreadStart;
*pStack++ = (ULONG_PTR)pBaseThreadInitThunk;
*pStack++ = (ULONG_PTR)pTppWorkerThread;
*pStack++ = (ULONG_PTR)pTpProcessWork;
*pStack++ = (ULONG_PTR)pTpCallbackIndirection;
*pStack++ = (ULONG_PTR)/* your wait/sleep function return site */;
```

## Integration with sleep masking

Return address patching and synthetic frames are most commonly used as part of a
**sleep mask** — the sequence around every `Sleep` or `NtWaitForSingleObject` call
inside a Beacon sleep callback or custom implant:

```
1. Encrypt heap (optional — memory scanning evasion)
2. Patch / spoof call stack
3. Sleep / wait
4. Restore call stack
5. Decrypt heap
6. Resume execution
```

## What a spoofed chain must satisfy

EDRs validate call stacks by checking:
1. Each return address points inside a legitimate, mapped module (not private RX memory)
2. The functions at each frame are plausible callers of the next (code flow analysis)
3. The unwind data (`RUNTIME_FUNCTION` / `.pdata` section) supports each frame
   (structured exception handling uses this — mismatched unwind data causes exceptions)

For (3): functions in the synthetic chain must have valid `.pdata` entries in their
parent module. Thread pool functions do. Random exports may not.

## Gotchas

- **Alignment:** x64 stack must be 16-byte aligned before a `call` (so `Rsp` is 8-byte aligned at entry, 16-byte after pushing the return address). Misalignment causes a `#GP` fault.
- **Unwind data mismatch:** If your synthetic frame references a function whose `.pdata` doesn't match the stack layout, SEH unwinding will crash. Stick to well-known thread pool functions with documented frame layouts.
- **CrowdStrike walks deep:** CS Falcon walks the full thread stack, not just the top 2-3 frames. The entire chain must be clean.
- **Return address patching is racy:** If an EDR scans immediately after you patch but before you restore, a legitimate-looking address is a different function. Make the patch window as short as possible.
- **MDE correlates stacks with ETW:** Even a spoofed stack can be correlated with ETW events showing the real execution path. Combine with ETW patching (see etw-evasion).

## Related skills

- `caro-kann-injection` — sleep masking is the practical application of call stack spoofing
- `etw-evasion` — complement call stack spoofing with ETW patching to remove the corroborating telemetry
- `edr-test-loop` — test call stack spoofing against each EDR in the lab
- `odpc-lab-setup` — x64dbg workflow for inspecting the live call stack
