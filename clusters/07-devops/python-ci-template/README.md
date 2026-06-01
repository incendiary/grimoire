# python-ci-template

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Standardised Python CI workflow (ruff + black + pytest-cov + secret scan).
Extracted from a session where the same workflow was written from scratch for 8 repos.

## Roadmap

- [x] Extracted from archive session (8x repetition — htb-canvas, Slice-N-Dice, bgp_rogue, burps, others)
- [x] Promoted to `clusters/07-devops/python-ci-template/`
- [x] Add `check-ci-ready.sh` script (local lint before push — mirrors CI lint job exactly)
- [x] Add `ci-no-tests.yml` variant for projects without a test suite
- [x] Add `ci-requirements-only.yml` variant for `requirements.txt`-only projects
- [x] Document Jython exception with minimal Jython-compatible CI template
- [ ] Test on one new repo (requires real session)
- [ ] Document any new gotchas from real usage (requires real session)
- [ ] Ship: copy to `~/.claude/skills/python-ci-template/`
