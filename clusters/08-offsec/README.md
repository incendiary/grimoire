# 08-offsec

Skills for offensive development workflows — shellcode, BOFs, process injection,
EDR iteration, and C2 integration. Aligned with the ODPC curriculum (White Knight Labs
Offensive Development Practitioner Certification).

Skills are built out from ODPC curriculum and engagement experience.

---

## Skills

| Skill | Status | Description |
|-------|--------|-------------|
| [shellcode-dev-conventions](shellcode-dev-conventions/) | ✅ complete | PIC shellcode rules: no globals, delta-offset, PEB walk, hash API resolution, null-byte audit |
| [api-hashing-conventions](api-hashing-conventions/) | ✅ complete | PEB/EAT walk, ROR13/DJB2/FNV-1a algorithm choice, compile-time hash generation, forwarded exports |
| [process-injection-taxonomy](process-injection-taxonomy/) | ✅ complete | Technique table by EDR visibility, privilege, reliability, and syscall strategy |
| [edr-test-loop](edr-test-loop/) | ✅ complete | Hypothesis-driven test-detect-modify-retest loop with static and dynamic fix checklists |
| [bof-dev-conventions](bof-dev-conventions/) | ✅ complete | beacon.h-only API, datap argument parsing, no globals, handle cleanup, clang-cl flags |
| [c2-integration-checklist](c2-integration-checklist/) | ✅ complete | CS/Havoc integration, sleep mask, malleable profile OPSEC, kill date, lab validation sequence |

---

## Typical chain

```
source-material-triage (06-study)
    → identify relevant technique
        → process-injection-taxonomy (select technique)
        → shellcode-dev-conventions (write payload)
        → api-hashing-conventions (resolve APIs)
        → bof-dev-conventions (if BOF delivery)
        → edr-test-loop (iterate against EDR)
        → c2-integration-checklist (deploy to C2)
```

---

## Notes

Skills in this cluster cover offensive development techniques used in authorised
red team engagements and certification lab environments. They are not operational
playbooks — they encode development conventions to keep Claude's assistance consistent
with established OPSEC and code quality standards.
