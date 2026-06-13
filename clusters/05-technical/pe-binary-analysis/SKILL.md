# pe-binary-analysis

> **Status:** COMPLETE
> **Type:** instructional
> **Cluster:** 05-technical

## Description
Enforce manual PE structure parsing conventions during code review and development.
No WinAPI abstractions. No library wrappers. Direct struct access only.

Invoke when: the session involves PE parsing, syscall hook detection, import table
analysis, in-memory PE introspection, or any Windows binary structure work.

## Context needed
- The specific PE structure or field under analysis
- Target architecture (x64 assumed unless the user states otherwise)
- Whether the target is on-disk or in-memory (layouts differ; sections are expanded in memory)

## What to do

1. **Enforce the no-WinAPI convention on all code.** Any WinAPI helper that abstracts
   PE structure access must be replaced with direct struct access. Specific replacements:
   - `ImageNtHeader(base)` → cast `base + ((IMAGE_DOS_HEADER*)base)->e_lfanew` to
     `IMAGE_NT_HEADERS64*` (or `IMAGE_NT_HEADERS32*` — check Magic first)
   - `ImageDirectoryEntryToData()` → index `OptionalHeader.DataDirectory[]` directly
   - `ImageRvaToVa()` → implement the RVA-to-VA conversion explicitly:
     `VA = ImageBase + RVA`
   - `ImageEnumerateCertificates()` → parse the security directory entry manually
   If the user asks for code using any of these, write the direct-access version and
   comment why the WinAPI version is not used.

2. **For code review,** check every function in scope for WinAPI PE helpers and flag
   each one with the direct replacement. Do not silently rewrite — state each
   replacement explicitly so the user understands the change.

3. **For all PE-related arithmetic, be explicit about RVA vs file offset.**
   Always annotate which you are working with:
   - Comment the formula inline: `// VA = ImageBase (0x...) + RVA (0x...)`
   - When converting between RVA and file offset (via section table), show the section
     look-up step explicitly
   - Never hide this in a helper function without showing the formula in comments

4. **For syscall hook detection,** compare the first N bytes of the function stub
   against the expected clean syscall pattern. Do not use any API to determine if a
   function is hooked. The comparison must be byte-by-byte against the expected stub.

5. **For struct field references in comments and documentation,** always use the
   fully qualified path: `IMAGE_NT_HEADERS64.OptionalHeader.SizeOfImage`, not
   just `SizeOfImage`.

## Gotchas
- RVA vs file offset confusion is the most common error in PE parsing. They are not
  interchangeable. Section data in the file is at a file offset; section data in
  memory is at an RVA from the image base. Always be explicit about which you are
  using, and show the conversion when it happens.
- In-memory PE layouts differ from on-disk layouts. Sections are expanded to their
  virtual size in memory. If the user does not specify, ask whether the target is
  on-disk or in-memory before writing parsing code.
- x86 and x64 use different optional header structures: `IMAGE_OPTIONAL_HEADER32` vs
  `IMAGE_OPTIONAL_HEADER64`. Never assume x64. Check the Magic field
  (`0x10B` = PE32, `0x20B` = PE32+) before proceeding.
- x64 PE files can still be 32-bit subsystem. `Machine` field in the file header
  (`IMAGE_FILE_MACHINE_AMD64` vs `IMAGE_FILE_MACHINE_I386`) is the definitive check.

## Suggested scripts
- None — this is a code convention skill; the rules are applied inline during development
