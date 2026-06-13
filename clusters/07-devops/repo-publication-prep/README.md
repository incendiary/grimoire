# repo-publication-prep

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

End-to-end checklist for preparing a private repo for public release: file-size audit,
history sanitisation decision, and language-appropriate pre-commit wiring.

Consolidated from three session-extracted stubs: `precommit-bootstrap` (×7),
`repo-publication-prep` (×2), and `github-repo-prep` (×3).

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/repo-publication-prep ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#repo-publication-prep
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.

## Roadmap

- [x] Extracted from PycharmProjects, DNSResolver, and StudySaurus sessions
- [x] Merged into single skill and promoted to `clusters/07-devops/repo-publication-prep/`
- [x] Add `find-large-files.sh` script
- [x] Add `audit_history.sh` script
- [x] Add `detect-language.sh` script
- [x] Expand pre-commit hook version pinning section
- [ ] Test end-to-end on one new repo (requires real session)
- [ ] Document any new gotchas from real usage (requires real usage)
- [x] Ship: copy to `~/.claude/skills/repo-publication-prep/`
