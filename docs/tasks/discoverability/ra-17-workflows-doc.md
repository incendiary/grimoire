# Task RA-17: Rewrite PROJECT-WORKFLOWS.md in pathway terms

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: RA-15, RA-16
> Effort: S
> Touches: `PROJECT-WORKFLOWS.md`, `README.md` (one paragraph), `CHANGELOG.md`

## Objective
`PROJECT-WORKFLOWS.md` becomes a short guide organised by pathway prefix, using only
current skill names, under 150 lines.

## Background
- The old document is organised by project type and recommends obsolete chains (for
  example three Python lint skills in a row). After RA-15, every skill name follows
  `<prefix>-<step>`, and the four entry skills (`orient`, `plan`, `release`, `publish`)
  contain a `## Pathway` table (RA-16).
- Source of truth for names and descriptions: `SKILLS.md` (generated). Source of truth for
  orders: the `## Pathway` tables in the four entry skills.

## Steps
1. Read `SKILLS.md` and the four `## Pathway` tables.
2. Replace the whole of `PROJECT-WORKFLOWS.md` with this structure:
   ```
   # Project workflows

   Skills are named by pathway: the prefix tells you when you need it. Type the prefix
   (for example `/release`) in Claude Code, or `#release` in Copilot Chat, to see the
   whole pathway. Full list: [SKILLS.md](SKILLS.md).

   | Prefix | Use it when |
   |---|---|
   | `orient` | starting or resuming work on a repo |
   | `plan` | ... |
   (one row per prefix that exists in SKILLS.md: orient, plan, roadmap, py, ci, deps,
    release, publish, tf, write, incident, review, grimoire)

   ## orient
   <copy the Pathway table from the orient entry skill>

   ## plan
   <copy the Pathway table>

   ## release
   <copy>

   ## publish
   <copy>

   ## Other prefixes
   For each remaining prefix: a `###` heading and a bullet list of its skills, each
   `` `name` ``: the first sentence of its description from SKILLS.md.

   ## By project type
   A table: Project type | Pathways in order. Rows: Python tool, .NET tool, Node service,
   Terraform, Security tool, Publishing a private repo. Use only prefixes and skill names
   that exist in SKILLS.md.
   ```
3. In `README.md`, replace the bullet list under `## Project Workflows` with one sentence
   linking to `PROJECT-WORKFLOWS.md` and `SKILLS.md`.
4. `CHANGELOG.md` → `### Changed`: `- PROJECT-WORKFLOWS.md reorganised by pathway prefix.`

## Constraints
- Only skill names that exist. Check each with `ls -d clusters/*/<name>`.
- Under 150 lines. No em dashes.

## Done when
- [ ] `wc -l < PROJECT-WORKFLOWS.md` is at most 150.
- [ ] Every backticked name in the file that looks like a skill exists:
      `grep -o '`[a-z][a-z0-9-]*`' PROJECT-WORKFLOWS.md | tr -d '`' | sort -u | while read n; do ls -d clusters/*/"$n" >/dev/null 2>&1 || echo "UNKNOWN $n"; done`
      prints nothing except flags such as `--sync` (none should start with a letter and be unknown).
- [ ] `grep -c '—' PROJECT-WORKFLOWS.md` prints `0`.

## Return signal
Commit message: `docs: reorganise PROJECT-WORKFLOWS.md by pathway`
Then follow Shared conventions step 7.
