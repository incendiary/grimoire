# source-material-triage

> **Cluster:** 06-study | **Status:** complete | **Added:** 2026-05-24

Takes a messy study material folder and produces a clean, syllabus-organised structure.
Classifies every file as KEEP, REVIEW, or SKIP against the target syllabus, generates a
curated folder layout, and produces a `.gitignore` snippet so junk does not come back.
Incremental by design — reruns skip already-classified files.

---

## What this skill does

Walks a directory of study material, classifies each file against a named syllabus
(CAIML, ARTOC, RTO2, or custom), and produces:

1. A curated folder structure organised by syllabus module (not original folder structure)
2. A decision for each file: KEEP (with syllabus topic), REVIEW (with reason), SKIP
3. A `.gitignore` snippet covering all junk patterns found
4. A `triage-log.json` so subsequent runs are incremental

Nothing is deleted. SKIP files are moved to `_triage-review/` for your confirmation.

---

## When to use it

- You have downloaded study material from multiple sources and need to know what to keep
- You are starting a new CAIML module and need to organise the material you have
- You want to check for duplicates before committing a study folder to git
- Any time your study folder contains ISOs, OVAs, or large videos mixed in with useful content

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/06-study/source-material-triage ~/.claude/skills/
```

No hook wiring required. The scripts (`file-classifier.py`, `syllabus-map.md`) need to
be built out before this skill is fully operational.

---

## How to invoke it in a session

```
/source-material-triage
Directory: ~/Downloads/caiml-material
Study target: UT Austin CAIML syllabus
Junk patterns to skip: *.iso, *.ova, videos > 200MB
```

Or inline:

```
Triage my study folder: ~/StudySaurus/material
Target: CAIML Module 2 (Supervised Learning)
```

---

## Workflow

```
User provides directory + study target + junk patterns
                 ↓
Run file-classifier.py (skip already-triaged files from triage-log.json)
                 ↓
For each file:
  KEEP → maps to syllabus topic (note which)
  REVIEW → possibly relevant, flag with reason
  SKIP → large binary, duplicate (by hash), video >200MB, off-topic
                 ↓
Output curated folder structure (organised by syllabus module)
                 ↓
Output .gitignore snippet for all SKIP patterns
                 ↓
Write triage-log.json for incremental reruns
                 ↓
Move SKIP files to _triage-review/ (never delete directly)
```

---

## Classification reference

| Decision | Criteria |
|----------|----------|
| KEEP | Content maps to a named syllabus topic |
| REVIEW | Possibly relevant but unclear — user decides |
| SKIP | ISO/OVA, duplicate (by hash), video >200MB, clearly off-topic |

---

## What it will NOT do

- Delete files — SKIP files go to `_triage-review/` only
- Produce a KEEP list without a target syllabus (always asks first)
- Use filename for duplicate detection (uses hash)
- Keep large video files locally by default (always flags >200MB for SKIP)

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `file-classifier.py` (directory walk, SHA-256, skip log support)
- [ ] Write `syllabus-map.md` for CAIML, ARTOC, RTO2
- [ ] Test incremental rerun (triage-log.json skip logic)
- [ ] Test on a real study folder
- [x] Ship: copy to `~/.claude/skills/source-material-triage/`
