# api-hashing-conventions

> **Cluster:** 08-offsec | **Status:** complete | **Added:** 2026-05-24

Standardised hash-based API resolution: algorithm selection table (ROR13 / DJB2 /
FNV-1a), compile-time hash macros and constexprs, PEB/EAT walk with forwarded export
handling, and collision verification before shipping.

---

## What this skill does

Pre-loads the full resolution pipeline before writing any shellcode or BOF that
must call Windows APIs without importing name strings. Catches the common mistakes:
mixing algorithms across a project, incorrect `AddressOfNameOrdinals` indexing,
missed forwarded exports, and hash collisions in the target function set.

---

## When to use it

- Writing API resolution in shellcode (PIC — no imports table)
- Writing a BOF that needs APIs not available via `DECLAREIMPORT`
- Reviewing existing hash-resolution code for correctness
- Choosing an algorithm for a new project

---

## Installation

### Claude Code

```bash
cp -r clusters/08-offsec/api-hashing-conventions ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#api-hashing-conventions
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

```
/api-hashing-conventions
Algorithm: DJB2, target arch: x64
APIs needed: LoadLibraryA, VirtualAlloc, VirtualProtect, CreateThread
```

---

## Workflow

```
Choose algorithm (document it)
        ↓
Implement compile-time hash macro / constexpr
        ↓
PEB walk → module base (ntdll @ index 1, kernel32 @ index 2)
        ↓
EAT walk → names[] hash match → ordinals[i] → funcs[ordinals[i]]
        ↓
Forwarded export check (RVA within export directory → resolve forward)
        ↓
Collision check against full DLL export list
```

---

## What it won't do

- Implement the PEB walk inline — see `shellcode-dev-conventions` for the full
  x86/x64 PEB structure and offsets
- Handle ordinal-only exports — those require a separate ordinal lookup path

---

## Worked end-to-end example — x64 shellcode resolving VirtualAlloc + CreateThread

**Goal:** Position-independent x64 shellcode that resolves `VirtualAlloc` and
`CreateThread` from `kernel32` using DJB2 hashing, without any import table.

**Step 1 — generate the hashes at development time:**
```python
# hash-api.py (included in this skill)
# python3 hash-api.py kernel32.dll VirtualAlloc CreateThread
#
# Output:
#   DJB2  VirtualAlloc  = 0x7C0DFCAA
#   DJB2  CreateThread  = 0x64399C43
```

**Step 2 — define the constexpr and embed hashes as constants:**
```cpp
constexpr DWORD djb2(const char* s) {
    DWORD h = 5381;
    while (*s) h = ((h << 5) + h) ^ (BYTE)*s++;
    return h;
}

// Compile-time constants — no name strings in .text
static const DWORD HASH_VirtualAlloc  = djb2("VirtualAlloc");   // 0x7C0DFCAA
static const DWORD HASH_CreateThread  = djb2("CreateThread");    // 0x64399C43
static const DWORD HASH_KERNEL32      = djb2_wide("KERNEL32.DLL"); // wide hash
```

**Step 3 — PEB walk to find kernel32 base (x64):**
```c
// gs:[0x60] = PEB; PEB+0x18 = PEB.Ldr; Ldr+0x20 = InMemoryOrderModuleList
// index 0 = current image, index 1 = ntdll, index 2 = kernel32/kernelbase
// Walk by name hash to be order-independent:
PVOID GetKernel32Base(void) {
    PPEB peb = (PPEB)__readgsqword(0x60);
    PLIST_ENTRY head = &peb->Ldr->InMemoryOrderModuleList;
    PLIST_ENTRY cur  = head->Flink;
    while (cur != head) {
        PLDR_DATA_TABLE_ENTRY entry =
            CONTAINING_RECORD(cur, LDR_DATA_TABLE_ENTRY, InMemoryOrderLinks);
        // Hash the wide BaseDllName — cast each WCHAR to BYTE (low byte)
        if (HashWide(entry->BaseDllName.Buffer) == HASH_KERNEL32)
            return entry->DllBase;
        cur = cur->Flink;
    }
    return NULL;
}
```

**Step 4 — EAT walk to resolve VirtualAlloc:**
```c
typedef LPVOID (WINAPI* pVirtualAlloc)(LPVOID, SIZE_T, DWORD, DWORD);

pVirtualAlloc ResolveVirtualAlloc(PVOID k32_base) {
    PIMAGE_DOS_HEADER dos = (PIMAGE_DOS_HEADER)k32_base;
    PIMAGE_NT_HEADERS64 nth = (PIMAGE_NT_HEADERS64)
        ((ULONG_PTR)k32_base + dos->e_lfanew);
    DWORD eat_rva = nth->OptionalHeader.DataDirectory[0].VirtualAddress;
    DWORD eat_size = nth->OptionalHeader.DataDirectory[0].Size;
    PIMAGE_EXPORT_DIRECTORY eat =
        (PIMAGE_EXPORT_DIRECTORY)((ULONG_PTR)k32_base + eat_rva);

    PDWORD names    = (PDWORD)((ULONG_PTR)k32_base + eat->AddressOfNames);
    PWORD  ords     = (PWORD) ((ULONG_PTR)k32_base + eat->AddressOfNameOrdinals);
    PDWORD funcs    = (PDWORD)((ULONG_PTR)k32_base + eat->AddressOfFunctions);

    for (DWORD i = 0; i < eat->NumberOfNames; i++) {
        const char* name = (const char*)((ULONG_PTR)k32_base + names[i]);
        if (djb2(name) == HASH_VirtualAlloc) {
            DWORD func_rva = funcs[ords[i]];
            // Check for forwarded export: RVA within the export directory range
            if (func_rva >= eat_rva && func_rva < eat_rva + eat_size)
                return NULL;  // VirtualAlloc does not forward; treat as unexpected
            return (pVirtualAlloc)((ULONG_PTR)k32_base + func_rva);
        }
    }
    return NULL;
}
```

**Step 5 — verify no collision in the target function set:**
```bash
# Run collision-check.py against kernel32.dll using DJB2
python3 collision-check.py /Windows/System32/kernel32.dll \
    VirtualAlloc VirtualProtect CreateThread ExitThread
# Expected: no collisions reported
# If a collision is reported, switch to FNV-1a for the conflicting pair
```

**Step 6 — pairing note for shellcode-dev-conventions:**
This example covers the resolution layer only. For the complete PEB structure layout,
x86 `fs:[0x30]` offsets, and position-independent prologue patterns, see
[`shellcode-dev-conventions`](../shellcode-dev-conventions/SKILL.md).

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `hash-api.py` (multi-algorithm hash printer)
- [x] Write `collision-check.py` (validates target function set against DLL export list)
- [x] Add x86 variant with `fs:[0x30]` PEB offset
- [x] Add worked end-to-end example pairing with `shellcode-dev-conventions`
