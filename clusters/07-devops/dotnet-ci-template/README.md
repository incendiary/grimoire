# dotnet-ci-template

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Standardised .NET CI workflow (build + test matrix + format check + secret scan).
Extracted from a session where the same workflow was written from scratch for 5 repos.

## Roadmap

- [x] Extracted from archive session (5x — WindowsServiceTemplate, QueuserAPC, IncendiaryService, EarlyWorm, csharp-shellcode-runner)
- [x] Promoted to `clusters/07-devops/dotnet-ci-template/`
- [x] Add `format-check.sh` script (local dotnet format; auto-detects .sln or .csproj)
- [x] Add `ci-cross-platform.yml` variant (`ubuntu-latest` for library projects)
- [x] Add `ci-windows-only.yml` variant (`windows-latest` for WinAPI/BOF projects)
- [x] Document net6.0 → net8.0 upgrade path in SKILL.md
- [ ] Test on one new repo (requires real session)
- [ ] Document any new gotchas from real usage (requires real session)
- [x] Ship: copy to `~/.claude/skills/dotnet-ci-template/`
