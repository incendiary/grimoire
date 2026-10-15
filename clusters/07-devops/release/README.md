# release

> **Cluster:** 07-devops | **Status:** complete | **Reworked:** 2026-10-14 (release-please)

Cuts releases with release-please: merges the standing release PR once CI is green, which
creates the tag and GitHub release, or sets release-please up in a repo without it. See
`SKILL.md` for both paths.

---

## Invocation

```
/release
```

---

## Roadmap

- [x] Rewritten around release-please; manual bump-and-tag flow and `release.sh` removed
