# api-hashing-conventions

> **Status:** COMPLETE
> **Cluster:** 08-offsec

## Description
Standardise hash-based API resolution for shellcode and BOFs: algorithm selection,
PEB/EAT walk implementation, compile-time hash generation to keep name strings out
of the binary, and forwarded export handling.

Invoke when: implementing API resolution without importing function names as plaintext
strings, or reviewing existing hash-based resolution code for correctness.

## Context needed
- Target architecture (x86 or x64 — affects PEB offsets)
- Hash algorithm already in use in the project (to avoid mixing algorithms)
- Whether compile-time hash generation is required (avoids name strings in `.text`)

## What to do

1. **Choose an algorithm and document it at the top of the file.** Mixing algorithms
   across a project causes hard-to-diagnose mismatches. Pick one and commit.

   | Algorithm | Properties | Notes |
   |-----------|-----------|-------|
   | ROR13     | Fast, small, well-known | Most common in public shellcode / Metasploit |
   | DJB2      | Low collision rate, simple | Good for longer export name sets |
   | FNV-1a    | Well-distributed, one multiply | Slightly larger instruction footprint |

   ROR13 is the default for x86/x64 shellcode matching the Metasploit convention.
   DJB2 is preferable for BOFs with larger API sets where collision risk matters.

2. **Implement compile-time hash generation as a macro or constexpr function.**
   This ensures no function name string appears in the compiled binary.

   **ROR13 — C preprocessor macro (MSVC / clang-cl compatible):**
   ```c
   #define ROTR32(v, n) (((v) >> (n)) | ((v) << (32 - (n))))
   // Compute at call site: HASH_ROR13("LoadLibraryA")
   // For compile-time evaluation use a constexpr in C++ or a build-time generator
   ```

   **DJB2 — C++ constexpr (compile-time evaluation guaranteed):**
   ```cpp
   constexpr DWORD djb2(const char* s) {
       DWORD h = 5381;
       while (*s) h = ((h << 5) + h) ^ (BYTE)*s++;
       return h;
   }
   #define API(name) djb2(name)
   ```

   **ROR13 — C++ constexpr:**
   ```cpp
   constexpr DWORD ror13(const char* s) {
       DWORD h = 0;
       while (*s) {
           h = ((h >> 13) | (h << 19));   // ROR 13
           h += (BYTE)*s++;
       }
       return h;
   }
   ```

3. **Walk the PEB to find module bases, then walk the EAT to find function addresses.**

   **Module base from PEB (x64):**
   ```c
   // PEB at gs:[0x60]; Ldr at PEB+0x18; InMemoryOrderModuleList at Ldr+0x20
   // Each LIST_ENTRY forward link points to LDR_DATA_TABLE_ENTRY.InMemoryOrderLinks
   // DllBase is at offset 0x20 from InMemoryOrderLinks in the entry struct
   // BaseDllName.Buffer (unicode) is at offset 0x48 from InMemoryOrderLinks
   ```
   Canonical load order: [0] = image, [1] = ntdll, [2] = kernel32/kernelbase.
   For most shellcode: walk until the module name hash matches the target.

   **Function address from EAT:**
   ```c
   PVOID resolve(PVOID module_base, DWORD target_hash) {
       PIMAGE_DOS_HEADER dos = (PIMAGE_DOS_HEADER)module_base;
       PIMAGE_NT_HEADERS nt  = RVA(module_base, dos->e_lfanew);
       DWORD eat_rva = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
       PIMAGE_EXPORT_DIRECTORY eat = RVA(module_base, eat_rva);

       PDWORD names   = RVA(module_base, eat->AddressOfNames);
       PWORD  ordinals = RVA(module_base, eat->AddressOfNameOrdinals);
       PDWORD funcs   = RVA(module_base, eat->AddressOfFunctions);

       for (DWORD i = 0; i < eat->NumberOfNames; i++) {
           const char* name = RVA(module_base, names[i]);
           if (hash(name) == target_hash) {
               DWORD func_rva = funcs[ordinals[i]];
               // Check for forwarded export before returning
               if (func_rva >= eat_rva && func_rva < eat_rva + eat_size)
                   return resolve_forwarded(module_base, RVA(module_base, func_rva));
               return RVA(module_base, func_rva);
           }
       }
       return NULL;
   }
   #define RVA(base, rva) ((PVOID)((ULONG_PTR)(base) + (DWORD)(rva)))
   ```

4. **Handle forwarded exports.** A forwarded export is an EAT entry whose RVA falls
   within the export directory itself — the "address" is actually a string like
   `KERNELBASE.LoadLibraryA`. Common cases: many `kernel32` functions forward to
   `kernelbase`, some `ntdll` functions forward to `win32u`.

   Forwarded export resolution:
   ```c
   // forward_string looks like "MODULE.FunctionName" or "MODULE.#ordinal"
   // 1. Parse module name (up to the '.')
   // 2. Find the module base via PEB walk or LoadLibrary equivalent
   // 3. Resolve the function name or ordinal in that module's EAT
   ```

5. **Verify hashes at development time.** A hash collision (two different names
   producing the same hash) will resolve to the wrong function silently.

   Before shipping:
   ```python
   # Verify no two API names in your usage set share a hash
   # Run against the full export list of target modules
   python3 -c "
   import pefile, sys
   pe = pefile.PE(sys.argv[1])
   hashes = {}
   for exp in pe.DIRECTORY_ENTRY_EXPORT.symbols:
       name = exp.name.decode() if exp.name else None
       if name:
           h = ror13(name)  # implement ror13 here
           if h in hashes:
               print(f'COLLISION: {name} == {hashes[h]}')
           hashes[h] = name
   "
   ```

## Gotchas
- DLL names in the PEB `BaseDllName` are wide (UTF-16LE). Hash them as ASCII or
  compare them character by character, casting each wide char to `BYTE` (low byte
  only — valid for ASCII-range module names).
- The load order in the PEB can change at runtime if modules are loaded dynamically.
  For the core set (ntdll, kernel32), index-based lookup is reliable. For others,
  always walk by name hash.
- `AddressOfNameOrdinals` is an array of `WORD` (2-byte) ordinal biases, not absolute
  ordinals. Index into `AddressOfFunctions` using `ordinals[i]`, not `i`.
- `NumberOfNames` ≠ `NumberOfFunctions`. Functions exported by ordinal only do not
  appear in the name table and cannot be found by name hash.
- ROR13 is published and well-known — signatures exist for it. For novel payloads
  consider DJB2 or FNV-1a to avoid trivial YARA matches on the hash loop.

## Suggested scripts
- `hash-api.py` — takes a DLL path and function name, prints the hash value under
  each supported algorithm (ROR13, DJB2, FNV-1a) for use as a compile-time constant
- `collision-check.py` — takes a DLL path and a list of target function names,
  reports any hash collisions within the set under the chosen algorithm
