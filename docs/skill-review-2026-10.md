# Skill review, 2026-10-13

Question asked of each skill: does it earn its place, or did it creep in (by mistake, a
weaker model, or the session-skill-extractor)? Every SKILL.md and script was read.
Result: 41 skills to 33. Two root causes of creep are fixed, not just their output.

## Root causes (fix first)

| # | Cause | Fix |
|---|---|---|
| R1 | `session-skill-extractor` runs on every session end and writes a stub for any pattern seen twice in one session: 1,788 stubs in `~/.claude/proposed-skills` since May (about 60 a week). Five current skills came from it. | On demand only (remove the Stop hook). Stub bar: 3+ occurrences, not already covered by a skill or memory. Each run counts the queue; at 20+ stubs it stops adding and opens a review with the owner instead. After the review, stubs are archived. |
| R2 | `roadmap-sync` step 3, "Add new planned items", invents roadmap entries. This is where items like "Test on 3 real repos" came from. | Delete step 3. Ticking and removing only. |
| R3 | 7 scripts in 6 skills use bash 4 (`mapfile`, `readarray`, `declare -A`). CI runs bash 5 so they pass there, but they fail on macOS's default bash 3.2. | Rewrite those lines for bash 3.2; add a CI grep that rejects bash-4-only builtins. |
| R4 | Three planning skills repeat an unsourced claim ("2-3x quality per invocation", attributed to a misspelled "Boris Chernsey"). | Delete the claim. |

## Per-skill plan

| Skill | Verdict | Why | Action |
|---|---|---|---|
| orient | Keep | Most-used session start | None |
| orient-branches | Keep, fix | Real workflow | bash 3.2 fix (R3) |
| orient-morning-run | Keep, change | Used 13x; but auto-merges Dependabot PRs by default | Report-only by default; merge only with `--merge` |
| orient-authored-repos | **Remove** | Hard-coded, stale list of 18 repos; one `gh` command does it; breaks on bash 3.2 | Replace with 4 lines in global CLAUDE.md "Repository scope" |
| plan | Keep, trim | Entry point; pathway table now does the routing | Delete layer summaries and R4 claim |
| plan-spec | Keep | Real method, used | None |
| plan-verify | Keep, fix | Real method | Delete R4 claim |
| plan-decompose | Keep, absorb | Same task-file format as plan-handoff | Absorb plan-handoff as a "mid-task handoff" section |
| plan-handoff | **Merge** into plan-decompose | Same output format; only the trigger differs | As above |
| plan-model-tier | Keep | Used for this programme's briefs | None |
| plan-environment | **Remove** | Generic workspace advice; `/init` and your CLAUDE.md policy cover it; references stale `/loadout/` path | Delete |
| roadmap | Keep, absorb | Picks next item | Absorb roadmap-deliver as "work the whole roadmap" mode; drop manual version bumps |
| roadmap-deliver | **Merge** into roadmap | Overlaps roadmap + release; prescribes manual major bumps that contradict release-please | As above |
| roadmap-sync | Keep, fix | Ticks items after merge | R2 |
| grimoire-find | **Remove** | Keyword scorer; frontmatter descriptions, `/` autocomplete and SKILLS.md now do this better | Delete; drop its MCP tool |
| session-skill-extractor | Keep, redesign | Idea is sound; volume is the problem | R1 |
| review-skill | Keep | Third-party skill vetting has real security value | None |
| review-codebase | Keep | Used heavily | None |
| review-ui | Keep | Used 2x | None (revisit in RA-23) |
| review-ios-signing | **Archive** (owner, 2026-10-13) | Built around one revocation scenario | Move to `archive/` |
| write-tone, write-human, write-exec | **Merge** into `write` | One job (improve a draft) in three modes; always used in sequence | One skill with tone / humanise / exec modes |
| incident-asks, incident-appendix, incident-risk-plan | Keep | Three different documents at different times | None |
| ci-local | Keep | Core | None |
| ci-python, ci-dotnet | Keep | Templates you reuse | None |
| ci-standards | Keep, update | Your standard | State release-please as the default versioning practice |
| ci-tests | **Remove** | Generic test-framework advice Claude already knows; never used | Delete |
| py-lint | Keep, fix | Core | R3 (`--staged` path) |
| deps-integrity | Keep, fix | Supply-chain checks | R3 |
| tf-guardrails | Keep, fix | Hard-won Terraform gotchas | R3 |
| release | Keep, **rewrite** | Prescribes manual version bump and tag, which release-please replaced | Rewrite: "merge the release-please PR; if absent, set release-please up" |
| release-readme-pin | Keep, fix | Real need | R3 (both scripts) |
| release-docker-ghcr | Keep | Niche but real, with tests | None |
| publish, publish-history-wipe, publish-secret-scan, publish-readme | Keep | The publish pathway | None |

Totals: 4 removed, 1 archived, 6 merged into 3. 41 to 32 skills.

## What the 1,788 stubs say

Grouped by theme, with recurrence across distinct days (a theme recurring over many days
is signal; one noisy session is not).

| Theme | Stubs | Days | Verdict |
|---|---|---|---|
| Agent delegation, briefs, dispatch, verification | 250 | 46 | **Gap.** Add a "dispatch" section to `plan-decompose`, generalised from this programme's runbook: brief format, model tier, worktrees, verify-not-trust, escalation, integration. |
| macOS / local toolchain (bash 3.2, nvm Node, pyenv, PATH) | 184 | 35 | **Gap.** Add a toolchain preflight to `orient` (bash, Node vs `engines`, Python modules a repo's CI needs); add "scripts must run on bash 3.2" to global CLAUDE.md. |
| Accepted CVEs, expected-red audits | ~20 | ~15 | **Small gap.** Add an "accepted advisories" section to `deps-integrity` (per-CVE, documented, re-checked on upstream release). |
| PR, branch, merge, release loops | 578 | 48 | Covered: `release`, `roadmap`, `orient-branches`, project CLAUDE.md delivery loop. |
| CI gates, status polling | 188 | 53 | Covered: `ci-local`; CI watching is a Claude Code feature (PR monitor). |
| Roadmap add/edit | 83 | 31 | Covered, and partly the R2 creep itself. |
| Context, handoff, session state | 49 | 25 | Covered: `plan-decompose`, Claude Code compaction and memory. |
| Project-specific (grimoire, Chorus, RubricAI, HopStock) | 166 | 32 | Belongs in those repos' CLAUDE.md, not skills. |
| Skill scaffolding, MCP, docs, misc | 257 | 51 | Noise or covered (`skill-creator`, one-offs). |

After this review the 1,798 stubs were moved to the macOS Trash
(`~/.Trash/proposed-skills-2026-10-13`); empty the Trash to finish.

## Work items

Status lives in `ROADMAP.md` ("Skill review programme"). Each item is one PR.

### SR-1: Stop the creep (extractor on demand; no invented roadmap items)
- `session-skill-extractor` becomes `grimoire-extract` and runs only when invoked: delete
  `install.sh` and `scripts/stop_hook.sh`, drop the install-all.sh hook wiring, and remove
  the Stop hook from `~/.claude/settings.json` (owner-approved). This also stops a paid
  model call at every session end.
- Bar for a stub: 3+ occurrences (`min_pattern_count` 3), and not already covered by an
  existing skill (check `SKILLS.md`) or memory.
- Queue review: `generate_stubs.py` counts existing stubs; at 20+ it writes nothing and
  prints `REVIEW DUE`. The skill then runs a review with the owner: aggregate by theme and
  recurrence (as in this document), turn real gaps into roadmap items, and move the stubs
  to the Trash.
- `roadmap-sync`: delete "add new planned items". It ticks and removes only.
- Done when: no Stop hook in settings; a run with 20 fake stubs prints `REVIEW DUE` and
  writes nothing; install test passes.

### SR-2: Removals and merges
- Remove `orient-authored-repos` (replace with 4 lines in global CLAUDE.md "Repository
  scope": `gh repo list incendiary --source --no-archived --limit 200 --json name -q '.[].name'`
  plus an exclusion list), `grimoire-find` (and its MCP tool), `plan-environment`, `ci-tests`.
- Archive `review-ios-signing` to `archive/review-ios-signing/` (excluded from install).
- Merge `write-tone`, `write-human`, `write-exec` into `write` (three modes); `plan-handoff`
  into `plan-decompose`; `roadmap-deliver` into `roadmap` (drop manual version bumps).
- Done when: 32 skills; all old names in `renamed-skills.txt`; frontmatter and catalogue checks pass.

### SR-3: Bash 3.2 compatibility
- Replace `mapfile`/`readarray`/`declare -A` in: `py-lint/lint-gate.sh`,
  `tf-guardrails/check-provider-compat.sh`, `release-readme-pin/check_readme_version.sh`
  and `pin_readme_version.sh`, `deps-integrity/check-lockfile-integrity.sh`,
  `orient-branches/branch-surface-resolve.sh`.
- Add a `validate.yml` step failing on those builtins in any `*.sh`.
- Done when: each script runs under `/bin/bash` 3.2 on macOS.

### SR-4: Align with how you actually work
- `release`: rewrite around release-please (merge the standing release PR; if the repo has
  none, set release-please up). Drop manual version bumps and tagging.
- `ci-standards`: state release-please as the default versioning practice.
- `orient-morning-run`: report-only by default; merge Dependabot PRs only with `--merge`.
- Delete the unsourced "2-3x quality" claim from `plan`, `plan-verify`, `plan-environment`.

### SR-5: Agent dispatch in `plan-decompose` (gap: 250 stubs, 46 days)
Generalise `docs/tasks/discoverability/00-runbook.md` into a "Dispatching to agents"
section: brief header fields (Model, Fallback, Depends on, Touches, Done when); model tier
rule (haiku only when every judgement is pre-made in the brief); one worktree per agent;
master re-runs every Done-when check (never trusts a summary); escalation ladder; serial
integration with conflict rules (union CHANGELOG, regenerate generated files); and a
usage note (prefer doing small tasks directly over spawning agents).
Done when: a fresh session can run a multi-task plan from the skill alone.

### SR-6: Toolchain preflight in `orient` (gap: 184 stubs, 35 days)
- `orient` gains a short check: `bash --version` (warn when scripts need bash 4),
  `node -v` against `package.json` `engines` and `.nvmrc`, Python modules the repo's CI
  needs (for example PyYAML for `ci-local`), and broken shims (`pyenv` pointing at a missing binary).
- Global CLAUDE.md: "Shell scripts must run on macOS /bin/bash 3.2."
- Done when: on this Mac, orient flags Node 16 and the broken pyenv shim.

### SR-7: Accepted advisories in `deps-integrity` (gap: about 20 stubs)
- A "Known, accepted advisories" section: record each accepted CVE in `SECURITY.md` (or
  `.github/accepted-advisories.md`) with ID, reason no fix exists, owner, and re-check
  trigger (upstream release); suppress per ID, never blanket; treat "expected red" CI only
  when it matches a recorded entry.
- Done when: the section exists with a template, and the npm check prints accepted IDs
  separately from new findings.

