# Task RA-18: Report old skill names used outside this repo (read-only)

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: RA-15
> Effort: S
> Touches: nothing in any repo. Writes one report file to `/tmp/ra-18-report.md`.

## Objective
Produce a report of every place outside this repo that still uses an old skill name, with
a proposed replacement for each, so the owner can approve the edits.

## Background
- Renames and merges are listed in `scripts/renamed-skills.txt` (`old<TAB>new`; `-` means
  retired, now a rule file under `rules/`).
- Known locations that reference skill names:
  - `~/.claude/CLAUDE.md` (names `github-authored-repos`)
  - `~/.claude/rules/*.md` (`git-ci.md` names `local-ci` and `pre-push-validation`)
  - Local clones of the private repos `grimoire-private` and `grimoire-offsec`, if present.
- **This task edits nothing.** Files outside the repo belong to the owner and need approval.

## Steps
1. Find private repo clones:
   ```bash
   find ~/Projects ~/PycharmProjects -maxdepth 3 -type d \( -name 'grimoire-private' -o -name 'grimoire-offsec' \) 2>/dev/null
   ```
2. Build the pattern list and search (read-only):
   ```bash
   cut -f1 scripts/renamed-skills.txt | sort -u > /tmp/ra18-old.txt
   for loc in ~/.claude/CLAUDE.md ~/.claude/rules <each clone path from step 1>; do
     grep -rnwF -f /tmp/ra18-old.txt "$loc" --exclude-dir=.git --exclude=CHANGELOG.md 2>/dev/null
   done
   ```
3. Write `/tmp/ra-18-report.md`:
   ```
   # RA-18: old skill names outside the repo

   | File | Line | Old | Proposed | Note |
   |---|---|---|---|---|
   ```
   One row per hit. "Proposed" is the new name from `renamed-skills.txt`; for retired names
   write `rules/<file>` if you can tell which rule replaced it from `rules/`, else `owner to decide`.
   In "Note" flag anything that is a command or path (for example `bash local-ci.sh`),
   since script names did not change and may still be correct.
4. Do not modify any file. Output the report path.

## Done when
- [ ] `/tmp/ra-18-report.md` exists with one row per grep hit.
- [ ] `git status` in this repo and in each clone shows no changes made by you.

## Return signal
No commit. Output exactly: `CHUNK COMPLETE: RA-18 report at /tmp/ra-18-report.md (<N> hits), awaiting owner approval`.
The master shows the report to the owner. Applying the edits is a separate, owner-approved step;
the master may dispatch it to `haiku` with the approved rows as the brief.
