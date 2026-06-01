# 09-odpc — White Knight Labs ODPC

Chapter-mapped implementation guidance for the **Offensive Development Practitioner
Certification (ODPC)** course by White Knight Labs. Skills in this cluster are
*how-to-implement* companions to the technique reference library in `08-offsec`.

**Environment:** AWS lab — Windows Dev Box (VS, x64dbg), Cobalt Strike Team Server,
Havoc C2, target machines with CrowdStrike Falcon, Sophos, Bitdefender, Elastic,
Palo Alto Cortex, and MDE.

---

## Chapter → Skill Index

| Chapter(s) | Topic | Skills to load |
|------------|-------|---------------|
| Ch 5 | PE Primer | `pe-binary-analysis` (05-technical), `pe-resource-shellcode` |
| Ch 11 | Shellcode in .rsrc | `pe-resource-shellcode`, `shellcode-dev-conventions` |
| Ch 14–16 | Dynamic API Resolution + Hashing | `api-hashing-conventions` |
| Ch 18 | CS Profiles + BOFs | `bof-dev-conventions`, `c2-integration-checklist` |
| Ch 19 | Havoc C2 | `c2-integration-checklist` |
| Ch 20–22 | Direct/Indirect Syscalls + HalosGate | `syscall-techniques` |
| Ch 24 | Caro-Kann Injection Framework | `caro-kann-injection`, `process-injection-taxonomy` |
| Ch 29–30 | Call Stack Spoofing | `call-stack-spoofing` |
| Ch 35–36 | D/Invoke + AppDomain Injection | `dotnet-offensive` |
| Ch 39–40 | ETW + Kernel Telemetry Evasion | `etw-evasion`, `edr-test-loop` |

Skills from other clusters (08-offsec, 05-technical) cover shared foundations.
Load both when working a chapter for full context.

---

## Skills

### [odpc-lab-setup](odpc-lab-setup/) ✅ complete
Lab environment reference: AWS topology, Visual Studio project templates for each
technique type, x64dbg hook inspection workflow, and EDR configuration notes for
each defensive product in the lab.

### [pe-resource-shellcode](pe-resource-shellcode/) ✅ complete
Embedding and extracting shellcode from the PE .rsrc section using FindResource /
LoadResource / LockResource. XOR decryption patterns, allocation tradeoffs, and
behavioural rule avoidance.
→ Chapters 5, 11

### [syscall-techniques](syscall-techniques/) ✅ complete
Direct syscall MASM stubs, indirect syscall via gadget jump, and HalosGate dynamic
SSN resolution. SysWhispers3 integration and tradeoffs vs manual stubs.
→ Chapters 20, 21, 22

### [call-stack-spoofing](call-stack-spoofing/) ✅ complete
Return address patching before sleep and restore after. Synthetic frame construction
using VEH + RtlCaptureContext. What a spoofed call chain must look like to survive
EDR stack unwinding.
→ Chapters 29, 30

### [dotnet-offensive](dotnet-offensive/) ✅ complete
D/Invoke vs P/Invoke detection surface. CsWhispers for C# syscall stubs. AppDomain
Manager Injection via environment variable hijacking. Managed code + indirect syscall
combinations.
→ Chapters 35, 36

### [etw-evasion](etw-evasion/) ✅ complete
ETW architecture, user-land EtwEventWrite patching, per-provider vs global patch
tradeoffs. Kernel callback functions that cannot be patched from user-land. Verification
workflow with edr-test-loop.
→ Chapters 39, 40

### [caro-kann-injection](caro-kann-injection/) ✅ complete
Multi-stage injection: RW allocation → sleep → RX flip → callback execution. Sleep
masking rationale. Unmonitored callback vectors. Python shellcode encryptor + C++
injector project structure.
→ Chapter 24

---

## JetBrains IDE integration

For Rider / CLion sessions: install the **JetBrains MCP Server** plugin
(`github.com/JetBrains/mcp-server`). This exposes open files, selected symbols,
and build error output to Claude — enabling fix suggestions without copy/paste.
No separate Claude skill needed; it's a one-time plugin install.
