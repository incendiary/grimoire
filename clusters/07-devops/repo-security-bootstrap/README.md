# repo-security-bootstrap

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Deploys `.gitleaks.toml` and a GitHub Actions secret-scan workflow to repos in bulk.
Extracted from a session where the same two files were committed to 16 repos identically.

## Roadmap

- [x] Extracted from PycharmProjects session (16x repetition)
- [x] Promoted to `clusters/07-devops/repo-security-bootstrap/`
- [x] Add `bootstrap-security.sh` script (handles unarchive/re-archive automatically)
- [x] Add `gitleaks-config-template.toml` with parameterised corporate-refs placeholders
- [x] Handle archived-repo unarchive/re-archive in the script
- [ ] Test on one repo end-to-end (requires real session)
- [ ] Document any new gotchas from real usage (requires real session)
- [x] Ship: copy to `~/.claude/skills/repo-security-bootstrap/`
