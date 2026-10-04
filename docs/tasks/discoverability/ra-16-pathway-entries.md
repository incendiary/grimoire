# Task RA-16: Pathway sections in entry skills

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: RA-15
> Effort: S
> Touches: `SKILL.md` of `orient`, `plan`, `release`, `publish`, and of each step skill listed below; `CHANGELOG.md`

## Objective
Each pathway's entry skill (the bare prefix) begins with its ordered steps, and each step
skill states which pathway and step it belongs to, so a sequence is recognisable by name.

## Background
- Owner's concern: granular skills used in sequence should be recognisable as a sequence.
  The prefix groups them in autocomplete; this task makes the order explicit.
- Pathways (use exactly these orders):
  - `orient`: `orient` (checks) → `orient-repo-state` (true state) → `orient-branches` (if
    branches are scattered) → `orient-morning-run` (routine upkeep, multi-repo) →
    `orient-authored-repos` (scope multi-repo work to authored repos).
  - `plan`: `plan` (route) → `plan-spec` (criteria) → `plan-decompose` (split) →
    `plan-model-tier` (choose models) → [work] → `plan-verify` (evaluate). Side branches:
    `plan-handoff` (context full), `plan-environment` (workspace setup).
  - `release`: `release` (issue → PR → CI → merge → tag → release) → `release-readme-pin`
    → `release-docker-ghcr` (if the repo ships an image) → `roadmap-sync`.
  - `publish`: `publish` (audit, decide on history) → `publish-history-wipe` (only if
    history is dirty) → `publish-secret-scan` → `ci-local --sync` → `publish-readme`.

## Steps
1. In each entry skill's `SKILL.md`, insert immediately after the
   `> **Status/Cluster/Type**` blockquote:
   ```
   ## Pathway

   | Step | Skill | When |
   |---|---|---|
   | 1 | `orient` | ... |
   ```
   using the orders above, one row per step, "When" in at most 10 words.
2. In each step skill's `SKILL.md` (not the entry), insert after the blockquote one line:
   `> **Pathway:** <prefix>, step <N> (see \`<prefix>\`)`. Side branches use `side branch` instead of `step <N>`.
3. In each entry skill's frontmatter description, ensure it ends with
   `Entry point of the <prefix> pathway.` (edit only by appending; keep under 1024 characters).
4. `CHANGELOG.md` → `### Added`: `- Pathway tables in orient, plan, release and publish entry skills.`

## Done when
- [ ] `grep -l '^## Pathway' clusters/*/*/SKILL.md` lists exactly the four entry skills.
- [ ] `grep -c '> \*\*Pathway:\*\*' ` across the step skills equals the number of non-entry rows in the four tables.
- [ ] `bash scripts/check-frontmatter.sh` and `bash scripts/check-discoverability.sh` pass.

## Return signal
Commit message: `docs: pathway tables in entry skills`
Then follow Shared conventions step 7.
