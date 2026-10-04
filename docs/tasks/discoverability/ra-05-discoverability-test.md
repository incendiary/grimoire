# Task RA-05: Measurable discoverability test

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: RA-02
> Effort: M
> Touches: `docs/discoverability-intents.tsv` (new), `clusters/01-meta/skill-keyword-lookup/find-skill.sh`, `scripts/check-discoverability.sh` (new), `.github/workflows/validate.yml`, `CHANGELOG.md`

## Objective
A fixture of plain-language requests, each mapped to the skill that should answer it, plus
a script and CI gate that measure how often the keyword finder ranks that skill in its top 3.

## Background
- The owner's top concern: "I can't remember or find the right skill name when I need
  one." This task turns that into a number (hit@3) that must not regress, including after
  the RA-15 rename.
- `find-skill.sh` scores keyword hits in `SKILL.md` and `README.md`, with a small synonym
  table and a boost for directory-name matches. It has `--json` and `--limit`.
- Every `SKILL.md` now has a frontmatter `description:` line, which is the best signal.
- **Owner checkpoint:** the intents file encodes how the owner phrases requests. After
  writing it, stop and output `CHUNK BLOCKED: RA-05 intents ready for owner review at docs/discoverability-intents.tsv` unless the dispatch prompt says the owner has approved it.

## Context files
- `clusters/01-meta/skill-keyword-lookup/find-skill.sh`: the scoring logic and `--json` output format.
- `REVIEW.md`, section "2.3 Fragmentation": overlap pairs that intents must distinguish.
- `docs/tasks/discoverability/ra-02-frontmatter-descriptions.md`: the disambiguation table (each pair is a good intent pair).

## Steps
1. Write `docs/discoverability-intents.tsv`: header `intent<TAB>expected_skill`, then one
   row per skill (57) plus extra rows for each overlap pair. Rules:
   - Phrase as a busy person would type, without skill names: e.g.
     `make sure my push won't go red in CI` → `local-ci`.
   - Exactly one intent per skill in `ls clusters/*/*/` as a baseline; for skills listed in the
     RA-02 disambiguation table add a second intent that sits close to its sibling.
   - No intent may contain the expected skill's name or a hyphenated fragment of it.
2. Stop for the owner checkpoint (see Background).
3. Change `find-skill.sh` scoring so a keyword hit in the frontmatter `description` line
   scores 3× a hit in the body. Keep the existing name boost and synonyms. Keep output formats unchanged.
4. Create `scripts/check-discoverability.sh`: for each intent row, run
   `bash clusters/01-meta/skill-keyword-lookup/find-skill.sh --json --limit 3 <intent words>`,
   record whether the expected skill is ranked 1st (hit@1) or in the top 3 (hit@3).
   Before comparing, resolve the expected name through `scripts/renamed-skills.txt` if it
   exists (lines `old<TAB>new`; follow chains; `-` means retired: report the row as
   `SKIPPED (retired)` and exclude it from N). This keeps the intents file valid through
   merges and the RA-15 rename without editing it.
   Print a table (intent, expected, top 3, result), then
   `hit@1: X/N (P%)  hit@3: Y/N (Q%)`. Exit 1 if hit@3 is below `${MIN_HIT3:-80}` percent.
5. Run it. If hit@3 is below 80%, improve `find-skill.sh` (for example strip stop-words
   like `my`, `the`, `this` from queries; add synonyms) rather than editing intents to fit.
   You may also report descriptions that are too weak, as a list in your return message;
   do not edit `SKILL.md` files.
6. Add a step to the `structure` job in `validate.yml`: `run: bash scripts/check-discoverability.sh`.
7. `CHANGELOG.md` → `### Added`: `- Discoverability test: docs/discoverability-intents.tsv and scripts/check-discoverability.sh (hit@3 gate, 80%).`

## Constraints
- Do not tune intents to the scorer. The intents represent the owner, not the tool.
- Keep `find-skill.sh` working on macOS bash 3.2 (no associative arrays).

## Done when
- [ ] Owner has approved the intents file.
- [ ] `bash scripts/check-discoverability.sh` exits 0 and prints hit@3 of at least 80%.
- [ ] `shellcheck` clean on both scripts.
- [ ] `bash clusters/01-meta/skill-keyword-lookup/find-skill.sh lint black ruff` still returns results in the old format.

## Return signal
Commit message: `feat: discoverability intent test with hit@3 gate`
Then follow Shared conventions step 7. Include the final hit@1/hit@3 line in your return message.
