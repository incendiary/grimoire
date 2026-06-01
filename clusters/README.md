# clusters/

This directory contains all skills organised into thematic clusters. Each cluster is a
folder with its own README describing the skills inside it.

---

## Cluster index

| # | Cluster | Purpose |
|---|---------|---------|
| 01 | [meta](01-meta/) | Skill management: building, vetting, and maintaining the loadout library itself |
| 02 | [comms](02-comms/) | Written communication: tone review, style rewriting, executive translation |
| 03 | [incident](03-incident/) | Security incident support: evidence collection, documentation, risk planning |
| 04 | [security](04-security/) | Domain-specific security: iOS signing risk analysis |
| 05 | [technical](05-technical/) | Coding conventions: PE binary parsing |
| 06 | [study](06-study/) | Study discipline: structured burst sessions, material triage |
| 07 | [devops](07-devops/) | Dev workflow: CI templates, repo publication prep, history wiping, secret scanning |
| 08 | [offsec](08-offsec/) | Offensive development: shellcode, BOFs, process injection, EDR iteration, C2 integration |

---

## Adding a new cluster

1. Create a folder with the next available number prefix: `08-name/`
2. Add a `README.md` in the new folder following the format in any existing cluster README
3. Update this index table
4. Update the main `loadout/README.md` skills index
