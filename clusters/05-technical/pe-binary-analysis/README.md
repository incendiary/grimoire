# pe-binary-analysis

> **Cluster:** 05-technical | **Status:** complete | **Added:** 2026-05-24

Enforces a strict convention for PE structure parsing: no WinAPI abstractions,
no library wrappers, direct struct access only. Applied during code review and
development for any Windows binary introspection work.

---

## What this skill does

Loads the convention set for PE parsing work and enforces it on all code written
or reviewed in the session:

- `ImageNtHeader()` → direct cast via `e_lfanew`
- `ImageRvaToVa()` → explicit arithmetic shown inline
- `ImageDirectoryEntryToData()` → direct `DataDirectory[]` indexing
- All RVA/file-offset arithmetic explicitly annotated
- x86 vs x64 header distinction always resolved via Magic field check
- Struct fields always referenced by fully qualified path in comments

---

## When to use it

- Writing PE parsing code in C or C++
- Reviewing PE parsing code for correctness or convention compliance
- Implementing syscall hook detection
- Analysing import tables, export tables, or relocation data
- Debugging PE structure offsets or section alignment issues
- Any session where PE binary introspection is the primary task

---

## Installation

### Claude Code

```bash
cp -r clusters/05-technical/pe-binary-analysis ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#pe-binary-analysis
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.



No hook wiring required. Load at the start of any PE-related coding session.

---

## How to invoke it in a session

Simply load the skill and proceed:

```
/pe-binary-analysis
I'm writing a PE loader and need to walk the import table.
```

Or during a review:

```
/pe-binary-analysis
Review this PE parsing function for convention compliance: [paste code]
```

The conventions are applied for the rest of the session without needing to re-state them.

---

## Workflow

```
Skill loaded → conventions active for session
        ↓
Code written or pasted for review
        ↓
Check: any WinAPI PE helpers present?
  Yes → replace with direct struct access, show formula
  No  → proceed
        ↓
Check: RVA/file offset arithmetic explicitly annotated?
  No  → add inline comment showing formula
        ↓
Check: x86 vs x64 — Magic field consulted?
  No  → add check before struct access
        ↓
Output: convention-compliant code with inline documentation
```

---

## Convention reference

| Forbidden | Replacement |
|-----------|-------------|
| `ImageNtHeader(base)` | `(IMAGE_NT_HEADERS64*)(base + dos->e_lfanew)` |
| `ImageRvaToVa(nth, base, rva, ...)` | `(PVOID)((ULONG_PTR)base + rva)` with explicit comment |
| `ImageDirectoryEntryToData(...)` | `nth->OptionalHeader.DataDirectory[entry]` directly |
| `ImageEnumerateCertificates(...)` | Parse security directory entry manually |

---

## Common errors this prevents

| Error | How the skill prevents it |
|-------|--------------------------|
| RVA treated as file offset | Forces explicit annotation and conversion formula |
| x86/x64 struct mismatch | Requires Magic field check before any struct cast |
| On-disk vs in-memory confusion | Requires explicit target statement before analysis |
| Silent WinAPI dependency | Replaces all WinAPI helpers with direct access |

---

## Syscall hook detection — byte-pattern reference

EDRs inline-hook ntdll syscall stubs by overwriting the first bytes with a `JMP`.
Compare the live stub bytes against the clean pattern to detect the hook.

**x64 clean stub (unhooked):**
```
4C 8B D1        ; mov r10, rcx        (copy arg 1 to r10, per calling convention)
B8 XX 00 00 00  ; mov eax, <SSN>      (syscall service number)
0F 05           ; syscall
C3              ; ret
```

**x64 hooked stub (EDR JMP hook — most common pattern):**
```
E9 XX XX XX XX  ; jmp rel32 → EDR hook handler
...             ; rest of original bytes (irrelevant — execution diverted)
```

**Detection check — byte-by-byte comparison:**
```c
BOOL IsSyscallHooked(PVOID stub) {
    // Clean x64 stub starts: 4C 8B D1 B8
    BYTE expected[] = { 0x4C, 0x8B, 0xD1, 0xB8 };
    return memcmp(stub, expected, sizeof(expected)) != 0;
}
```

**x86 clean stub (Windows 10, syscall-via-shared-data path):**
```
B8 XX 00 00 00  ; mov eax, <SSN>
BA 00 03 FE 7F  ; mov edx, 0x7FFE0300   (KUSER_SHARED_DATA.SystemCallStub)
FF D2           ; call edx
C2 XX 00        ; ret N                 (N = stack cleanup for the specific syscall)
```

**x86 alternate (older Windows — int 2E path):**
```
B8 XX 00 00 00  ; mov eax, <SSN>
BA 00 00 00 00  ; mov edx, 0  (not used in all versions)
64 FF 15 C0 00 00 00  ; call dword ptr fs:[0xC0]
C2 XX 00        ; ret N
```

**SSN lookup — resolving the service number from ntdll on disk:**
The SSN is the `imm32` in the `mov eax` instruction at offset 4 in the stub.
Read from the ntdll export via EAT walk, then: `SSN = *(DWORD*)(stub + 4)`.

**Full clean-vs-live comparison for hook detection:**
```c
// Compare first 8 bytes of live (mapped) stub against on-disk ntdll stub.
// On-disk ntdll is clean; the in-process mapped ntdll may be patched.
BOOL IsHooked(PVOID live_stub, PVOID disk_stub) {
    return memcmp(live_stub, disk_stub, 8) != 0;
}
// To get disk_stub: open ntdll from disk with CreateFile + MapViewOfFile,
// then resolve the same export via the EAT of the disk-mapped image.
```

---

## Worked example — import table walk without WinAPI

Walk `IMAGE_DIRECTORY_ENTRY_IMPORT` to enumerate all imported DLLs and their functions.

```c
#define RVA(base, rva) ((PVOID)((ULONG_PTR)(base) + (DWORD)(rva)))

void WalkImportTable(PVOID base) {
    PIMAGE_DOS_HEADER dos = (PIMAGE_DOS_HEADER)base;
    PIMAGE_NT_HEADERS64 nth = (PIMAGE_NT_HEADERS64)RVA(base, dos->e_lfanew);

    // IMAGE_DIRECTORY_ENTRY_IMPORT = index 1
    DWORD iat_rva = nth->OptionalHeader.DataDirectory[1].VirtualAddress;
    if (!iat_rva) return;  // no imports

    PIMAGE_IMPORT_DESCRIPTOR imp = (PIMAGE_IMPORT_DESCRIPTOR)RVA(base, iat_rva);

    // Iterate import descriptors — sentinel entry has Name = 0 and FirstThunk = 0
    for (; imp->Name != 0; imp++) {
        const char* dll_name = (const char*)RVA(base, imp->Name);

        // OriginalFirstThunk = hint/name table; FirstThunk = IAT (gets patched by loader)
        // Use OriginalFirstThunk to read names; it is not patched
        PIMAGE_THUNK_DATA64 thunk = (PIMAGE_THUNK_DATA64)RVA(base, imp->OriginalFirstThunk);

        for (; thunk->u1.AddressOfData != 0; thunk++) {
            if (thunk->u1.Ordinal & IMAGE_ORDINAL_FLAG64) {
                // Imported by ordinal — no name
                DWORD ordinal = (DWORD)(thunk->u1.Ordinal & 0xFFFF);
                // printf("%s  #%lu\n", dll_name, ordinal);
            } else {
                // Imported by name — AddressOfData is RVA to IMAGE_IMPORT_BY_NAME
                PIMAGE_IMPORT_BY_NAME ibn =
                    (PIMAGE_IMPORT_BY_NAME)RVA(base, thunk->u1.AddressOfData);
                // ibn->Hint = export name table index (hint, not guaranteed)
                // ibn->Name = null-terminated function name string
                // printf("%s  %s (hint %u)\n", dll_name, ibn->Name, ibn->Hint);
            }
        }
    }
}
```

**Key points:**
- `IMAGE_DIRECTORY_ENTRY_IMPORT` = index 1 in `DataDirectory[]`. Direct index — no `ImageDirectoryEntryToData`.
- `OriginalFirstThunk` (the INT) preserves names; `FirstThunk` (the IAT) is overwritten with resolved addresses by the loader. Always walk the INT for names.
- Sentinel: the last `IMAGE_IMPORT_DESCRIPTOR` has both `Name` and `FirstThunk` set to zero.
- This is an in-memory walk. `base` is the image base of the loaded module, not a file handle.

---

## Worked example — section table traversal with RVA/file-offset conversion

Walk the section headers to enumerate sections and convert an RVA to a file offset.

```c
void WalkSections(PVOID base) {
    PIMAGE_DOS_HEADER dos = (PIMAGE_DOS_HEADER)base;
    PIMAGE_NT_HEADERS64 nth = (PIMAGE_NT_HEADERS64)RVA(base, dos->e_lfanew);

    WORD num_sections = nth->FileHeader.NumberOfSections;

    // Section headers begin immediately after the NT headers (optional header included)
    // Formula: IMAGE_NT_HEADERS64 is at dos->e_lfanew; size = 4 (sig) + 20 (COFF) + SizeOfOptionalHeader
    PIMAGE_SECTION_HEADER sec = IMAGE_FIRST_SECTION(nth);
    // IMAGE_FIRST_SECTION(nth) = (IMAGE_SECTION_HEADER*)((ULONG_PTR)(nth)
    //   + FIELD_OFFSET(IMAGE_NT_HEADERS, OptionalHeader)
    //   + nth->FileHeader.SizeOfOptionalHeader)

    for (WORD i = 0; i < num_sections; i++, sec++) {
        // sec->Name is 8 bytes, NOT null-terminated if exactly 8 chars
        // sec->VirtualAddress = RVA of section start in memory
        // sec->VirtualSize    = actual used size in memory (may exceed SizeOfRawData)
        // sec->PointerToRawData = file offset of section data on disk
        // sec->SizeOfRawData    = padded-to-FileAlignment size of section data on disk

        // RVA → file offset (for on-disk PE only):
        // if (rva >= sec->VirtualAddress && rva < sec->VirtualAddress + sec->SizeOfRawData)
        //   file_offset = (rva - sec->VirtualAddress) + sec->PointerToRawData;
    }
}

// RVA-to-file-offset helper — returns 0 if rva is not within any section
DWORD RvaToFileOffset(PVOID file_base, DWORD rva) {
    PIMAGE_DOS_HEADER dos = (PIMAGE_DOS_HEADER)file_base;
    PIMAGE_NT_HEADERS64 nth = (PIMAGE_NT_HEADERS64)RVA(file_base, dos->e_lfanew);
    PIMAGE_SECTION_HEADER sec = IMAGE_FIRST_SECTION(nth);

    for (WORD i = 0; i < nth->FileHeader.NumberOfSections; i++, sec++) {
        if (rva >= sec->VirtualAddress &&
            rva <  sec->VirtualAddress + sec->SizeOfRawData) {
            // VA formula (annotated):
            // file_offset = PointerToRawData + (rva - VirtualAddress)
            return sec->PointerToRawData + (rva - sec->VirtualAddress);
        }
    }
    return 0;  // not found — rva may be in a zero-padded virtual region
}
```

**Key points:**
- `IMAGE_FIRST_SECTION` is a macro from `winnt.h` — safe to use; it does direct pointer arithmetic, not a WinAPI call.
- `VirtualSize` can exceed `SizeOfRawData`: the difference is zeroed in memory but absent from the file. RVA-to-file-offset is only valid within `SizeOfRawData`.
- This helper is for on-disk parsing. For in-memory parsing, VA = `ImageBase + RVA` directly — no section lookup needed.
- Section `.Name` is exactly 8 bytes. If the name is 8 chars, there is no null terminator. Use `strncmp(..., 8)` or copy + add null.

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Add syscall hook detection byte-pattern reference (clean stub patterns for common syscalls)
- [x] Add worked example: full import table walk without WinAPI
- [x] Add worked example: section table traversal with RVA/file-offset conversion
- [ ] Test on 2 real PE parsing sessions
- [x] Ship: copy to `~/.claude/skills/pe-binary-analysis/`
