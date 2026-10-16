# Roadmap

Open work only. Completed work is in `CHANGELOG.md` and git history. New items enter
this file only when the owner asks for them.

## Open items

- [ ] **RA-23: evidence-based prune** of skills with no use, once both machines have 60 days
  of transcripts (from 2026-10-08). Brief: [docs/tasks/ra-23-usage-prune.md](docs/tasks/ra-23-usage-prune.md).
  Interim snapshot in [docs/ponytail-review-2026-10-16.md](docs/ponytail-review-2026-10-16.md).
- [ ] **ci-local:** auto-fix for prettier and eslint (JS/TS projects).
- [ ] **ci-local:** pin detection for `pyproject.toml`, `poetry.lock`, and constraints files.
- [ ] **ci-local:** job dependency graph (`needs:`) and matrix expansion awareness.
- [ ] **ci-local:** cache discovered jobs to skip re-parsing on each run.
- [ ] **tf-guardrails:** known-good version matrix for frequently used module combinations.
- [ ] **plan-decompose:** for code tasks, use Serena's symbol overview to choose chunk
  boundaries (per class or module, not line counts). Python, TypeScript, and C# first.

## Completed programmes

- **Skill review (2026-10, SR-1 to SR-7):** [docs/skill-review-2026-10.md](docs/skill-review-2026-10.md).
  41 to 32 skills; extractor on demand; bash 3.2 fixes; release-please; three gap fills.
- **Discoverability and consolidation (2026-09 to 2026-10, RA-01 to RA-29):** [REVIEW.md](REVIEW.md).
  Frontmatter descriptions on every skill, pathway-prefix names, MCP tools run one
  registered script. Task briefs are in git history (removed 2026-10-16).
- **Post-programme review (RA-28):** [docs/ponytail-review-2026-10-16.md](docs/ponytail-review-2026-10-16.md).
