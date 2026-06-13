# shellcode-dev-conventions

> **Status:** COMPLETE
> **Type:** instructional
> **Cluster:** 08-offsec

## Description
Enforce position-independent code conventions for shellcode: no global variables,
no absolute addresses, delta-offset or PEB-walk for self-location, hash-based API
resolution, and null-byte / bad-character awareness.

Invoke when: writing raw shellcode, reflective DLL entry stubs, staged payload stubs,
or any code that must execute without a loader fixing up relocations.

## Context needed
- Target architecture (x86 or x64 — affects register conventions and PEB offset)
- Execution context (injected thread, shellcode loader, ROP-delivered, staged/stageless)
- Size constraint and bad-character set (if staging through a limited buffer)

## What to do

1. **Verify the code is truly position-independent before writing any logic.**
   PIC means no references to absolute addresses and no use of the `.data` section
   for writable globals. Violations are silent at build time and crash at runtime.

   - No global variables. Constants go in `.text` as inline immediates or `CALL/POP`
     strings. Writable state lives on the stack or in heap-allocated memory.
   - No function pointers initialised at compile time (they are relocated data).
   - No C runtime (CRT) — CRT init code is not PIC and references the loader.

2. **Use the delta-offset technique to find your own base address** if you need
   to reference data within the shellcode blob:
   ```asm
   ; x64
   call  delta
   delta:
     pop   rbx          ; rbx = address of 'delta' label = runtime position
     sub   rbx, offset delta - shellcode_base
   ```
   For reflective loaders, the entry point receives its own base via a parameter
   or resolves it by scanning backwards from the return address.

3. **Walk the PEB to resolve module base addresses.** Never import or hardcode
   module base addresses — they vary across OS versions and ASLR.

   **x64 PEB walk (gs:[0x60]):**
   ```c
   // InMemoryOrderModuleList is at PEB+0x18 (Ldr), Ldr+0x20 (InMemoryOrderModuleList)
   PPEB peb = (PPEB)__readgsqword(0x60);
   PLIST_ENTRY head = &peb->Ldr->InMemoryOrderModuleList;
   for (PLIST_ENTRY e = head->Flink; e != head; e = e->Flink) {
       PLDR_DATA_TABLE_ENTRY entry = CONTAINING_RECORD(e, LDR_DATA_TABLE_ENTRY, InMemoryOrderLinks);
       // entry->DllBase is the module base
       // entry->BaseDllName.Buffer is the unicode name
   }
   ```
   **x86:** replace `__readgsqword(0x60)` with `__readfsdword(0x30)`.
   Module order: index 0 = executable, index 1 = ntdll, index 2 = kernel32.

4. **Resolve function addresses by hashing export names**, not by importing strings.
   See `api-hashing-conventions` skill for the full algorithm. Key principle: the
   hash is computed at compile time (macro or constexpr), the EAT walk happens at
   runtime, and no function name string appears in the binary.

5. **Audit for null bytes and bad characters after assembly.** Most shellcode
   delivery mechanisms treat `\x00` as a string terminator.

   Common sources of null bytes:
   - `mov eax, 0` → use `xor eax, eax` instead
   - `push 0` in x86 call setup → use `push ebx` after `xor ebx, ebx`
   - Short jumps that expand to `\x0f\x84\x00\x00...` (far conditional) → keep
     jump targets within ±127 bytes to force short encoding

   After assembling:
   ```bash
   objdump -d shellcode.o | grep -P "\\\\x00"
   # or
   xxd shellcode.bin | grep " 00"
   ```

6. **Enforce size discipline from the start.** Stageless payloads delivered over
   network protocols have hard size limits (Metasploit stageless default ~900 bytes,
   some exploits tighter). Profile early:
   ```bash
   wc -c shellcode.bin
   ```
   Compress or encode only as a last resort — encoders add stubs and may introduce
   bad characters of their own.

## Gotchas
- `__declspec(thread)` (TLS) variables are not PIC. Avoid.
- Strings as C `const char*` go into `.rdata`, which is a separate section and will
  not be present in a flat shellcode blob. Use `CALL/POP` or inline char arrays.
- MSVC inline assembly (`__asm`) is not available in x64 builds. Use a `.asm` file
  with MASM or switch to intrinsics / compiler builtins for the critical sections.
- Stack alignment: x64 ABI requires 16-byte alignment at the point of a `CALL`.
  If entering shellcode from an injected thread the stack may be misaligned — add
  `and rsp, 0xFFFFFFFFFFFFFFF0` before any calls.
- Calling convention in x64 Windows: first four args in RCX, RDX, R8, R9 with
  32 bytes of shadow space reserved on the stack before the call.
- A reflective DLL is not flat shellcode — it has a full PE header. Don't strip it
  unless implementing a header wipe post-load.

## Suggested scripts
- `null-byte-audit.sh` — assembles the object and reports any `\x00` bytes with
  their offset and surrounding instruction context
- `size-report.sh` — prints raw byte count and estimates encoded size at +35%
  (XOR encoder overhead approximation)
