# portfolio-readme-generator

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Generates consistent, professional README files for security tooling and research repos.
Enforces a fixed section order, reads the code before writing, and always includes the
authorised-use disclaimer for offensive tools. Calibrated to the quality bar set by
Phosphor, Slice-N-Dice, and DNSResolver.

---

## What this skill does

Reads the actual repo code first, then produces a README with a fixed structure:
description → features (only what exists) → requirements → installation → usage →
roadmap → disclaimer → licence. Applies British English and human-rewrite style rules.

The authorised-use disclaimer is mandatory for all security tools — no exceptions.

---

## When to use it

- A repo has no README or only a placeholder
- A repo's existing README is inaccurate or incomplete
- You are preparing a repo for portfolio publication and it needs a consistent look

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/portfolio-readme-generator ~/.claude/skills/
```

---

## How to invoke it in a session

```
/portfolio-readme-generator
Repo: CLion-nova-bof-template
Type: security tool (BOF development)
Status: working
```

Or inline:

```
Write a README for this repo. It's a DNS resolver tool for finding dangling CNAME records.
[paste or point to the code]
```

---

## Disclaimer template

Always included for security tooling:

> This tool is intended for use in authorised security assessments, research, and
> educational purposes only. Usage against systems you do not own or have explicit
> written permission to test is illegal. The author assumes no liability for misuse.

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Add README linter to check structure compliance post-generation
- [ ] Add per-language examples (Python CLI, C# Windows tool, C++ BOF)
- [ ] Test on 5 repos
- [ ] Ship: copy to `~/.claude/skills/portfolio-readme-generator/`
