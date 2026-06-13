# clusters/

This directory contains all skills organised into thematic clusters. Each cluster is a
folder with its own README describing the skills inside it.

---

## How Claude Code skills work

A Claude Code skill is a folder containing a `SKILL.md` file. When that folder lives
in `~/.claude/skills/`, Claude Code reads it and applies the instructions it contains
for the duration of the session.

**Skills are not commands you type — they are context that gets loaded.** The `SKILL.md`
describes when the skill should activate, what context Claude needs, and what it should
do. Once installed, Claude recognises the trigger conditions and applies the skill
without you re-explaining the rules each time.

### How to invoke a skill

After installing a skill, you can invoke it in two ways:

**Explicit invocation** — reference the skill by name:
```
/repo-compass
Repo: incendiary/DNSResolver
```

**Implicit invocation** — describe your task and Claude recognises the trigger:
```
What's still outstanding on DNSResolver? Give me the full picture.
```

Most skills list their trigger phrases in the `SKILL.md` description. The skill's
`README.md` includes a worked invocation example.

---

## Cluster index

| # | Cluster | Purpose |
|---|---------|---------|
| 01 | [meta](01-meta/) | Skill management: building, vetting, and maintaining the grimoire library itself |
| 02 | [comms](02-comms/) | Written communication: tone review, style rewriting, executive translation |
| 03 | [incident](03-incident/) | Security incident support: evidence collection, documentation, risk planning |
| 04 | [security](04-security/) | Domain-specific security: iOS signing risk analysis |
| 05 | [technical](05-technical/) | Coding conventions: PE binary parsing, test bootstrapping |
| 06 | [study](06-study/) | Study discipline: structured burst sessions, material triage, YouTube curation |
| 07 | [devops](07-devops/) | Dev workflow: CI templates, repo publication prep, history wiping, secret scanning |
| 08 | [offsec](08-offsec/) | Offensive development: shellcode, BOFs, process injection, EDR iteration, C2 integration |
| 09 | [odpc](09-odpc/) | White Knight Labs ODPC: chapter-mapped implementation guides for syscalls, ETW evasion, call stack spoofing, .NET offensive, and Caro-Kann injection |

---

## Adding a new cluster

1. Create a folder with the next available number prefix: `10-name/`
2. Add a `README.md` in the new folder following the format in any existing cluster README
3. Update this index table
4. Update the main `README.md` skills index
