# source-material-triage

> **Status:** COMPLETE
> **Cluster:** 06-study

## Description
Classify and distil a folder of study material against a target syllabus. Output a
curated folder structure and a `.gitignore` snippet covering all junk patterns found.

Invoke when: the user has a directory of downloaded study material (PDFs, videos, notes,
archives) and needs to determine what is worth keeping and where it maps to the current
study target. Trigger phrases: "triage my study folder", "classify this material",
"what's worth keeping here", "organise my study files".

## Context needed
- Path to the directory to triage
- Current study target (e.g. UT Austin CAIML syllabus, ARTOC, RTO2, specific module)
- Any known junk patterns to skip: `*.iso`, `*.ova`, `node_modules/`, video files over
  a size threshold, etc.

## What to do

1. **Run the classifier script to get a file listing with sizes, types, and hashes.**
   Skip any files already in `triage-log.json` (incremental run support). For large
   directories, filter obvious junk first (ISO, OVA, large binaries) before full analysis.

2. **For each file, make a classification decision:**
   - **KEEP** — maps to a topic in the target syllabus. Note which topic.
   - **REVIEW** — possibly relevant but unclear. Flag for user decision with a one-line
     reason why it is ambiguous.
   - **SKIP** — large binary (ISO, OVA), duplicate (same hash as another file), video
     over 200 MB (stream from source; do not store locally), or clearly off-topic.

3. **Output a curated folder structure** showing where KEEP files should be moved.
   Organise by syllabus topic, not by original folder structure. The folder names should
   match the syllabus module names so the structure is study-session ready.

4. **Output a `.gitignore` snippet** covering all SKIP patterns encountered. This
   prevents re-adding junk if the material folder is tracked in a git repo.

5. **Write a `triage-log.json`** so subsequent runs are incremental. Each entry:
   `{ "path": "relative/path/file.pdf", "hash": "sha256...", "decision": "KEEP|REVIEW|SKIP", "topic": "module name" }`

## Gotchas
- Large video files are almost always better streamed from source than stored locally.
  Default to SKIP for video files over 200 MB unless the user provides a specific offline
  reason (e.g. no internet access during study sessions).
- Do not delete anything. Move SKIP candidates to a `_triage-review/` subfolder so the
  user can confirm before deletion. Never delete files directly.
- Duplicate detection should use file hash, not filename. A file renamed to something
  meaningful is still a duplicate if the content is identical.
- The syllabus map must be up to date for accurate KEEP classifications. If the user
  has not provided a syllabus, ask for one before producing the KEEP list. A triage
  without a target syllabus produces a folder structure that is not study-session ready.

## Suggested scripts
- `file-classifier.py` — walks directory, outputs file list with size, extension, and
  SHA-256 hash for deduplication. Skips files already in `triage-log.json`.
- `syllabus-map.md` — maps topic keywords to syllabus sections for CAIML, ARTOC, and
  RTO2. Update this file as study targets change.
