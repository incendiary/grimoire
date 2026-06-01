# call-stack-spoofing

> **Cluster:** 09-odpc | **Status:** complete | **Added:** 2026-06-02

Return address patching and synthetic frame construction to defeat EDR call stack
inspection. Maps to ODPC Chapters 29 and 30.

## Roadmap

- [x] SKILL.md written: return address patching, synthetic frame construction, thread pool call chain, integration with sleep masking, gotchas
- [ ] Add x64 unwind data reference (what .pdata entries look like for thread pool functions)
- [ ] Add worked example: before/after stack walk output for a spoofed chain
