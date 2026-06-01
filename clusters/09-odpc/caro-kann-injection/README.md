# caro-kann-injection

> **Cluster:** 09-odpc | **Status:** complete | **Added:** 2026-06-02

Multi-stage injection: RW alloc → sleep masking → RX flip → callback execution.
Integrates ETW patching and call stack spoofing. Maps to ODPC Chapter 24.

## Roadmap

- [x] SKILL.md written: Python encryptor, C++ injector skeleton, callback vector table, sleep masking integration, project structure, gotchas
- [ ] Add QueueUserAPC variant (alertable wait pattern)
- [ ] Add heap encryption for the sleep masking window
