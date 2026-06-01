# 06-study — Study discipline

Skills for structured learning. Designed around production over consumption: every
study session ends with something you write, implement, or explain — not something you
read. Currently covers the CAIML postgraduate certificate and supporting maths
reconditioning, with a secondary focus on study material organisation.

---

## Skills

### [study-burst-runner](study-burst-runner/) ✅ complete
Enforces the 35-minute study burst format. One atomic objective per session, stated
and testable. Teaches in order: intuition → edge behaviour → worked example → notation
→ connection. Requires a production output at the end (write it, implement it, explain
it to someone). Time-checks at 30 minutes and reduces scope rather than running over.
Appends to a study log. Dyslexia-aware formatting throughout.
→ [Full documentation](study-burst-runner/README.md)

### [source-material-triage](source-material-triage/) ✅ complete
Classifies a directory of study material against a target syllabus (CAIML, ARTOC,
RTO2). Each file is labelled KEEP (with syllabus topic), REVIEW (ambiguous, flagged
for user decision), or SKIP (large binary, duplicate, off-topic). Produces a
syllabus-organised folder structure, a `.gitignore` snippet for junk patterns, and a
`triage-log.json` for incremental reruns. Nothing is deleted — SKIP files go to
`_triage-review/` for confirmation.
→ [Full documentation](source-material-triage/README.md)

---

## Typical chain

```
New study material arrives
        ↓
source-material-triage    (what is worth keeping, organised by module)
        ↓
Per module, per day:
study-burst-runner         (35-minute structured session with output)
        ↓
study-log.md updated       (track coverage over time)
```
