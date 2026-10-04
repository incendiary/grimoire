# Task RA-25: Delete three unused scripts

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none
> Effort: XS
> Touches: `clusters/01-meta/model-selection-framework/model-select.sh`, `scripts/roadmap-close.sh`, `scripts/skill-dependency-graph.sh` (all deleted); `clusters/01-meta/model-selection-framework/README.md` and `SKILL.md`; `CHANGELOG.md`

## Objective
Remove scripts with no callers or that no agent can use.

## Background
| Script | Lines | Why it goes |
|---|---|---|
| `clusters/01-meta/model-selection-framework/model-select.sh` | 203 | Interactive (`read -rp` prompts); an agent cannot drive it. The skill's SKILL.md tables already carry the framework. |
| `scripts/roadmap-close.sh` | 151 | No callers; agents tick checkboxes directly. |
| `scripts/skill-dependency-graph.sh` | 79 | No callers. `grep -rn <skill-name> clusters/` answers the same question. |

Checked `- [x]` history lines in `ROADMAP.md`'s "Infrastructure roadmap" that mention these
scripts stay as they are (they record what was done).

## Steps
1. `git rm clusters/01-meta/model-selection-framework/model-select.sh scripts/roadmap-close.sh scripts/skill-dependency-graph.sh`
2. Find references:
   ```bash
   grep -rnE 'model-select\.sh|roadmap-close|skill-dependency-graph' . --exclude=CHANGELOG.md --exclude=REVIEW.md --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tasks
   ```
   In `model-selection-framework/README.md` and `SKILL.md`, delete the paragraph or section
   that describes running `model-select.sh` (for example the README section starting
   "Use `model-select.sh` to walk through the framework interactively"), including its code
   block. Leave `- [x]` lines in `ROADMAP.md`. Repeat the grep until only those remain.
3. `CHANGELOG.md` → `### Removed`: `- Unused scripts: model-select.sh, scripts/roadmap-close.sh, scripts/skill-dependency-graph.sh.`

## Done when
- [ ] The three files do not exist.
- [ ] Step 2 grep prints only `- [x]` lines from `ROADMAP.md`.
- [ ] Shared conventions step 6 checks pass.

## Return signal
Commit message: `chore: delete unused scripts`
Then follow Shared conventions step 7.
