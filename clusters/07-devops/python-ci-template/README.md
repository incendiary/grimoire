# python-ci-template

> **Cluster:** 07-devops | **Status:** promoted | **Added:** 2026-05-24

Standardised Python CI workflow (ruff + black + pytest-cov + secret scan).
Extracted from a session where the same workflow was written from scratch for 8 repos.

## Roadmap

- [x] Extracted from archive session (8x repetition — htb-canvas, Slice-N-Dice, bgp_rogue, burps, others)
- [x] Promoted to `clusters/07-devops/python-ci-template/`
- [ ] Add `check-ci-ready.sh` script (local lint before push)
- [ ] Add variant for projects without a test suite
- [ ] Add variant for `requirements.txt`-only projects (no `pyproject.toml`)
- [ ] Document Jython exception clearly
- [ ] Test on one new repo
- [ ] Document any new gotchas from real usage
- [ ] Ship: copy to `~/.claude/skills/python-ci-template/`
