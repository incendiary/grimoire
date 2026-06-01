# dotnet-ci-template

> **Cluster:** 07-devops | **Status:** promoted | **Added:** 2026-05-24

Standardised .NET CI workflow (build + test matrix + format check + secret scan).
Extracted from a session where the same workflow was written from scratch for 5 repos.

## Roadmap

- [x] Extracted from archive session (5x — WindowsServiceTemplate, QueuserAPC, IncendiaryService, EarlyWorm, csharp-shellcode-runner)
- [x] Promoted to `clusters/07-devops/dotnet-ci-template/`
- [ ] Add `format-check.sh` script (local dotnet format before push)
- [ ] Add cross-platform variant (`ubuntu-latest` for library projects)
- [ ] Add Windows-only variant (`windows-latest` for WinAPI/BOF projects)
- [ ] Flag net6.0 → net8.0 upgrade path
- [ ] Test on one new repo
- [ ] Document any new gotchas from real usage
- [ ] Ship: copy to `~/.claude/skills/dotnet-ci-template/`
