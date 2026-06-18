# bof-dev-conventions

> **Cluster:** 08-offsec | **Status:** complete | **Added:** 2026-05-24

Beacon Object File development conventions: `beacon.h`-only API, no static globals,
`datap` argument parsing, handle/heap cleanup on all code paths, and clang-cl / MSVC
compilation flags that produce a loadable COFF without CRT dependencies.

---

## What this skill does

Pre-loads the full set of BOF constraints before writing any BOF code. Catches the
common crashes: CRT functions, static globals, missing `/GS-`, wrong argument
parsing, and handles that leak into Beacon's long-running process memory.

---

## When to use it

- Writing a new BOF for Cobalt Strike or a compatible C2 framework
- Reviewing a BOF for correctness before deployment
- Debugging a BOF that crashes Beacon on execution

---

## Installation

### Claude Code

```bash
cp -r clusters/08-offsec/bof-dev-conventions ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#bof-dev-conventions
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

```
/bof-dev-conventions
Framework: Cobalt Strike, inline execution
Goal: process enumeration BOF, args: target PID (int), output mode (short)
```

---

## Workflow

```
Include beacon.h only (no CRT)
        ↓
Declare void go(char* args, int len)
        ↓
BeaconDataParse → extract args in pack order
        ↓
DECLAREIMPORT for every WinAPI call
        ↓
Implement logic — all state on stack or heap (no globals)
        ↓
cleanup: label — CloseHandle + HeapFree on all paths
        ↓
BeaconPrintf(CALLBACK_OUTPUT, ...) for all output
        ↓
Compile: clang-cl /c /GS- /Os → .o COFF
        ↓
inline-execute in Beacon
```

---

## Fork-and-run vs inline — OPSEC comparison

The delivery mode is an OPSEC decision, not just an execution convenience.

| | **Inline (inline-execute)** | **Fork-and-run** |
|---|---|---|
| **Execution context** | Runs inside the Beacon thread | Runs in a sacrificial process spawned by Beacon |
| **Process creation event** | None | One `CreateProcess` event (Sysmon ID 1) |
| **EDR surface** | Beacon process only | Beacon process + sacrificial process + DLL injection into it |
| **Beacon stability** | BOF crash kills Beacon | BOF crash kills only the sacrificial process |
| **Output size** | Limited by Beacon output buffer | Larger output (piped from sacrificial process) |
| **Duration** | Short — must return promptly | Long-running tasks allowed |
| **`spawnto` required** | No | Yes — must be set before use |

**Decision rules:**

Use **inline** when:
- The task is fast, reads memory or tokens, and does not make blocking calls
- The task must not be visible as a new process (e.g. token impersonation, handle enumeration)
- The BOF is well-tested and crash-safe

Use **fork-and-run** when:
- The task runs a third-party post-ex DLL or unstable code (crash isolation matters)
- The task produces large output (screenshot, keylog buffer, long scan result)
- The task takes longer than a few seconds (avoids blocking the Beacon check-in loop)
- The task uses a library that is incompatible with the no-CRT constraint of inline BOFs

**`spawnto` OPSEC note for fork-and-run:**
```
# Check and set spawnto before any fork-and-run operation:
spawnto x64 %windir%\System32\svchost.exe
# Verify it's set:
spawnto
```
`rundll32.exe` (the default) is a high-signal spawnto binary — it has few legitimate
non-system callers and is flagged by most EDRs in this context. Replace it before use.
Common lower-signal alternatives: `svchost.exe`, `dllhost.exe`, `WerFault.exe`.

---

## Makefile template

Standard Makefile for BOF projects targeting both x64 and x86. Uses LLVM/clang-cl on
Windows and mingw-w64 on Linux. Adjust `CC_WIN` path for your clang-cl installation.

```makefile
# BOF Makefile — produces x64 and x86 COFF object files
# Usage: make           → build all
#        make clean     → remove output directory
#        make x64       → build x64 only
#        make x86       → build x86 only

BOF_NAME  := mybof
SRC       := src/$(BOF_NAME).c
OUT_DIR   := dist

# Windows: LLVM clang-cl (adjust path if needed)
CC_WIN_X64 := clang-cl
CC_WIN_X86 := clang-cl

# Cross-compile from Linux: mingw-w64
CC_LINUX_X64 := x86_64-w64-mingw32-gcc
CC_LINUX_X86 := i686-w64-mingw32-gcc

# clang-cl flags (Windows builds)
CFLAGS_CL  := /c /GS- /Os /Zi-
CFLAGS_X64 := $(CFLAGS_CL) /D_WIN64
CFLAGS_X86 := $(CFLAGS_CL) /D_WIN32

# mingw flags (Linux cross-compile)
CFLAGS_GCC     := -c -O1 -fno-stack-protector -fno-asynchronous-unwind-tables
CFLAGS_GCC_X64 := $(CFLAGS_GCC) -m64
CFLAGS_GCC_X86 := $(CFLAGS_GCC) -m32

.PHONY: all x64 x86 clean

all: x64 x86

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

# Detect OS — use clang-cl on Windows, mingw on Linux
ifeq ($(OS),Windows_NT)
x64: $(OUT_DIR)
	$(CC_WIN_X64) $(CFLAGS_X64) $(SRC) /Fo$(OUT_DIR)/$(BOF_NAME).x64.o

x86: $(OUT_DIR)
	$(CC_WIN_X86) $(CFLAGS_X86) $(SRC) /Fo$(OUT_DIR)/$(BOF_NAME).x86.o
else
x64: $(OUT_DIR)
	$(CC_LINUX_X64) $(CFLAGS_GCC_X64) $(SRC) -o $(OUT_DIR)/$(BOF_NAME).x64.o

x86: $(OUT_DIR)
	$(CC_LINUX_X86) $(CFLAGS_GCC_X86) $(SRC) -o $(OUT_DIR)/$(BOF_NAME).x86.o
endif

clean:
	rm -rf $(OUT_DIR)
```

**Usage notes:**
- Output goes to `dist/` — gitignore `dist/` and commit only source.
- The `/GS-` (clang-cl) / `-fno-stack-protector` (gcc) flag is mandatory: BOFs run
  without a stack cookie handler; the CRT function the handler calls does not exist.
- `/Zi-` disables debug info — keeps output size minimal and avoids embedding source paths.
- After building, validate with `bof-validate.sh` before loading into Beacon.

---

## What it won't do

- Write the aggressor script — argument packing order is documented but not generated
- Cover managed (.NET) BOF-style assemblies (use `inline-execute-assembly`)
- Handle Havoc-specific demon module API differences (separate roadmap item)

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `bof-build.sh` (clang-cl wrapper with correct flags)
- [x] Write `bof-validate.sh` (static check for globals, missing cleanup)
- [ ] Add Havoc demon module API comparison
- [x] Add fork-and-run vs inline guidance with OPSEC notes
- [x] Add Makefile template
