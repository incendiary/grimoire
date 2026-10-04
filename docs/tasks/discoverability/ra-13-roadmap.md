# Task RA-13: Delete `grimoire-roadmap-status`; rename `roadmap-driver` to `roadmap`

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: RA-02
> Effort: XS
> Touches: `clusters/01-meta/grimoire-roadmap-status/` (deleted), `clusters/01-meta/roadmap-driver/` → `clusters/01-meta/roadmap/`, `mcp-server/registry.json`, `clusters/01-meta/README.md`, references, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
One skill, `roadmap`, answers both "what should I work on next" and "show roadmap status".

## Background
- `grimoire-roadmap-status` has only `SKILL.md` and `README.md`, no script. Its whole job
  is what `bash scripts/roadmap-collect.sh` already prints. It is deleted, not merged.
- `roadmap-driver` picks the next roadmap item and frames the execution chain. It becomes
  `roadmap` (prefix entry for the roadmap pathway).

## New frontmatter description (use verbatim)
`Shows roadmap status and picks the next implementation-ready item from ROADMAP.md or README roadmaps, then frames the execution chain (state, decompose, plan, verify). Use when asked 'what should I work on next', 'show roadmap status', 'what is still open', or 'pick up from the roadmap'. To tick items after a merge use roadmap-sync.`

## Steps
1. Rename and delete:
   ```bash
   git mv clusters/01-meta/roadmap-driver clusters/01-meta/roadmap
   git rm -r clusters/01-meta/grimoire-roadmap-status
   printf 'roadmap-driver\troadmap\ngrimoire-roadmap-status\troadmap\n' >> scripts/renamed-skills.txt
   ```
2. In `clusters/01-meta/roadmap/SKILL.md`: set frontmatter `name: roadmap` and the
   description above; change the `# roadmap-driver` heading to `# roadmap`; add directly
   under `## Description`:
   ```
   **Status only:** run `bash scripts/roadmap-collect.sh` (add `--json` for machine-readable output) and summarise the counts.
   ```
   In `README.md`, replace `roadmap-driver` with `roadmap` in the title and install commands.
3. `mcp-server/registry.json`: change the `roadmap-driver` entry to `"name": "roadmap"`,
   `"skill": "clusters/01-meta/roadmap/SKILL.md"`; delete the `grimoire-roadmap-status` entry.
4. Fix references:
   ```bash
   grep -rnwE 'roadmap-driver|grimoire-roadmap-status' . --exclude=CHANGELOG.md --exclude=REVIEW.md --exclude=renamed-skills.txt --exclude=discoverability-intents.md --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tasks
   ```
   Replace each with `roadmap` (merge duplicate list lines). Repeat until empty. Leave
   checked historical items in `ROADMAP.md`'s "Infrastructure roadmap" as they are only if
   the grep's `ROADMAP.md` hits are inside lines starting `- [x]`; edit everything else.
5. `CHANGELOG.md` → `### Changed`: `- roadmap-driver renamed to roadmap; grimoire-roadmap-status removed (use scripts/roadmap-collect.sh).`

## Done when
- [ ] Step 4 grep prints nothing except `- [x]` lines in `ROADMAP.md`.
- [ ] `bash scripts/check-frontmatter.sh clusters/01-meta/roadmap/SKILL.md` exits 0.
- [ ] `cd mcp-server && npm ci && npm run build && npm test` passes.
- [ ] Shared conventions step 6 checks pass.

## Return signal
Commit message: `feat!: rename roadmap-driver to roadmap, drop grimoire-roadmap-status` with footer
`BREAKING CHANGE: roadmap-driver is now roadmap; grimoire-roadmap-status is removed.`
Then follow Shared conventions step 7.
