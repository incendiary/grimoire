# repo-security-bootstrap

> **Cluster:** 07-devops | **Status:** promoted | **Added:** 2026-05-24

Deploys `.gitleaks.toml` and a GitHub Actions secret-scan workflow to repos in bulk.
Extracted from a session where the same two files were committed to 16 repos identically.

## Roadmap

- [x] Extracted from PycharmProjects session (16x repetition)
- [x] Promoted to `clusters/07-devops/repo-security-bootstrap/`
- [ ] Add `bootstrap-security.sh` script
- [ ] Parameterise the corporate-refs regex (load from config rather than hardcode)
- [ ] Handle archived-repo unarchive/re-archive in the script
- [ ] Test on one repo end-to-end
- [ ] Document any new gotchas from real usage
- [ ] Ship: copy to `~/.claude/skills/repo-security-bootstrap/`
