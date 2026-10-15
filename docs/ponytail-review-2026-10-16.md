# Ponytail review 2026-10-16

RA-28: post-programme debt ledger and over-engineering audit, after the discoverability
programme (RA-01 to RA-29) and the skill review (SR-1 to SR-7).

## Debt ledger

No `ponytail:` debt. Clean ledger. (The only hit is the example inside the RA-28 brief.)

## Audit

Ranked, biggest cut first. Code is lean after the programme; the remaining weight is
duplicated documentation.

1. `yagni` Per-skill `README.md` files: 3,131 lines duplicating each `SKILL.md`. Their only
   machine use is the `## Roadmap` sections that `roadmap-collect.sh` scrapes (9 open items
   left). Replacement: delete them, keep the 9 items directly in `ROADMAP.md`, and drop
   `roadmap-collect.sh`, `check-roadmap-sync.sh`, its pre-commit hook and its
   `devops-check.yml` step. `SKILLS.md` already gives the browsable index. [clusters/*/*/README.md]
2. `delete` Cluster READMEs: 721 hand-kept lines of indexes and workflow diagrams that
   `SKILLS.md` and the pathway tables now cover, and that went stale during this programme.
   [clusters/*/README.md, clusters/README.md]
3. `delete` Finished task briefs: 1,984 lines in `docs/tasks/discoverability/` once RA-23
   closes. The useful part (dispatch protocol) now lives in `plan-decompose`; the briefs stay
   in git history. [docs/tasks/discoverability/]
4. `yagni` Confidence-heuristic knobs in `grimoire-extract` (`confidence_base`,
   `confidence_weight_*`, `min_confidence`): documented as uncalibrated and never tuned.
   Replacement: rank by `occurring_sessions` then `count`, which the script already sorts on.
   [clusters/01-meta/grimoire-extract/config.json, scripts/extract_patterns.py]
5. `delete` Guard for a missing `clusters/` directory and the rename-cycle protection in
   `scripts/usage-report.py` (carried over from the wave 1 review). [scripts/usage-report.py]
6. `delete` Redundant `mkdir -p "${BACKUP_ROOT}"` in the retired-skills block. [install-all.sh]

net: about -6,000 lines possible, 0 deps. Items 1 to 3 change repo conventions (CLAUDE.md
requires a README per skill), so they need the owner's decision.

## Suggested next tasks

- RA-30 candidate: drop per-skill and cluster READMEs; roadmap items live in `ROADMAP.md` (sonnet, M)
- RA-31 candidate: delete finished discoverability briefs after RA-23 (haiku, XS)
- RA-32 candidate: items 4 to 6 above (haiku, XS)

## RA-23 interim snapshot (this Mac only, 2026-05-09 to 2026-10-15)

19 of 32 skills show no recorded use. Most are rare by nature (incident, publish,
release-time skills) or new under their current names. Not enough for a prune decision:
RA-23 stays open until both machines have 60 days of transcripts (from 2026-10-08).
