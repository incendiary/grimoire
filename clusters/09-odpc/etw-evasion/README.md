# etw-evasion

> **Cluster:** 09-odpc | **Status:** complete | **Added:** 2026-06-02

ETW architecture, user-land EtwEventWrite patching, per-provider vs global tradeoffs,
and kernel callback limits. Maps to ODPC Chapters 39 and 40.

## Roadmap

- [x] SKILL.md written: ETW architecture, provider table, EtwEventWrite + AMSI patch, per-provider vs global, kernel callbacks reference, verification workflow, gotchas
- [x] Add per-provider patch implementation (targeting DotNETRuntime specifically)
- [x] Add ETW patch detection signatures (what memory scanners look for)
