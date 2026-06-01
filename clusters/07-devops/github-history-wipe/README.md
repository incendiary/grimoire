# github-history-wipe

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Automates the fresh `git init` workflow for wiping history before public release.
Extracted from a session where the same 9-step procedure was repeated verbatim 16 times.

## Roadmap

- [x] Extracted from PycharmProjects session (16x repetition)
- [x] Promoted to `clusters/07-devops/github-history-wipe/`
- [x] Add `capture-releases.sh` script
- [x] Add `recreate-releases.sh` script
- [x] Handle archived-repo unarchive/re-archive automatically
- [x] Add author email override to the commit step
- [ ] Test on one repo end-to-end (requires real session)
- [ ] Document any new gotchas from real usage (requires real session)
- [ ] Ship: copy to `~/.claude/skills/github-history-wipe/`
