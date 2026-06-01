# github-authored-repos

> **Status:** promoted
> **Cluster:** 01-meta
> **Source:** archive session (pattern detected 3x)

## Description
Prevents inclusion of forks and reference clones in multi-repo operations by enforcing
the canonical authored-repo list from CLAUDE.md.

Invoke when: any session that operates across multiple repos — bulk CI setup, portfolio
audit, secret scanning sweep, README generation, or similar.

## Context needed
The authoritative authored-repo list (from CLAUDE.md as of 2026-05):

```
StartingPoint, Phosphor, Slice-N-Dice, htb-canvas, IncendiaryService,
DNSResolver, CLion-nova-bof-template, WindowsServiceTemplate,
csharp-shellcode-runner, QueuserAPC, EarlyWorm, pdf2john-docker,
bgp_rogue, Implant-Practice, agency-agents, ScallOps, az-nsg, burps
```

Repos to explicitly exclude (forks/reference copies):
```
Ghostwriter, OSCE3-Notes, RTOVMSetup, AWAE-PREP, pybgpstream,
plaintextoffenders, clone-cert, my-arsenal-of-aws-security-tools,
Azurite, kerberoast, reveal.js, hashcat
```

## What to do

At the start of any multi-repo session:
1. State the scope explicitly: "Operating on authored repos only."
2. If using `gh repo list`, always filter against the authored list — do not process all repos returned by the API.
3. Before acting on a repo, verify it is in the authored list. If ambiguous, ask.

To verify a repo's fork status programmatically:
```bash
gh api repos/incendiary/<repo> --jq '.fork'
# returns true if fork, false if original
```

To list all repos and classify them in one pass:
```bash
bash list-authored.sh           # coloured terminal output
bash list-authored.sh --json    # machine-readable JSON
```

## Keeping the authored list in sync with CLAUDE.md

The authored-repo list is maintained in two places:
1. `CLAUDE.md` (user's private global instructions — source of truth)
2. `SKILL.md` and `list-authored.sh` (copied here for session use)

When a new repo is created:
1. Add it to the `Authored repos` list in `CLAUDE.md`
2. Add the same name to the `AUTHORED` array in `list-authored.sh`
3. Add it to the **Context needed** authored list in this `SKILL.md`
4. Commit the script change to `loadout`

When a session surfaces a repo not in the list (❓ from `list-authored.sh`):
- Do not include it in multi-repo operations silently
- Flag it: "This repo is not in the authored list — confirm before including"
- If the user confirms it is authored, follow the sync steps above

## Gotchas
- `gh repo list` returns all repos including forks — never process the raw list
- The authored list in CLAUDE.md may drift over time — if a session surfaces a repo not in the list, flag it for CLAUDE.md update rather than silently including or excluding it
- `agency-agents` and `ScallOps` are clones of third-party repos, not forks in the GitHub sense; they still do not belong in authored-repo operations
- When in doubt, confirm with the user before acting on an ambiguous repo

## Suggested scripts
- `list-authored.sh` — filters `gh repo list` output against the hardcoded authored list
