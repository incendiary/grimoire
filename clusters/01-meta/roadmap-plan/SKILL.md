---
name: roadmap-plan
description: "Turns a codebase review, ponytail audit, or other findings into a ROADMAP.md that cheaper agents can execute cold: every item carries tier, dependencies, files, context, steps, verification with a negative check, a do-not list, done-when, and a conventional PR title, enforced by a completeness check. Use when asked to 'write a roadmap from this review', 'plan the fixes for agents', or 'turn these findings into work items'. To pick the next item use roadmap; to tick items after a merge use roadmap-sync."
---
# roadmap-plan

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** instructional
> **Script:** `check-items.py` (completeness check, stdlib only)

## Description
A roadmap written for delegation is a **work order, not a summary**. The agent that picks
up an item has no memory of the conversation and cannot ask questions. If a field is
missing, the agent guesses, and a guess at the wrong tier or scope is how the work fails.

This skill writes the roadmap to a single standard and refuses to call it done until
`check-items.py` passes.

## Context needed
- The findings: a codebase review (`review-codebase`), a ponytail audit, or similar.
- The project's stated intent (README, design doc) so items serve it.
- The maintainer's decisions on scope-defining questions (see step 2).

## The standard

Every item, scheduled or idea, has all nine fields, as bold labels, in this order:

| # | Field | Content |
|---|-------|---------|
| 1 | `**Tier:**` | cheap / mid / strong, and **why**: how cheaply a gate proves it correct, how far a mistake spreads (`plan-model-tier`). |
| 2 | `**Depends on:**` | Item IDs that must land first, or `none`. |
| 3 | `**Files:**` | Explicit paths to touch. |
| 4 | `**Context:**` | What is wrong and where, with names and `file:line`. Written for a reader who has never seen the repo. |
| 5 | `**Steps:**` | Numbered, exact commands or edits. Not intentions. |
| 6 | `**Verify:**` | Commands whose output proves it works, **including a negative check**: break it on purpose, confirm the gate fails, revert. |
| 7 | `**Do not:**` | The tempting wrong moves: scope creep, "tidying", changing a contract. |
| 8 | `**Done when:**` | An observable end state. |
| 9 | `**PR:**` | Conventional-commit title (`feat:`, `fix:`, `refactor:`, `!` for breaking). The title drives the version bump. |

**The standard does not bend for brevity.** Long items are deliberate. An instruction to
keep something short ("just a one-line note about X") never permits dropping a field: if
X is worth recording as work, it gets a full item. Resolve any doubt about length in
favour of the standard. Do not describe the standard as a style or one option; it is the
only format.

### Item template

```markdown
### R-<n>: <short imperative title>
**Tier:** mid. Behaviour change in a shared helper; the E2E gate catches regressions.
**Depends on:** R-1
**Files:** `src/x.py`, `tests/test_x.py`
**Context:** `src/x.py:42` `parse()` drops trailing fields when ...
**Steps:**
1. ...
2. ...
**Verify:**
- `pytest tests/test_x.py`
- Negative check: revert step 1, confirm `test_trailing_fields` fails, restore.
**Do not:** change `parse()`'s signature; reformat unrelated code.
**Done when:** `pytest` passes and `x --dump` output matches `tests/golden/x.txt`.
**PR:** `fix: keep trailing fields in parse`
```

## Workflow

1. **Reconcile claims with the code.** Before planning on any premise ("we already output
   Markdown", "nothing calls this"), check it in the code. A wrong premise accepted here
   becomes every downstream item's bug. Correct the user, with evidence, when needed.
2. **Interview on scope; decide the small things.** Ask about scope-defining choices:
   what to delete, what each output format is for, what is out of bounds. Decide naming,
   PR grouping and ordering yourself, state the decision, move on. Be consistent: do not
   ask about one PR's name and decide the others.
3. **Record decisions** in a dated table in `ROADMAP.md`. Resolve every open question
   before the item that depends on it is scheduled.
4. **Sequence with these rules:**
   - **Gate before refactor.** The first item builds a byte-exact end-to-end
     characterisation test. Unit coverage alone misses the defects that matter.
   - **Grep before delete**, with a stop rule: any production caller means stop and report.
   - **Measure before optimising.** A benchmark item, then a conditional optimisation item
     with numeric thresholds for whether it proceeds.
   - **Group PRs by theme and type.** A squash merge has one title and one type, so never
     mix a feature and a refactor in one PR. One commit per item inside a PR.
   - **Versioning follows PR titles.** No version bumps or tags in item PRs; one release
     at the end.
5. **Write every item to the standard**, then the shared sections (below).
6. **Run the completeness check** until it passes:
   ```bash
   python3 ~/.claude/skills/roadmap-plan/check-items.py ROADMAP.md
   ```
   It checks all nine fields are present, non-empty and in order, that `Verify` has a
   negative check, and that `PR` is a conventional title. It cannot judge quality: also
   re-read each item as a cold agent would.
7. **Sweep for stale references.** After any rename or removal the plan introduces, grep
   docs, agent guides and configs for the old name (tool paths, model names, script names)
   and either fix them or add an item.

## ROADMAP.md layout

```markdown
# Roadmap
## Intent          one paragraph: what the project is for, what this plan serves
## Decisions       | Date | Decision | Why |
## Sequence        item IDs in order, grouped into PRs, with the PR title for each
## Agent rules     the stop conditions below, verbatim
## Items           the ### items, scheduled first, then ideas
```

Also write the dated review the plan came from (`docs/review-YYYY-MM-DD.md`), and move any
superseded roadmap into an archive file rather than deleting it.

### Agent rules (copy into every roadmap)

An executing agent **stops and reports** when:
- a gate changes output unexpectedly;
- a step fails twice;
- a contract, schema or public interface would change;
- an instruction contradicts the code.

## Failure modes this skill exists to prevent

- **Thin items** that look complete but are not executable cold (most first drafts).
  The checker catches missing fields; the cold re-read catches thin ones.
- **Shortening under pressure:** reading a request for brevity as permission to drop fields.
- **Inconsistent asking:** asking permission on one small decision and not its siblings.
- **Stale references** left behind by renames.
- **Unverified premises** from the user shaping the plan.

## Integration with other skills

- **review-codebase**, **ponytail-audit**: produce the findings this skill plans from.
- **plan-model-tier**: the reasoning behind each item's `Tier`.
- **plan-decompose**: splits a single large item into session-sized task files.
- **roadmap**: picks the next ready item; **roadmap-sync**: ticks items after a merge.
