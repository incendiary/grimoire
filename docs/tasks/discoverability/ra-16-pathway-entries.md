# Task RA-16: Pathway tables in the four entry skills

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: RA-15
> Effort: XS
> Touches: `SKILL.md` of `orient`, `plan`, `release`, `publish`; `CHANGELOG.md`

## Objective
Each pathway's entry skill (the bare prefix) begins with its ordered steps, so the whole
sequence is visible from one name.

## Background
- The prefix already groups step skills in autocomplete; this table only adds the order.
  Step skills get no back-reference (the prefix says it).
- Use exactly these orders and wording:

**orient**
| Step | Skill | When |
|---|---|---|
| 1 | `orient` | Start or resume a session on a repo |
| 2 | `orient-branches` | Branches are scattered or unclear |
| 3 | `orient-morning-run` | Routine PR and dependabot upkeep |
| 4 | `orient-authored-repos` | Work spans several repos |

**plan**
| Step | Skill | When |
|---|---|---|
| 1 | `plan` | Unsure which planning step applies |
| 2 | `plan-spec` | Before work: define success criteria |
| 3 | `plan-decompose` | Work spans several sessions |
| 4 | `plan-model-tier` | Delegating to sub-agents |
| 5 | `plan-verify` | Output exists and needs evaluation |
| side | `plan-handoff` | Context is already full |
| side | `plan-environment` | Setting up a workspace or CLAUDE.md |

**release**
| Step | Skill | When |
|---|---|---|
| 1 | `release` | Cutting a release |
| 2 | `release-readme-pin` | README install lines need the new tag |
| 3 | `release-docker-ghcr` | The repo ships a container image |
| 4 | `roadmap-sync` | Tick roadmap items the release closed |

**publish**
| Step | Skill | When |
|---|---|---|
| 1 | `publish` | Preparing a private repo for public release |
| 2 | `publish-history-wipe` | History contains sensitive material |
| 3 | `publish-secret-scan` | Before the first public push |
| 4 | `ci-local` | Verify CI locally (`--sync`) |
| 5 | `publish-readme` | README is missing or a placeholder |

## Steps
1. Before editing, confirm every skill named above exists: `ls -d clusters/*/<name>`. If
   any does not, stop with `CHUNK BLOCKED: RA-16 missing <name>`.
2. In each entry skill's `SKILL.md`, insert after the `> **Status/Cluster/Type**`
   blockquote a `## Pathway` heading followed by its table, exactly as above.
3. `CHANGELOG.md` → `### Added`: `- Pathway tables in the orient, plan, release and publish entry skills.`

## Done when
- [ ] `grep -l '^## Pathway' clusters/*/*/SKILL.md` lists exactly the four entry skills.
- [ ] `bash scripts/check-frontmatter.sh` exits 0.

## Return signal
Commit message: `docs: pathway tables in entry skills`
Then follow Shared conventions step 7.
