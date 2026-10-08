# Task RA-28: Post-programme ponytail-debt ledger and audit re-run

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: RA-17 (all implementation tasks done)
> Effort: S
> Touches: `docs/ponytail-review-<YYYY-MM-DD>.md` (new), `CHANGELOG.md`

## Objective
One report of (a) every deliberate shortcut agents marked with a `ponytail:` comment
during the programme, and (b) a fresh over-engineering audit of the repo as it now stands.
The owner decides what to act on; this task changes no code.

## Background
- Agents executing the earlier briefs may have taken deliberate shortcuts and marked them
  `# ponytail: <ceiling>, <upgrade path>`. Unlisted, those become permanent.
- The first audit (2026-10-04, recorded in `REVIEW.md` under "Over-engineering audit")
  shaped this programme. The repo has changed a lot since (41 skills, new scripts), so it
  needs a second pass.
- Both are skills from the owner's `ponytail` plugin: `ponytail:ponytail-debt` and
  `ponytail:ponytail-audit`. Use the Skill tool if you have it. If not, read their
  instructions at `~/.claude/plugins/cache/ponytail/ponytail/*/skills/ponytail-debt/SKILL.md`
  and `.../ponytail-audit/SKILL.md` and follow them by hand.

## Steps
1. Run `ponytail:ponytail-debt` over the repo. Keep its ledger output verbatim, including
   the `no-trigger` tags and the final count line.
2. Run `ponytail:ponytail-audit` over the repo. Keep its ranked findings and `net:` line verbatim.
3. For each audit finding, check `REVIEW.md` "Over-engineering audit (2026-10-04)": if
   it was already raised there, append `(repeat of 2026-10-04 finding)`.
4. Write `docs/ponytail-review-<today>.md`:
   ```
   # Ponytail review <date>

   ## Debt ledger
   <step 1 output>

   ## Audit
   <step 2 output, annotated per step 3>

   ## Suggested next tasks
   <for each `no-trigger` marker and each audit finding over 50 lines: one line proposing a
    task, in the form "RA-NN candidate: <imperative title> (<haiku|sonnet|opus>, <XS|S|M>)">
   ```
5. `CHANGELOG.md` → `### Added`: `- docs/ponytail-review-<date>.md: post-programme debt ledger and audit.`

## Constraints
- Report only. Do not apply any finding or edit any `ponytail:` comment.

## Done when
- [ ] The report exists with all three sections.
- [ ] `git diff --stat main` lists only the report, `CHANGELOG.md`, `ROADMAP.md`, and this task file.

## Return signal
Commit message: `docs: post-programme ponytail review`
Then follow Shared conventions step 7. In your return message, give the debt count line
and the audit `net:` line.
