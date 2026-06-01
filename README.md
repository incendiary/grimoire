# grimoire

A private library of Claude Code skills — structured, composable `SKILL.md` folders
that encode context, constraints, and scripts for recurring workflows. Skills are
organised into clusters of atomic, chainable units rather than monolithic all-in-one
prompts. New skills are promoted into this repo via the `session-skill-extractor`
meta-skill after each session.

> **Process note:** every time a skill is added or promoted, update the Skills Index
> table below. This is the single source of truth for what is in the library and what
> state it is in.

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
/tone-check
Audience: senior stakeholder
Draft: [paste draft]
```

**Implicit invocation** — describe your task and Claude recognises the trigger:
```
Check the tone of this before I send it to the CISO.
[paste draft]
```

Most skills list their trigger phrases in the `SKILL.md` description. The skill's
`README.md` includes a worked invocation example.

---

## Installation

### Install a single skill

```bash
cp -r clusters/<cluster>/<skill-name> ~/.claude/skills/
```

Example — installing `tone-check`:
```bash
cp -r clusters/02-comms/tone-check ~/.claude/skills/
```

### Install all skills at once

```bash
bash install-all.sh
```

The script copies every skill folder under `clusters/` into `~/.claude/skills/`,
skipping any that are already present (does not overwrite). Prints a summary of
what was installed and what was skipped.

For `session-skill-extractor` specifically, it also runs `install.sh` to wire
the Claude Code Stop hook, which triggers extraction at the end of every session.

### Verify installation

After installing, open a Claude Code session and check the skill loads:
```
What skills do you have loaded?
```
Claude will list the skills it has read from `~/.claude/skills/`.

---

## Workflow: from session to new skill

```
Claude Code session runs
        ↓
session-skill-extractor Stop hook fires at session end
        ↓
Transcript analysed for repeated patterns
        ↓
Proposed stubs written to ~/.claude/proposed-skills/
        ↓
Review proposed stubs
        ↓
Promote useful ones into grimoire under the appropriate cluster
        ↓
Update the Skills Index in this README
        ↓
git commit + push
        ↓
bash install-all.sh to make the new skill available
```

---

## Clusters

→ See [clusters/README.md](clusters/README.md) for the full cluster index.

1. **[01-meta](clusters/01-meta/)** — Skill management: extracting session patterns, vetting third-party skills, enforcing repo scope.
2. **[02-comms](clusters/02-comms/)** — Written communication: tone review, style rewriting, executive translation.
3. **[03-incident](clusters/03-incident/)** — Incident support: evidence collection, formal documentation, risk action plans.
4. **[04-security](clusters/04-security/)** — Domain security: iOS signing risk analysis.
5. **[05-technical](clusters/05-technical/)** — Coding conventions: PE binary parsing.
6. **[06-study](clusters/06-study/)** — Study discipline: structured burst sessions, material triage.
7. **[07-devops](clusters/07-devops/)** — Dev workflow: CI templates, repo publication, history wiping, secret scanning.
8. **[08-offsec](clusters/08-offsec/)** — Offensive development: shellcode, BOFs, process injection, EDR iteration, C2 integration.

---

## Skills Index

> **Status key:** ✅ implemented/complete · 📋 promoted (content from extraction, needs expansion) · 🔲 stub

| Cluster | Skill | Status | Source |
|---------|-------|--------|--------|
| 01-meta | `session-skill-extractor` | ✅ implemented | — |
| 01-meta | `skill-vetter` | ✅ complete | — |
| 01-meta | `github-authored-repos` | ✅ complete | archive session, 2026-05-24 |
| 02-comms | `tone-check` | ✅ complete | — |
| 02-comms | `human-rewrite` | ✅ complete | — |
| 02-comms | `executive-translate` | ✅ complete | — |
| 03-incident | `incident-ask-builder` | ✅ complete | — |
| 03-incident | `incident-appendix` | ✅ complete | — |
| 03-incident | `risk-to-action` | ✅ complete | — |
| 04-security | `ios-signing-risk` | ✅ complete | — |
| 05-technical | `pe-binary-analysis` | ✅ complete | — |
| 06-study | `study-burst-runner` | ✅ complete | — |
| 06-study | `source-material-triage` | ✅ complete | — |
| 07-devops | `repo-compass` | ✅ complete | — |
| 07-devops | `repo-publication-prep` | ✅ complete | — |
| 07-devops | `github-history-wipe` | ✅ complete | — |
| 07-devops | `repo-security-bootstrap` | 📋 promoted | PycharmProjects session, 2026-05-24 |
| 07-devops | `python-ci-template` | 📋 promoted | archive session, 2026-05-24 |
| 07-devops | `dotnet-ci-template` | 📋 promoted | archive session, 2026-05-24 |
| 01-meta | `test-before-asking` | ✅ complete | — |
| 01-meta | `cwd-verification` | ✅ complete | — |
| 01-meta | `verify-code-version` | ✅ complete | — |
| 01-meta | `mid-task-checkin` | ✅ complete | — |
| 07-devops | `python-ci-lint-precheck` | ✅ complete | — |
| 07-devops | `format-before-commit` | ✅ complete | — |
| 07-devops | `portfolio-readme-generator` | ✅ complete | — |
| 07-devops | `pre-commit-aware-commits` | ✅ complete | — |
| 07-devops | `github-release-workflow` | ✅ complete | — |
| 07-devops | `git-push-protocol-handler` | ✅ complete | — |
| 07-devops | `roadmap-sync` | ✅ complete | — |
| 07-devops | `terraform-checkov-skips` | ✅ complete | — |
| 07-devops | `terraform-aws-syntax` | ✅ complete | — |
| 07-devops | `terraform-version-compat` | ✅ complete | — |
| 07-devops | `project-delivery-workflow` | ✅ complete | — |
| 08-offsec | `shellcode-dev-conventions` | ✅ complete | ODPC, 2026-05-24 |
| 08-offsec | `api-hashing-conventions` | ✅ complete | ODPC, 2026-05-24 |
| 08-offsec | `process-injection-taxonomy` | ✅ complete | ODPC, 2026-05-24 |
| 08-offsec | `edr-test-loop` | ✅ complete | ODPC, 2026-05-24 |
| 08-offsec | `bof-dev-conventions` | ✅ complete | ODPC, 2026-05-24 |
| 08-offsec | `c2-integration-checklist` | ✅ complete | ODPC, 2026-05-24 |

---

## Note

This repository is **private**.
