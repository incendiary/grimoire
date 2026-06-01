# 05-technical — Platform context and conventions

Skills that enforce low-level coding conventions. These are loader skills — their job
is to establish grounding at session start so it does not need to be re-stated during
the session. Load one of these and the conventions apply for the rest of the session
without repetition.

---

## Skills

### [pe-binary-analysis](pe-binary-analysis/) ✅ complete
Enforces manual PE structure parsing conventions: no WinAPI abstractions, no library
wrappers, direct struct access only. Covers `ImageNtHeader`, `ImageRvaToVa`,
and `ImageDirectoryEntryToData` replacements; RVA vs file offset annotation rules;
x86/x64 Magic field checks; and syscall hook detection patterns. Load at the start of
any PE parsing or binary introspection session.
→ [Full documentation](pe-binary-analysis/README.md)

---

## Adding project-specific context skills

Platform context skills (grounding a specific project's architecture, paths, and
conventions) are inherently personal. The pattern is: create a skill folder with
a `SKILL.md` that pre-loads your platform's key facts, then load it at the start of
any relevant session. See any existing skill in this cluster for the template.
