# Task RA-05: Discoverability spot-check list

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: none
> Effort: XS
> Touches: `docs/discoverability-intents.md` (new), `CHANGELOG.md`

## Objective
A short list of plain-language requests, each paired with the skill that should answer it,
which the owner pastes into a fresh session after RA-02 and again after RA-15 to confirm
Claude picks the right skill.

## Background
- The owner's top concern: finding the right skill without remembering its name. What
  matters is whether **Claude** routes correctly, which only a real session shows. A
  keyword scorer in CI would measure the wrong thing, so there is deliberately no script
  and no CI gate.
- Expected names change during the programme. Write current names; readers map them
  through `scripts/renamed-skills.txt`.
- **Owner checkpoint:** after writing the file, stop and output
  `CHUNK BLOCKED: RA-05 intents ready for owner review at docs/discoverability-intents.md`,
  unless the dispatch prompt says the owner has approved it.

## Steps
1. Read `docs/tasks/discoverability/ra-02-frontmatter-descriptions.md` (the disambiguation
   table) and `ls clusters/*/*/`.
2. Write `docs/discoverability-intents.md`:
   ```
   # Discoverability spot-check

   Paste each request into a fresh Claude Code session (no skill names). Pass = Claude
   invokes the expected skill. Map old names through scripts/renamed-skills.txt.

   | Request | Expected skill |
   |---|---|
   ```
   20 to 25 rows: at least one per pathway (orient, plan, roadmap, Python lint, CI,
   dependencies, release, publish, Terraform, writing, incident, review, grimoire), and
   both sides of the five closest overlap pairs in the RA-02 table. Phrase each as a busy
   person would type it, never containing the skill's name.
3. Stop for the owner checkpoint.
4. `CHANGELOG.md` → `### Added`: `- docs/discoverability-intents.md: manual routing spot-check.`

## Done when
- [ ] Owner has approved the list.
- [ ] No request contains its expected skill name (check each row by eye).

## Return signal
Commit message: `docs: discoverability spot-check list`
Then follow Shared conventions step 7.
