# github-authored-repos

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-05-24

Prevents fork/clone inclusion in multi-repo operations by enforcing the canonical
authored-repo list. Extracted after forks were incorrectly included in 3 separate operations.

## Roadmap

- [x] Extracted from archive session (3x — agency-agents, ScallOps misclassified)
- [x] Promoted to `clusters/01-meta/github-authored-repos/`
- [x] Add `list-authored.sh` script
- [x] Add fork-detection one-liner to SKILL.md examples
- [x] Set up process to keep the authored list in sync with CLAUDE.md
- [ ] Test on one multi-repo session (requires real session)
- [ ] Document any new gotchas from real usage (requires real usage)
- [x] Ship: copy to `~/.claude/skills/github-authored-repos/`
