# portfolio-readme-generator

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Generate professional README files for security tooling and research repos using a
consistent structure. Inspired by Phosphor, Slice-N-Dice, and DNSResolver as reference
quality bars.

Invoke when: a repo needs a README or its existing README is a placeholder. Trigger
phrases: "write a README for this", "generate the README", "this repo needs docs".

## Context needed
- The repo name and purpose (read the code if not described)
- Whether it is a security tool (requires authorised-use disclaimer)
- Whether it has a CLI, library interface, or both
- Current status: working, alpha, research/PoC, archived

## What to do

1. **Read the actual code before writing a single word.** Do not generate a README
   from the repo name alone. Read `main.py`, `__init__.py`, the entry point, and any
   existing docs. A README generated without reading the code will be inaccurate.
   For C# or C++ projects: read the primary `.cs` / `.cpp` file and the solution structure.

2. **Follow this section structure in order:**
   ```
   # Repo Name
   [Badges: CI status, language, license — only include if the CI/badge exists]

   One-sentence description. What it does, not what it is.

   ## Features
   Bullet list. Concrete, not aspirational. Only list features that exist.

   ## Requirements
   OS, runtime version, dependencies. Be specific.

   ## Installation
   Step-by-step. Test the steps mentally — do not include steps that would fail.

   ## Usage
   The minimal working example first. Then flags/options.

   ## Roadmap
   What is planned. Use checkboxes: checked = done, unchecked = planned.

   ## Disclaimer
   [See authorised-use disclaimer below]

   ## Licence
   ```

3. **Apply the authorised-use disclaimer for any security tooling:**
   ```
   ## Disclaimer
   This tool is intended for use in authorised security assessments, research,
   and educational purposes only. Usage against systems you do not own or have
   explicit written permission to test is illegal. The author assumes no liability
   for misuse. Users are solely responsible for ensuring compliance with applicable
   laws and regulations.
   ```
   This is non-negotiable for offensive tools. Do not omit it.

4. **Apply `human-rewrite` style rules** to the full output: British English, active
   voice, no corporate filler.

## Gotchas
- Do not include features that do not yet exist. Check the code before listing anything.
- Do not include CI badges if CI does not exist for the repo — a failing badge is worse
  than no badge.
- Empty stubs (repos with only a README placeholder and no real code) get a minimal
  README: name, one-sentence intent, "work in progress" status note. Do not fabricate
  a feature list.
- All security tools get the disclaimer. This includes PoC research tools and BOF templates.

## Suggested scripts
- None — this is a writing skill, no scripts needed
