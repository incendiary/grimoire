# codebase-holistic-review

> **Status:** COMPLETE
> **Cluster:** 05-technical
> **Type:** instructional

## Description

Run a structured, predictive review of an entire codebase — not just current bugs, but
risks that will materialise as the project grows. Produces a written findings document
suitable for embedding in the repo README or a dedicated `REVIEW.md`. After completing
the review, optionally calls `roadmap-sync` to move the action items to a dedicated
file with enough detail for a lesser-capable agent to execute independently.

Invoke when: "review this codebase holistically", "what issues should I expect",
"predict where this will break", "do a full code audit", "what should I fix before
scaling this up". Pairs with `karpathy-framework` (use that to build the spec and
evaluation criteria first if the codebase is large).

## Context needed

Before starting, collect all of the following. Do not skip items — lesser agents
working from the output roadmap will need this grounding:

- **Entry points** — every file that starts execution (CLI scripts, HTTP handlers,
  cron triggers, module `__init__.py` imports, test suites)
- **Dependency manifest** — `package.json`, `pyproject.toml`, `requirements.txt`,
  `go.mod`, `*.csproj`, etc.
- **CI definition** — `.github/workflows/`, `Makefile`, `justfile`, or equivalent
- **Existing tests** — test directory structure and last known coverage %
- **README / docs** — current documented purpose, install, and usage
- **Known pain points** — anything the author already knows is fragile

## What to do

Work through the review phases in sequence. Do not skip a phase even if it seems
irrelevant — a null finding is still a finding.

---

### Phase 1: Architecture map

1. Identify the layers (data, logic, presentation, infrastructure).
2. List the core modules/packages and their single-line purpose.
3. Note any modules that have no clear single responsibility (candidates for future
   splitting).
4. Draw the data-flow: where does external input enter, how does it move through the
   system, where does it leave (response/file/side-effect)?

**Output format:**

```
## Architecture

| Module / Path | Responsibility | Concerns |
|---|---|---|
| src/auth/     | JWT validation and session handling | Mixes token creation with permission checks |
| ...           | ...            | ...      |
```

---

### Phase 2: Risk inventory

Classify every identified risk into one of five categories. Score each 1–5 (5 = critical).

| Category | What to look for |
|---|---|
| **Security** | Injection points, auth bypasses, secret exposure, dependency CVEs |
| **Scalability** | N+1 queries, unbounded loops, in-memory state that can't be distributed |
| **Reliability** | Uncaught exceptions, missing retries, no circuit-breakers on external calls |
| **Maintainability** | Functions >50 lines, deeply nested logic, missing tests for critical paths |
| **Dependency** | Unpinned versions, abandoned packages (last commit >2 years), single-purpose deps |

**Output format:**

```
## Risk inventory

| # | Category | Finding | Score | File / Location |
|---|---|---|---|---|
| 1 | Security | API key loaded from env without validation or fallback | 4 | src/config.py:12 |
| 2 | Scalability | Loads full user list into memory on every request | 5 | src/routes/users.py:34 |
| ... | | | | |
```

---

### Phase 3: Predictive failure analysis

For each risk with score ≥ 3, write a failure scenario:

- **What happens:** The exact observable failure mode (error message, silent data
  corruption, performance cliff, security breach)
- **Trigger condition:** What usage pattern, data volume, or environment change will
  cause it
- **Estimated timeline:** Will this fail today, at 10× current load, or only after
  the next dependency upgrade?

**Output format:**

```
## Predicted failure scenarios

### PF-1: OOM on large CSV import (Scalability, score 5)

**What happens:** `MemoryError` or process kill during import when CSV exceeds
available memory.

**Trigger condition:** Any file larger than ~200MB on a 512MB instance.

**Estimated timeline:** Will occur if any user uploads a file >200MB. No current
protection against this.

**Minimum fix:** Stream the file using `csv.DictReader` with chunked processing
instead of `pd.read_csv()`.

**Full fix (roadmap item):** Add configurable chunk size, progress tracking, and a
max-file-size guard with a clear user error message.
```

---

### Phase 4: Test coverage gaps

1. List every critical execution path with no test coverage.
2. Note any tests that assert too broadly (`assert response.status_code == 200`) and
   would pass even if the logic is wrong.
3. Identify the three highest-value test additions (ranked by risk score of uncovered
   path).

**Output format:**

```
## Test coverage gaps

| Path | Why critical | Test type needed |
|---|---|---|
| src/auth/tokens.py:verify_token() | All protected routes depend on this | Unit: valid token, expired, tampered, wrong secret |
| src/jobs/import.py:process_csv() | Highest revenue feature, OOM risk | Integration: file size limits, malformed input |
```

---

### Phase 5: Dependency audit

1. Check every dependency for:
   - Pinned vs range vs floating version
   - Date of last upstream release (anything >18 months with no security releases is a flag)
   - Known CVEs (run `pip audit`, `npm audit`, or `trivy fs .`)
2. Note any dependency doing only one small thing that could be inlined.

---

### Phase 6: CI/CD gap analysis

1. Does the pipeline run tests on every PR?
2. Does it lint and format-check?
3. Does it scan for secrets?
4. Does it pin action versions?
5. Is there a scheduled run for dependency drift detection?

Flag every "no" as a CI gap and write the YAML snippet that would fix it.

---

### Phase 7: Write the review document

Compile all phase outputs into a single document. The document must include:

1. **Executive summary** — 3–5 sentences. Top risk, most urgent fix, overall health.
2. **Architecture map** (Phase 1 output)
3. **Risk inventory** (Phase 2 output)
4. **Predicted failure scenarios** (Phase 3 output, score ≥ 3 only)
5. **Test coverage gaps** (Phase 4 output)
6. **Dependency audit** (Phase 5 output)
7. **CI/CD gaps** (Phase 6 output)
8. **Action roadmap** — see format below

#### Action roadmap format

Each action item must be written so that a lesser-capable agent can execute it
independently, without needing to re-read the whole review. Include:

- **Title:** Short imperative phrase
- **Context:** 1–2 sentences explaining what the problem is and where
- **Success criteria:** Exactly how to verify it is done correctly
- **Files to change:** Explicit paths
- **Estimated effort:** XS / S / M / L / XL

```markdown
### RA-1: Add file size guard to CSV import

**Context:** `src/jobs/import.py:process_csv()` loads the entire CSV into memory
with `pd.read_csv()`. Files >200MB will OOM the process.

**Success criteria:**
- Files >200MB return a 413 error with message "File too large (max 200MB)"
- Files ≤200MB still import correctly
- A unit test covers both cases

**Files to change:** `src/jobs/import.py`, `tests/test_import.py`

**Estimated effort:** S
```

---

### Phase 8: Embed and trigger roadmap-sync

1. Write the review document to `REVIEW.md` at repo root (or append to `README.md`
   under `## Code Review` if the repo has no separate REVIEW.md yet).
2. Extract every action item to the roadmap section of the README (`## Roadmap`):
   - Paste as `- [ ] RA-N: <title>` checkboxes
3. Call `roadmap-sync` to move roadmap items to a dedicated file (`PROJECT-ROADMAP.md`
   or `ROADMAP.md`) if the README roadmap is getting long (>15 items).
4. Commit as:
   ```
   docs: add holistic review findings and action roadmap
   ```

## Gotchas

- Run the review in a fresh context — do not carry over assumptions from previous
  sessions. Start by reading the actual files, not recalling them.
- Do not omit findings just because they are well-known. Document them so the roadmap
  is complete for other agents.
- Write action items as if explaining to someone who has never seen the codebase.
  Vague action items ("improve performance") are not usable.
- If the codebase is large (>50 files), use `task-decomposer` first to split the
  review into cluster-by-cluster chunks and run each chunk in its own session.
- After a `karpathy-spec` pass, the spec becomes the success-criteria baseline for
  the predictive failure section.

## Suggested workflow

```
karpathy-spec             → (optional, large codebases) define what "healthy" looks like first
        ↓
codebase-holistic-review  → run all 8 phases
        ↓
[produce REVIEW.md + action roadmap]
        ↓
roadmap-sync              → move roadmap items to dedicated file if >15 items
        ↓
task-decomposer           → (optional) chunk action items for multi-session execution
        ↓
karpathy-verify           → verify the review is complete against the phase checklist
```

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Add worked example: Python web service holistic review (before/after findings)
- [ ] Add worked example: Node.js monorepo review
- [ ] Test on 3 real repos and capture recurring finding patterns
- [ ] Add language-specific risk pattern tables (Python, TypeScript, C#, Go)
