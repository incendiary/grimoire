# bof-dev-conventions

> **Status:** COMPLETE
> **Cluster:** 08-offsec

## Description
Enforce Beacon Object File development conventions: correct BOF API usage, no static
globals, argument parsing via `datap`, proper output and cleanup, and compilation
flags for both MSVC and clang-cl.

Invoke when: writing a new BOF for Cobalt Strike or a compatible C2 framework, or
reviewing BOF code for correctness and stability before deployment.

## Context needed
- Target C2 framework (Cobalt Strike, Havoc, Sliver, or other) — determines which
  BOF API headers are in scope
- Whether the BOF is inline (runs inside Beacon) or fork-and-run (spawned in a
  sacrificial process)
- Argument types expected from the aggressor script or client-side call

## What to do

1. **Include the correct headers and use only the BOF API — no libc, no CRT.**
   BOFs share memory with Beacon. Any CRT initialisation or libc call that expects
   a fully initialised runtime environment will crash the Beacon process.

   ```c
   #include "beacon.h"    // Cobalt Strike BOF API header

   // ONLY these output functions:
   BeaconPrintf(CALLBACK_OUTPUT, "...");
   BeaconPrintf(CALLBACK_ERROR,  "...");

   // ONLY these dynamic import macros:
   DECLAREIMPORT(Kernel32, CreateToolhelp32Snapshot);
   // Then call via:
   IMPORT(Kernel32, CreateToolhelp32Snapshot)(TH32CS_SNAPPROCESS, 0);
   ```

   Never use `printf`, `malloc`, `free`, `strlen`, or any other CRT function.
   Use `BeaconDataLength` / `BeaconDataExtract` variants for memory operations.

2. **Do not use static or global variables.** BOFs do not get their own address
   space — the `.data` and `.bss` sections are loaded into Beacon's memory at
   a fixed address for that Beacon instance. A second concurrent BOF execution
   would corrupt the first's globals. All state goes on the stack or in
   heap allocations freed before return.

   ```c
   // WRONG
   static HANDLE g_snapshot = NULL;
   // CORRECT — declare on stack or heap, free before returning
   HANDLE snapshot = CreateToolhelp32Snapshot(...);
   ```

3. **Parse arguments using the `datap` struct and `BeaconDataParse` family.**
   Cobalt Strike passes arguments as a packed binary blob; accessing raw `argv`
   will read garbage.

   ```c
   void go(char* args, int len) {
       datap parser;
       BeaconDataParse(&parser, args, len);

       int   mode  = BeaconDataInt(&parser);
       char* name  = BeaconDataExtract(&parser, NULL);  // null-terminated string
       short flags = BeaconDataShort(&parser);
   }
   ```

   Argument order in `go()` must match the order packed by the aggressor script:
   ```cna
   // Aggressor script packing:
   $args = bof_pack($1, "isz", $mode, $flags, $name);
   // Maps to: BeaconDataInt, BeaconDataShort, BeaconDataExtract
   ```

   Pack format characters: `i` = int (4B), `s` = short (2B), `z` = string
   (null-terminated), `b` = binary blob, `Z` = wide string.

4. **Close all handles, free all heap allocations, and flush output before returning.**
   Beacon is a long-running process. Resource leaks from BOFs accumulate across
   sessions.

   Cleanup checklist per BOF:
   ```
   □ Every HANDLE opened is CloseHandle'd on all code paths (success and error)
   □ Every heap allocation is freed (HeaponFree or equivalent) on all code paths
   □ BeaconPrintf(CALLBACK_OUTPUT, ...) called after all output is generated
   □ No early return that skips cleanup — use goto cleanup or RAII equivalents
   ```

5. **Compile with the correct flags for Cobalt Strike's BOF loader.**

   **MSVC (cl.exe):**
   ```bat
   cl.exe /c /GS- /TP /GL /Os bof.c /Fo bof.o
   ```
   - `/c` — compile only, no link
   - `/GS-` — disable stack cookie (cookie init requires CRT)
   - `/TP` — treat as C++ if using constexpr; omit for pure C
   - `/Os` — optimise for size

   **clang-cl (preferred for cross-compilation):**
   ```bash
   clang-cl /c /GS- /Os -target x86_64-pc-windows-msvc bof.c -o bof.o
   ```

   **Makefile target:**
   ```makefile
   bof.o: bof.c beacon.h
       clang-cl /c /GS- /Os -target x86_64-pc-windows-msvc $< -o $@
   ```

   Output must be a COFF `.o` file, not an EXE or DLL. Cobalt Strike's `inline-execute`
   expects an x64 COFF; use `inline-execute-assembly` for managed code.

## Gotchas
- `/GS-` is mandatory. With stack cookies enabled, the cookie initialisation code
  calls `__security_init_cookie()` which is a CRT function — Beacon does not have
  it, so the BOF crashes on entry.
- `DECLAREIMPORT` and `IMPORT` are macros that call `BeaconGetSpawnTo`-family
  functions under the hood. They cache function pointers — never call `IMPORT()`
  on a null module handle.
- If using C++ features (lambdas, classes), ensure no global constructors are
  generated. Global constructors are called by the CRT, not by the BOF loader.
  Static local variables with non-trivial constructors (C++ magic statics) also
  require CRT init.
- The inline `go` entry point signature must be exactly `void go(char* args, int len)`.
  Cobalt Strike's loader calls it by name after patching up relocations in the COFF.
- Fork-and-run BOFs run in a sacrificial process (`spawnto` value). The sacrificial
  process exits after the BOF returns — resource cleanup is less critical but still
  good practice for operational hygiene.
- `BeaconDataExtract` returns a pointer into the args blob, not a copy. Do not
  free it and do not write to it.

## Suggested scripts
- `bof-build.sh` — wrapper around clang-cl with the correct flags; takes a `.c`
  file and outputs a versioned `.o` in `dist/`
- `bof-validate.sh` — checks the compiled COFF for static globals, missing
  `BeaconPrintf` output calls, and open handles without matching `CloseHandle`
