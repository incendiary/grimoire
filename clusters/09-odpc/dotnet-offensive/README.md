# dotnet-offensive

> **Cluster:** 09-odpc | **Status:** complete | **Added:** 2026-06-02

D/Invoke patterns, CsWhispers syscall stubs, and AppDomain Manager Injection for
managed C# offensive code. Maps to ODPC Chapters 35 and 36.

## Roadmap

- [x] SKILL.md written: P/Invoke vs D/Invoke comparison, minimal D/Invoke implementation, CsWhispers workflow, AppDomain Manager injection setup, combined D/Invoke + indirect syscall pattern, gotchas
- [ ] Add manual PE map helper (alternative to LoadLibrary for D/Invoke module loading)
- [ ] Add AppDomain Manager persistence via registry example
